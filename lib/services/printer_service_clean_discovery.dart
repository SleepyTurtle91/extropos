part of 'printer_service_clean.dart';

extension PrinterServiceDiscovery on PrinterService {
  Future<List<Printer>> discoverPrinters() async {
    try {
      final List<Printer> allPrinters = [];
      final savedPrinters = await DatabaseService.instance.getPrinters();
      allPrinters.addAll(savedPrinters);

      if (Platform.isAndroid) {
        final androidPrinters = await _androidService.discoverPrinters();
        for (final discovered in androidPrinters) {
          if (!allPrinters.any((p) => p.id == discovered.id)) allPrinters.add(discovered);
        }

        if (await isIMinDevice()) {
          if (!allPrinters.any((p) => p.id == 'imin_printer')) {
            final iminPrinter = Printer(
              id: 'imin_printer',
              name: 'iMin Built-in Printer',
              type: PrinterType.receipt,
              connectionType: PrinterConnectionType.usb,
              status: PrinterStatus.offline,
              isDefault: false,
              modelName: 'iMin Swan 2',
              paperSize: ThermalPaperSize.mm80,
              categories: [],
            );
            allPrinters.add(iminPrinter);
            await DatabaseService.instance.savePrinter(iminPrinter);
          }
        }
      } else if (Platform.isWindows) {
        final windowsPrinters = await _windowsService.discoverPrinters();
        for (final discovered in windowsPrinters) {
          if (!allPrinters.any((p) => p.id == discovered.id)) allPrinters.add(discovered);
        }
      }
      return allPrinters;
    } catch (_) {
      return await DatabaseService.instance.getPrinters().catchError((_) => <Printer>[]);
    }
  }

  Future<bool> isIMinDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final model = androidInfo.model.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();
      return model.contains('imin') || model.contains('swan') || model.contains('d3') || model.contains('d4') ||
             manufacturer.contains('imin') || manufacturer.contains('sunmi') || brand.contains('imin');
    } catch (e) {
      developer.log('Error detecting iMin device: $e');
      return false;
    }
  }

  Future<List<Printer>> discoverBluetoothPrinters() async {
    return Platform.isAndroid ? await _androidService.discoverBluetoothPrinters() : [];
  }

  Future<List<Printer>> discoverUsbPrinters() async {
    if (Platform.isAndroid) return await _androidService.discoverUsbPrinters();
    if (Platform.isWindows) return await _windowsService.discoverUsbPrinters();
    return [];
  }

  Future<bool> requestUsbPermission(Printer printer) async {
    return Platform.isAndroid ? await _androidService.requestUsbPermission(printer) : true;
  }

  Future<bool> requestBluetoothPermission(Printer printer) async {
    if (Platform.isAndroid) {
      final ok = await PermissionsHelper.requestBluetoothPermissions();
      if (ok) {
        printer.hasPermission = true;
        await DatabaseService.instance.savePrinter(printer);
      }
      return ok;
    }
    return true;
  }
}
