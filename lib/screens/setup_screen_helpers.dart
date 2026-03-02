part of 'setup_screen.dart';

extension SetupScreenHelpers on _SetupScreenState {
  bool _isNextDisabled() {
    if (_step == 1) {
      return _storeNameCtrl.text.trim().isEmpty || _businessType.isEmpty;
    }
    if (_step == 2) return _terminalIdCtrl.text.trim().isEmpty;
    if (_step == 3) {
      final pin = _ownerPinCtrl.text.trim();
      final confirm = _confirmPinCtrl.text.trim();
      return _ownerNameCtrl.text.trim().isEmpty ||
          pin.length != 4 ||
          confirm.length != 4 ||
          pin != confirm;
    }
    return false;
  }

}
