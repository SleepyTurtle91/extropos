import 'dart:io';
import 'package:extropos/services/update_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

typedef OpenFileFunction = Future<void> Function(String path);

class UpdateDialogs {
  static Future<void> downloadLatestApk(
    BuildContext context, {
    UpdateService Function()? updateServiceFactory,
    OpenFileFunction? openFileFn,
  }) async {
    try {
      final currentContext = context;
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Downloading latest APK...')),
            ],
          ),
        ),
      );

      final svc =
          updateServiceFactory?.call() ??
          UpdateService(owner: 'Giras91', repo: 'flutterpos');

      final choice = await showDialog<String>(
        context: currentContext,
        builder: (context) => AlertDialog(
          title: const Text('Download Update'),
          content: const Text('Would you like to open the APK after download?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'download'),
              child: const Text('Download'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'download_open'),
              child: const Text('Download & Open'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel') {
        if (currentContext.mounted) Navigator.of(currentContext).pop();
        return;
      }

      final filePath = await svc.downloadLatestApk();

      Directory desktopPath;
      final home = Platform.environment['HOME'] ?? '';
      if (Platform.isWindows) {
        desktopPath = Directory(Platform.environment['USERPROFILE'] ?? '');
      } else {
        desktopPath = Directory('$home/Desktop');
      }
      if (!await desktopPath.exists()) {
        final downloads = Directory('$home/Downloads');
        if (await downloads.exists()) {
          desktopPath = downloads;
        } else {
          desktopPath = Directory(home);
        }
      }
      final file = File(filePath);
      final target = File('${desktopPath.path}/${file.uri.pathSegments.last}');
      try {
        await file.copy(target.path);
      } catch (e) {
        if (currentContext.mounted) {
          Navigator.of(currentContext).pop();
          final action = await showDialog<String>(
            context: currentContext,
            builder: (context) => AlertDialog(
              title: const Text('Unable to save file'),
              content: Text(
                'Failed to write APK to ${desktopPath.path}: $e\n\nYou can pick a different location or open the APK directly if supported.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('choose'),
                  child: const Text('Choose location'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('open'),
                  child: const Text('Open APK'),
                ),
              ],
            ),
          );
          if (action == 'choose') {
            final fileSave = await getSaveLocation(
              suggestedName: file.uri.pathSegments.last,
            );
            if (fileSave != null) {
              await File(fileSave.path).writeAsBytes(await file.readAsBytes());
              ToastHelper.showToast(
                currentContext,
                'Saved to ${fileSave.path}',
              );
            }
          } else if (action == 'open') {
            final openFn = openFileFn ?? (path) => OpenFilex.open(path);
            await openFn(file.path);
          }
          return;
        }
      }

      if (currentContext.mounted) {
        Navigator.of(currentContext).pop();
        ToastHelper.showToast(
          currentContext,
          'Latest APK downloaded: ${target.path}',
        );
      }

      if (choice == 'download_open') {
        final openFn = openFileFn ?? (path) => OpenFilex.open(path);
        await openFn(target.path);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Failed'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  static Future<void> checkForUpdates(
    BuildContext context, {
    UpdateService Function()? updateServiceFactory,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking for updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final updateService =
          updateServiceFactory?.call() ??
          UpdateService(owner: 'Giras91', repo: 'flutterpos');
      final updateInfo = await updateService.checkForUpdates();

      if (context.mounted) Navigator.pop(context);

      if (updateInfo == null) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Releases Available'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Could not find any releases on GitHub.'),
                  SizedBox(height: 12),
                  Text(
                    'This could mean:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• No releases have been published yet'),
                  Text('• Repository is private'),
                  Text('• Network connection issue'),
                  SizedBox(height: 12),
                  Text(
                    'To enable updates, publish a release on GitHub with an APK file attached.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!updateInfo.isNewer) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Up to Date'),
              content: Text(
                'You are running the latest version (${updateInfo.version}).',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (context.mounted)
        showUpdateDialog(
          context,
          updateInfo,
          updateServiceFactory: updateServiceFactory,
        );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to check for updates: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  static void showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo, {
    UpdateService Function()? updateServiceFactory,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${updateInfo.version} is now available!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Release: ${updateInfo.tagName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Release Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  updateInfo.releaseNotes,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              downloadAndInstallUpdate(
                context,
                updateInfo,
                updateServiceFactory: updateServiceFactory,
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download & Install'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> downloadAndInstallUpdate(
    BuildContext context,
    UpdateInfo updateInfo, {
    UpdateService Function()? updateServiceFactory,
  }) async {
    if (!Platform.isAndroid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not Supported'),
          content: const Text(
            'Automatic updates are only supported on Android. Please download the update manually from GitHub.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri.parse(updateInfo.downloadUrl);
                if (await canLaunchUrl(uri))
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('Open in Browser'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading update...'),
                SizedBox(height: 8),
                Text(
                  'This may take a few minutes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final updateService =
          updateServiceFactory?.call() ??
          UpdateService(owner: 'Giras91', repo: 'flutterpos');
      final apkPath = await updateService.downloadLatestApk(
        assetNameContains: '.apk',
      );

      if (context.mounted) Navigator.pop(context);

      await OpenFilex.open(apkPath);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Complete'),
            content: const Text(
              'The update has been downloaded. Please follow the on-screen instructions to install the update.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Failed'),
            content: Text('Failed to download update: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(updateInfo.downloadUrl);
                  if (await canLaunchUrl(uri))
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: const Text('Download Manually'),
              ),
            ],
          ),
        );
      }
    }
  }
}
