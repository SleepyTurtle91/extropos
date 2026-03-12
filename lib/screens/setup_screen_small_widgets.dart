part of 'setup_screen.dart';

extension _SetupScreenSmallWidgets on _SetupScreenState {
  Widget _buildStepContent(int currentStep) {
    switch (currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.store,
            _indigo,
            Colors.indigo.shade50,
            'Welcome to ExtroPOS',
            "Let's start by setting up your business profile.",
          ),
          const SizedBox(height: 40),
          _buildInputLabel('BUSINESS NAME'),
          TextField(
            controller: _storeNameCtrl,
            decoration: _inputDecoration('e.g. Daily Grind Coffee'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 32),
          _buildInputLabel('BUSINESS TYPE'),
          Row(
            children: [
              Expanded(
                child: _buildTypeBtn('retail', 'Retail', Icons.shopping_bag),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTypeBtn('cafe', 'Cafe', Icons.local_cafe),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTypeBtn('restaurant', 'Dining', Icons.restaurant),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTypeBtn(String id, String label, IconData icon) {
    final isSelected = _businessType == id;
    return InkWell(
      onTap: () {
        setState(() => _businessType = id);
        ConfigService.instance.setBusinessType(id);
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? _indigo : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? _indigo : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? _indigo : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SetupStep3Panel(
      ownerNameCtrl: _ownerNameCtrl,
      ownerEmailCtrl: _ownerEmailCtrl,
      ownerPinCtrl: _ownerPinCtrl,
      confirmPinCtrl: _confirmPinCtrl,
      onChanged: () => setState(() {}),
    );
  }

  Widget _buildStep4() {
    return SetupStep4Panel(
      syncMode: _syncMode,
      onSyncModeChanged: (mode) => setState(() => _syncMode = mode),
    );
  }

  Widget _buildSummaryRow(String label, String value, {String? subtext}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            if (subtext != null)
              Text(
                subtext,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _indigo, letterSpacing: 1),
              ),
          ],
        )
      ],
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _indigo,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _indigo.withOpacity(0.3),
                    blurRadius: 20,
                  )
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Setting up your POS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Initializing secure database & users...',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
      ),
    );
  }

}
