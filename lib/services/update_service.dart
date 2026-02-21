import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class UpdateInfo {
  final String version;
  final String tagName;
  final String downloadUrl;
  final String releaseNotes;
  final String publishedAt;
  final bool isNewer;
  final String assetName;

  UpdateInfo({
    required this.version,
    required this.tagName,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.publishedAt,
    required this.isNewer,
    required this.assetName,
  });
}

/// Simple service that fetches the latest GitHub release for this repo and
/// downloads an APK asset matching the provided pattern.
///
/// It uses anonymous access if no token is present, but can use a token via
/// the `GITHUB_TOKEN` or `GH_TOKEN` environment variables when available to
/// avoid rate limits.
class UpdateService {
  final String owner;
  final String repo;
  final http.Client _client;

  /// Accepts an optional [http.Client] for testing. When not provided, a
  /// default client will be used.
  final Future<Directory> Function() _getTemporaryDirectory;

  UpdateService({
    required this.owner,
    required this.repo,
    http.Client? client,
    Future<Directory> Function()? getTemporaryDirectoryFn,
  }) : _client = client ?? http.Client(),
       _getTemporaryDirectory =
           getTemporaryDirectoryFn ?? getTemporaryDirectory;

  Uri _latestReleaseUri() =>
      Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');

  /// Check for updates from GitHub releases
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      debugPrint('🔄 Checking for updates from GitHub...');

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      debugPrint('📱 Current version: $currentVersion');

      final token =
          Platform.environment['GITHUB_TOKEN'] ??
          Platform.environment['GH_TOKEN'];
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'token $token';
      }

      // Fetch latest release from GitHub
      final response = await _client
          .get(_latestReleaseUri(), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        debugPrint('❌ Repository not found or no releases published');
        debugPrint('   Repository: $owner/$repo');
        debugPrint(
          '   Make sure the repository exists and has at least one release',
        );
        return null;
      }

      if (response.statusCode == 403) {
        debugPrint('❌ GitHub API rate limit exceeded or access forbidden');
        debugPrint('   Consider adding a GITHUB_TOKEN environment variable');
        return null;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ GitHub API error: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return null;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String;
        final releaseNotes =
            data['body'] as String? ?? 'No release notes available';
        final publishedAt = data['published_at'] as String;

        // Extract version from tag (e.g., v1.0.5-20251125 -> 1.0.5)
        String latestVersion = tagName;
        if (latestVersion.startsWith('v')) {
          latestVersion = latestVersion.substring(1);
        }

        // Split by dash to separate version from date
        final parts = latestVersion.split('-');
        final versionPart = parts[0]; // e.g., "1.0.5"

        // Find APK download URL
        String? apkUrl;
        String? assetName;
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null) {
          for (var asset in assets) {
            final name = asset['name'] as String;
            if (name.endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String;
              assetName = name;
              break;
            }
          }
        }

        if (apkUrl == null) {
          debugPrint('❌ No APK found in latest release');
          return null;
        }

        debugPrint('🆕 Latest version: $versionPart (tag: $tagName)');
        debugPrint('📦 APK: $assetName');

        // Compare versions
        final isNewer = _isVersionNewer(versionPart, currentVersion);

        debugPrint(isNewer ? '✨ Update available!' : '✅ App is up to date');

        return UpdateInfo(
          version: versionPart,
          tagName: tagName,
          downloadUrl: apkUrl,
          releaseNotes: releaseNotes,
          publishedAt: publishedAt,
          isNewer: isNewer,
          assetName: assetName ?? 'app-release.apk',
        );
      } else {
        debugPrint('❌ GitHub API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return null;
    }
  }

  /// Compare two semantic versions (e.g., "1.0.5" vs "1.0.4")
  static bool _isVersionNewer(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // Pad to same length
      while (newParts.length < 3) {
        newParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      // Compare major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      debugPrint('⚠️ Error comparing versions: $e');
      return false;
    }
  }

  Future<String> downloadLatestApk({
    String assetNameContains = 'app-release.apk',
  }) async {
    final token =
        Platform.environment['GITHUB_TOKEN'] ??
        Platform.environment['GH_TOKEN'];
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };
    if (token != null && token.isNotEmpty)
      headers['Authorization'] = 'token $token';

    final resp = await _client
        .get(_latestReleaseUri(), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch latest release: ${resp.statusCode} ${resp.reasonPhrase}',
      );
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final assets = (body['assets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final asset = assets.firstWhere(
      (a) => (a['name'] as String).contains(assetNameContains),
      orElse: () => {},
    );

    if (asset.isEmpty)
      throw Exception(
        'No matching asset found in the latest release for pattern $assetNameContains',
      );

    final downloadUrl = asset['browser_download_url'] as String;
    final name = asset['name'] as String;

    final tempDir = await _getTemporaryDirectory();
    final filePath = '${tempDir.path}/$name';
    final file = File(filePath);

    final downloadResp = await _client
        .get(Uri.parse(downloadUrl), headers: headers)
        .timeout(const Duration(minutes: 2));
    if (downloadResp.statusCode != 200) {
      throw Exception('Failed to download asset: ${downloadResp.statusCode}');
    }

    await file.writeAsBytes(downloadResp.bodyBytes);
    return filePath;
  }
}
