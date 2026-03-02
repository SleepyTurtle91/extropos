part of 'printers_management_screen.dart';

// Printer discovery operations extracted from PrintersManagementOperations
extension PrintersDiscoveryOperations on _PrintersManagementScreenState {
  Future<void> _discoverPrintersAsync() async {
    if (!mounted || !_isInitialized) return;

    try {
      debugPrint('🔍 Starting printer discovery...');

      // Detect iMin hardware and use very short timeout to prevent lag
      final isIMin = await _isIMinDevice();
      final timeoutDuration = isIMin
          ? const Duration(seconds: 2) // Reduced from 3 to 2 seconds
          : const Duration(seconds: 8); // Reduced from 10 to 8 seconds

      debugPrint(
        '📱 Device type: ${isIMin ? "iMin (2s timeout)" : "Other (8s timeout)"}',
      );

      // Show subtle indicator that discovery is running
      if (mounted) {
        ToastHelper.showToast(context, 'Discovering printers...');
      }

      // Add timeout to prevent hanging on iMin devices
      final discoveredPrinters = await _printerService.discoverPrinters().timeout(
        timeoutDuration,
        onTimeout: () {
          debugPrint(
            '⏱️ Printer discovery timed out after ${timeoutDuration.inSeconds} seconds',
          );
          if (mounted) {
            ToastHelper.showToast(
              context,
              'Printer discovery timed out. Some printers may not be detected.',
            );
          }
          return [];
        },
      );

      debugPrint('✅ Discovered ${discoveredPrinters.length} printers');

      if (!mounted) return;

      // Collect new printers to confirm
      final newPrinters = <Printer>[];
      final updatedPrinters = <Printer>[];

      for (final discovered in discoveredPrinters) {
        debugPrint(
          '  📍 Found: ${discovered.name} (${discovered.connectionType.name})',
        );

        final savedIndex = printers.indexWhere(
          (p) =>
              p.platformSpecificId == discovered.platformSpecificId ||
              p.id == discovered.id,
        );
        if (savedIndex == -1) {
          newPrinters.add(discovered);
        } else {
          // Only update if status actually changed to avoid unnecessary rebuilds
          final saved = printers[savedIndex];
          if (saved.status != discovered.status ||
              saved.hasPermission != discovered.hasPermission) {
            saved.status = discovered.status;
            saved.hasPermission = discovered.hasPermission;
            updatedPrinters.add(saved);
            debugPrint('    🔄 Updated printer: ${saved.name}');
          }
        }
      }

      // Update existing printers
      if (updatedPrinters.isNotEmpty) {
        setState(() {
          // Already updated in the loop above
        });
        // Persist updates asynchronously
        for (final updated in updatedPrinters) {
          unawaited(DatabaseService.instance.savePrinter(updated));
        }
      }

      // Confirm and add new printers
      for (final newPrinter in newPrinters) {
        final shouldAdd = await _confirmAddPrinter(newPrinter);
        if (shouldAdd && mounted) {
          try {
            await DatabaseService.instance.savePrinter(newPrinter);
            setState(() => printers.add(newPrinter));
            debugPrint('    ➕ Added new printer: ${newPrinter.name}');
            ToastHelper.showToast(context, 'Added printer: ${newPrinter.name}');
          } catch (e) {
            debugPrint('❌ Failed to save printer: $e');
            ToastHelper.showToast(context, 'Failed to save printer: $e');
          }
        } else {
          debugPrint('    ⏭️ Skipped printer: ${newPrinter.name}');
        }
      }

      if (mounted) {
        ToastHelper.showToast(
          context,
          newPrinters.isEmpty
              ? 'No new printers found'
              : 'Found ${newPrinters.length} new printer(s)',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Printer discovery failed: ${e.toString()}',
      );
    }
  }

  Future<void> _searchBluetoothPrinters() async {
    try {
      setState(() => _isLoading = true);

      debugPrint('🔍 Searching for Bluetooth printers...');
      final bluetoothPrinters =
          await _printerService.discoverBluetoothPrinters().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Bluetooth search timed out');
          return [];
        },
      );

      debugPrint(
        '✅ Found ${bluetoothPrinters.length} Bluetooth printer(s)',
      );

      if (!mounted) return;

      // Confirm each new Bluetooth printer
      final newBluetoothPrinters = <Printer>[];
      for (final discovered in bluetoothPrinters) {
        final exists = printers.any(
          (p) => p.bluetoothAddress == discovered.bluetoothAddress,
        );
        if (!exists) {
          newBluetoothPrinters.add(discovered);
        }
      }

      // Add confirmed printers to the list
      for (final newPrinter in newBluetoothPrinters) {
        final shouldAdd = await _confirmAddPrinter(newPrinter);
        if (shouldAdd && mounted) {
          try {
            await DatabaseService.instance.savePrinter(newPrinter);
            setState(() => printers.add(newPrinter));
            debugPrint('    ➕ Added new printer: ${newPrinter.name}');
            ToastHelper.showToast(
              context,
              'Added printer: ${newPrinter.name}',
            );
          } catch (e) {
            debugPrint('❌ Failed to save printer: $e');
            ToastHelper.showToast(context, 'Failed to save printer: $e');
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showToast(
          context,
          newBluetoothPrinters.isEmpty
              ? 'No new Bluetooth printers found'
              : 'Bluetooth search complete. ${newBluetoothPrinters.length} new printer(s) found.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error searching Bluetooth printers: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showToast(context, 'Error searching Bluetooth printers: $e');
    }
  }

  Future<void> _searchUsbPrinters() async {
    try {
      setState(() => _isLoading = true);

      debugPrint('🔍 Searching for USB printers...');
      final usbPrinters = await _printerService.discoverUsbPrinters().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ USB search timed out');
          return [];
        },
      );

      debugPrint('✅ Found ${usbPrinters.length} USB printer(s)');

      if (!mounted) return;

      // Confirm each new USB printer
      final newUsbPrinters = <Printer>[];
      for (final discovered in usbPrinters) {
        final exists = printers.any(
          (p) =>
              p.usbDeviceId == discovered.usbDeviceId ||
              p.platformSpecificId == discovered.platformSpecificId,
        );
        if (!exists) {
          newUsbPrinters.add(discovered);
        }
      }

      // Add confirmed printers to the list
      for (final newPrinter in newUsbPrinters) {
        final shouldAdd = await _confirmAddPrinter(newPrinter);
        if (shouldAdd && mounted) {
          try {
            await DatabaseService.instance.savePrinter(newPrinter);
            setState(() => printers.add(newPrinter));
            debugPrint('    ➕ Added new printer: ${newPrinter.name}');
            ToastHelper.showToast(context, 'Added printer: ${newPrinter.name}');
          } catch (e) {
            debugPrint('❌ Failed to save printer: $e');
            ToastHelper.showToast(context, 'Failed to save printer: $e');
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showToast(
          context,
          newUsbPrinters.isEmpty
              ? 'No new USB printers found'
              : 'USB search complete. ${newUsbPrinters.length} new printer(s) found.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error searching USB printers: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showToast(context, 'Error searching USB printers: $e');
    }
  }
}
