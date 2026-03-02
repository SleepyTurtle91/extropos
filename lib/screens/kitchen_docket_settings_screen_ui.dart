part of 'kitchen_docket_settings_screen.dart';

extension KitchenDocketSettingsScreenUI on _KitchenDocketSettingsScreenState {
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kitchen Docket Settings'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Docket Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Section
          const Card(
            color: Color(0xFFFFF3CD),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Color(0xFF856404)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configure how kitchen dockets are printed for your kitchen staff',
                      style: TextStyle(color: Color(0xFF856404)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Template Style Section
          _buildSectionHeader('🍳 Template Style'),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Choose the layout format for kitchen dockets',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          _buildKitchenTemplateCard(),

          const SizedBox(height: 24),

          // Header Text
          _buildSectionHeader('Header Text'),
          _buildTextFieldCard(
            _kitchenHeaderController,
            'Kitchen Header Text',
            'e.g., KITCHEN ORDER, NEW ORDER',
            Icons.restaurant_menu,
            1,
          ),

          const SizedBox(height: 24),

          // Footer Text
          _buildSectionHeader('Footer Text'),
          _buildTextFieldCard(
            _kitchenFooterController,
            'Kitchen Footer Text',
            'e.g., Rush orders, Thank you (optional)',
            Icons.note,
            2,
          ),

          const SizedBox(height: 24),

          // Font Size
          _buildSectionHeader('Font Size'),
          _buildKitchenFontSizeCard(),

          const SizedBox(height: 24),

          // Display Options
          _buildSectionHeader('Display Options'),
          _buildDisplayOptionsCard(),

          const SizedBox(height: 24),

          // Save Button
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

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

  Widget _buildKitchenTemplateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Template',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<KitchenTemplateStyle>(
              initialValue: _settings.kitchenTemplateStyle,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixIcon: Icon(Icons.article),
              ),
              items: const [
                DropdownMenuItem(
                  value: KitchenTemplateStyle.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Standard',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Detailed order layout with full information',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: KitchenTemplateStyle.compact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Compact',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Table number focused with merchant sections',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _settings = _settings.copyWith(kitchenTemplateStyle: value);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            // Template Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _settings.kitchenTemplateStyle ==
                            KitchenTemplateStyle.standard
                        ? 'Preview: Standard Template'
                        : 'Preview: Compact Template',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _settings.kitchenTemplateStyle ==
                            KitchenTemplateStyle.standard
                        ? '• Full order details\n• Item modifiers shown\n• Traditional kitchen docket layout'
                        : '• Large table number focus\n• Merchant-organized sections\n• Compact item listing',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Live Preview of generated kitchen docket using current settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Preview',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      color: Colors.black,
                      padding: const EdgeInsets.all(8),
                      child: SelectableText(
                        _buildPreviewText(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKitchenFontSizeCard() {
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
                    value: _settings.kitchenFontSize.toDouble(),
                    min: 10,
                    max: 24,
                    divisions: 14,
                    label: _settings.kitchenFontSize.toString(),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          kitchenFontSize: value.round(),
                        );
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${_settings.kitchenFontSize}pt',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kitchen docket text at ${_settings.kitchenFontSize}pt',
              style: TextStyle(fontSize: _settings.kitchenFontSize.toDouble()),
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
            title: const Text('Show Date & Time'),
            subtitle: const Text('Display timestamp on kitchen dockets'),
            value: _settings.kitchenShowDateTime,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(kitchenShowDateTime: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Table Number'),
            subtitle: const Text('Display table number on dockets'),
            value: _settings.kitchenShowTable,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(kitchenShowTable: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Order Number'),
            subtitle: const Text('Display order ID on dockets'),
            value: _settings.kitchenShowOrderNumber,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(kitchenShowOrderNumber: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Modifiers'),
            subtitle: const Text(
              'Display item modifiers (e.g., no onions, extra cheese)',
            ),
            value: _settings.kitchenShowModifiers,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(kitchenShowModifiers: value);
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
        child: ElevatedButton.icon(
          onPressed: _saveSettings,
          icon: const Icon(Icons.save),
          label: const Text('Save Kitchen Docket Settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }
}
