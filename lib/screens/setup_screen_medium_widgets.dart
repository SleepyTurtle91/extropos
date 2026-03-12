part of 'setup_screen.dart';

extension _SetupScreenMediumWidgets on _SetupScreenState {
  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.monitor,
            _emerald,
            Colors.green.shade50,
            'Terminal Setup',
            'Configure this device for your store network.',
          ),
          const SizedBox(height: 40),
          _buildInputLabel('TERMINAL ID'),
          TextFormField(
            controller: _terminalIdCtrl,
            onChanged: (_) => setState(() {}),
            inputFormatters: [UpperCaseTextFormatter()],
            decoration: _inputDecoration('e.g. TERM-01'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Used for identifying transactions from this specific device.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hardware Integration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detect attached printers & scanners',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text(
                    'Auto-Detect',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      key: const ValueKey(5),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.check_circle,
            Colors.grey.shade600,
            Colors.grey.shade100,
            'Ready to Initialize',
            'Review your settings before creating the database.',
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Business',
                  _storeNameCtrl.text.trim().isEmpty
                      ? 'Not set'
                      : _storeNameCtrl.text.trim(),
                  subtext: _businessType.isEmpty
                      ? null
                      : _businessType.toUpperCase(),
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'Terminal ID',
                  _terminalIdCtrl.text.trim().isEmpty
                      ? 'Not set'
                      : _terminalIdCtrl.text.trim(),
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'Owner Account',
                  _ownerNameCtrl.text.trim().isEmpty
                      ? 'Not set'
                      : _ownerNameCtrl.text.trim(),
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'Storage Mode',
                  _syncMode == 'local' ? 'Local Only' : 'Cloud Sync',
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Container(
      color: _indigo,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 32),
          const Text(
            "You're All Set!",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
          ),
          const SizedBox(height: 16),
          Text(
            "ExtroPOS is configured and ready for business.\nLet's make some sales.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.indigo.shade100, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _indigo,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 12,
              shadowColor: Colors.black.withOpacity(0.5),
            ),
            child: const Text(
              'Launch Point of Sale',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _step == 1 ? null : _handleBack,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledForegroundColor: Colors.grey.shade300,
            ),
          ),
          ElevatedButton(
            onPressed: _isNextDisabled() ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _step == _totalSteps ? _emerald : _indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade400,
              elevation: _isNextDisabled() ? 0 : 8,
              shadowColor:
                  (_step == _totalSteps ? _emerald : _indigo).withOpacity(0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _step == _totalSteps ? 'Initialize System' : 'Continue',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_step != _totalSteps) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

}
