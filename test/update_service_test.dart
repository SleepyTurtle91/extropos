import 'dart:convert';
import 'dart:io';

import 'package:extropos/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('downloadLatestApk writes file and returns path on success', () async {
    // Mock the latest release JSON response with one APK asset
    final latestReleaseJson = {
      'tag_name': 'v1.0.0',
      'assets': [
        {
          'name': 'app-release.apk',
          'browser_download_url': 'https://example.com/app-release.apk',
        },
      ],
    };

    final apkBytes = utf8.encode('fake-apk-binary');

    // Setup a MockClient that returns the JSON for the first request and
    // returns APK bytes for the asset download URL.
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/releases/latest')) {
        return Response(
          jsonEncode(latestReleaseJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.toString() == 'https://example.com/app-release.apk') {
        return Response.bytes(apkBytes, 200);
      }
      return Response('Not found', 404);
    });

    final svc = UpdateService(
      owner: 'owner',
      repo: 'repo',
      client: client,
      getTemporaryDirectoryFn: () async =>
          Directory.systemTemp.createTemp('update_test_'),
    );
    final path = await svc.downloadLatestApk();

    final file = File(path);
    expect(await file.exists(), true);
    final content = await file.readAsBytes();
    expect(content, equals(apkBytes));

    // Clean up
    await file.delete();
  });

  test('downloadLatestApk throws when no matching asset', () async {
    final latestReleaseJson = {'tag_name': 'v1.0.0', 'assets': []};
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/releases/latest')) {
        return Response(
          jsonEncode(latestReleaseJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return Response('Not found', 404);
    });

    final svc = UpdateService(
      owner: 'owner',
      repo: 'repo',
      client: client,
      getTemporaryDirectoryFn: () async =>
          Directory.systemTemp.createTemp('update_test_'),
    );
    expect(svc.downloadLatestApk(), throwsException);
  });
}
