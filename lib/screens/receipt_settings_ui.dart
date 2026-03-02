part of 'receipt_settings_screen.dart';

/// Extension providing all UI builder methods for receipt settings configuration
extension _ReceiptSettingsScreenUIBuilders on _ReceiptSettingsScreenState {
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildPaperSizeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _PaperSizeTile(
              title: ReceiptPaperSize.mm58.displayName,
              subtitle: '${ReceiptPaperSize.mm58.widthInMm}mm width',
              selected: _settings.paperSize == ReceiptPaperSize.mm58,
              onTap: () {
                setState(() {
                  _settings = _settings.copyWith(
                    paperSize: ReceiptPaperSize.mm58,
                    paperWidth: ReceiptPaperSize.mm58.widthInMm,
                  );
                });
              },
            ),
            _PaperSizeTile(
              title: ReceiptPaperSize.mm80.displayName,
              subtitle: '${ReceiptPaperSize.mm80.widthInMm}mm width',
              selected: _settings.paperSize == ReceiptPaperSize.mm80,
              onTap: () {
                setState(() {
                  _settings = _settings.copyWith(
                    paperSize: ReceiptPaperSize.mm80,
                    paperWidth: ReceiptPaperSize.mm80.widthInMm,
                  );
                });
              },
            ),
            _PaperSizeTile(
              title: ReceiptPaperSize.a4.displayName,
              subtitle: '${ReceiptPaperSize.a4.widthInMm}mm width',
              selected: _settings.paperSize == ReceiptPaperSize.a4,
              onTap: () {
                setState(() {
                  _settings = _settings.copyWith(
                    paperSize: ReceiptPaperSize.a4,
                    paperWidth: ReceiptPaperSize.a4.widthInMm,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _settings.fontSize.toDouble(),
                    min: 8,
                    max: 20,
                    divisions: 12,
                    label: _settings.fontSize.toString(),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(fontSize: value.round());
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${_settings.fontSize}pt',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sample text at ${_settings.fontSize}pt',
              style: TextStyle(fontSize: _settings.fontSize.toDouble()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayOptionsCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Show Logo'),
            subtitle: const Text('Display business logo on receipt'),
            value: _settings.showLogo,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showLogo: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Date & Time'),
            subtitle: const Text('Display transaction timestamp'),
            value: _settings.showDateTime,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showDateTime: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Order Number'),
            subtitle: const Text('Display unique order ID'),
            value: _settings.showOrderNumber,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showOrderNumber: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Cashier Name'),
            subtitle: const Text('Display staff member name'),
            value: _settings.showCashierName,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showCashierName: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Tax Breakdown'),
            subtitle: const Text('Display detailed tax information'),
            value: _settings.showTaxBreakdown,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showTaxBreakdown: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Service Charge Breakdown'),
            subtitle: const Text('Display detailed service charge information'),
            value: _settings.showServiceChargeBreakdown,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  showServiceChargeBreakdown: value,
                );
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Thank You Message'),
            subtitle: const Text('Display customized thank you text'),
            value: _settings.showThankYouMessage,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showThankYouMessage: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldCard(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    int maxLines,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
          ),
          maxLines: maxLines,
        ),
      ),
    );
  }

  Widget _buildPrintOptionsCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Auto Print'),
            subtitle: const Text(
              'Automatically print receipt after transaction',
            ),
            value: _settings.autoPrint,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(autoPrint: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _previewReceipt,
              icon: const Icon(Icons.preview),
              label: const Text('Preview Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
