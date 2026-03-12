part of 'setup_screen.dart';

extension _SetupScreenFutures on _SetupScreenState {
  Future<void> _finishSetup() async {
    if (_isProcessing) return;

    final storeName = _storeNameCtrl.text.trim();
    final ownerName = _ownerNameCtrl.text.trim();
    final ownerEmail = _ownerEmailCtrl.text.trim();
    final pin = _ownerPinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();

    if (storeName.isEmpty || _businessType.isEmpty) {
      ToastHelper.showToast(context, 'Complete the business profile first');
      return;
    }
    if (_terminalIdCtrl.text.trim().isEmpty) {
      ToastHelper.showToast(context, 'Enter a terminal ID');
      return;
    }
    if (ownerName.isEmpty || pin.length != 4 || confirm.length != 4) {
      ToastHelper.showToast(context, 'Enter a valid 4-digit PIN');
      return;
    }
    if (pin != confirm) {
      ToastHelper.showToast(context, 'PINs do not match');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await ConfigService.instance.setStoreName(storeName);
      await ConfigService.instance
          .setTerminalId(_terminalIdCtrl.text.trim().toUpperCase());
      await ConfigService.instance.setSyncMode(_syncMode);
      await ConfigService.instance.setBusinessType(_businessType);

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'business_info',
        {
          'name': storeName,
          'email': ownerEmail.isEmpty ? null : ownerEmail,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: ['1'],
      );

      final mode = _mapBusinessMode(_businessType);
      await BusinessInfo.updateInstance(
        BusinessInfo.instance.copyWith(
          businessName: storeName,
          ownerName: ownerName,
          email: ownerEmail,
          selectedBusinessMode: mode,
        ),
      );

      await ConfigService.instance.setSetupDone(true);

      final String newAdminId = const Uuid().v4();
      await db.delete('users', where: 'id = ?', whereArgs: ['1']);

      final user = User(
        id: newAdminId,
        username: ownerName.replaceAll(' ', '_').toLowerCase(),
        fullName: ownerName,
        email: ownerEmail,
        role: UserRole.admin,
        pin: pin,
      );

      await DatabaseService.instance.insertUser(user);

      try {
        await PinStore.instance.setAdminPin(pin);
      } catch (e) {
        debugPrint('Failed to save admin PIN: $e');
      }

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _step = 6;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ToastHelper.showToast(context, 'Setup failed: $e');
      debugPrint('Setup error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

}
