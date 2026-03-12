part of 'setup_screen.dart';

extension _SetupScreenOperations on _SetupScreenState {
  void _handleNext() {
    if (_isNextDisabled()) return;
    if (_step < _totalSteps) {
      setState(() => _step++);
    } else {
      _finishSetup();
    }
  }

  void _handleBack() {
    if (_step > 1) {
      setState(() => _step--);
    }
  }

}
