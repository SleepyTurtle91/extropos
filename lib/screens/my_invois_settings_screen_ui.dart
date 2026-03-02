part of 'my_invois_settings_screen.dart';

extension _MyInvoisSettingsUIBuilders on _MyInvoisSettingsScreenState {
  Widget buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MyInvois Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable MyInvois integration'),
              subtitle: const Text('Submit e-invoices to MyInvois platform'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Environment',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Sandbox'),
                    subtitle: const Text('Test environment'),
                    value: true,
                    groupValue: _useSandbox,
                    onChanged: _isEnabled
                        ? (val) => _onEnvironmentChanged(val!)
                        : null,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Production'),
                    subtitle: const Text('Live submissions'),
                    value: false,
                    groupValue: _useSandbox,
                    onChanged: _isEnabled
                        ? (val) => _onEnvironmentChanged(val!)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildTextField(
              controller: _sstController,
              label: 'SST Registration Number *',
              hint: 'e.g., W10-1808-32000000',
              validator: _isEnabled
                  ? (v) =>
                      v == null || v.trim().isEmpty ? 'SST number is required' : null
                  : null,
            ),
            const SizedBox(height: 16),
            buildTextField(
              controller: _brnController,
              label: 'Business Registration Number (BRN)',
              hint: 'e.g., 201701012345',
            ),
            const SizedBox(height: 16),
            buildTextField(
              controller: _emailController,
              label: 'Business Email',
              hint: 'e.g., billing@company.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            buildTextField(
              controller: _phoneController,
              label: 'Business Phone',
              hint: 'e.g., +60123456789',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            buildTextField(
              controller: _addressController,
              label: 'Business Address',
              hint: 'Full address for invoices',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text('Reset to defaults'),
                  onPressed: _confirmResetToDefaults,
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_sync),
                      label: const Text('Test connection'),
                      onPressed: _isEnabled && !_isTesting ? _testConnection : null,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save settings'),
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status & Requirements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                buildStatusChip(
                  _isEnabled ? 'Enabled' : 'Disabled',
                  _isEnabled ? Colors.green : Colors.orange,
                  _isEnabled ? Icons.verified : Icons.privacy_tip_outlined,
                ),
                const SizedBox(width: 8),
                buildStatusChip(
                  _useSandbox
                      ? 'Sandbox'
                      : _hasRecentSuccessfulTest
                          ? 'Production'
                          : 'Production (blocked)',
                  _useSandbox
                      ? Colors.blue
                      : _hasRecentSuccessfulTest
                          ? Colors.redAccent
                          : Colors.orange,
                  _useSandbox
                      ? Icons.science
                      : _hasRecentSuccessfulTest
                          ? Icons.public
                          : Icons.lock_clock,
                ),
              ],
            ),
            const SizedBox(height: 12),
            buildStatusRow('SST Registration', _sstController.text.isEmpty ? 'Not set' : _sstController.text),
            buildStatusRow('BRN', _brnController.text.isEmpty ? 'Not set' : _brnController.text),
            buildStatusRow('Email', _emailController.text.isEmpty ? 'Not set' : _emailController.text),
            buildStatusRow('Phone', _phoneController.text.isEmpty ? 'Not set' : _phoneController.text),
            buildStatusRow('Address', _addressController.text.isEmpty ? 'Not set' : _addressController.text),
            buildStatusRow('Guard window', '$_guardHours hours'),
            const SizedBox(height: 12),
            buildLastTestBadge(),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            if (!_useSandbox && !_hasRecentSuccessfulTest)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: buildGuardNotice(),
              ),
            buildGuardSelector(),
            const Text(
              'Checklist',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            buildChecklistItem('SST registration number is required when enabled'),
            buildChecklistItem('Use sandbox environment for testing invoices'),
            buildChecklistItem('Ensure accurate business details for submissions'),
            buildChecklistItem(
              'Successful test in last $_guardHours hours required before production',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget buildLastTestBadge() {
    if (_lastTestedAt == null || _lastTestSuccess == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text('No test performed yet', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    }

    final timeAgo = DateTime.now().difference(_lastTestedAt!);
    final isRecent = _hasRecentSuccessfulTest;
    final formatter = DateFormat('MMM dd, yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lastTestSuccess!
            ? (isRecent ? Colors.green[50] : Colors.orange[50])
            : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _lastTestSuccess!
              ? (isRecent ? Colors.green : Colors.orange)
              : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _lastTestSuccess!
                ? (isRecent ? Icons.check_circle : Icons.warning)
                : Icons.error,
            color: _lastTestSuccess!
                ? (isRecent ? Colors.green : Colors.orange)
                : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastTestSuccess!
                      ? (isRecent
                          ? 'Last test successful'
                          : 'Test success expired')
                      : 'Last test failed',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _lastTestSuccess!
                        ? (isRecent ? Colors.green[800] : Colors.orange[800])
                        : Colors.red[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatter.format(_lastTestedAt!)} (${_formatTimeAgo(timeAgo)})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Widget buildGuardNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Production locked. Run a successful test within the last $_guardHours hours to go live.',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGuardSelector() {
    const options = [6, 12, 24, 48, 72];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Production guard window',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _guardHours,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: options
                .map(
                  (h) => DropdownMenuItem(
                    value: h,
                    child: Text('$h hours'),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => _guardHours = val);
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'Require a recent successful test before allowing production.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
