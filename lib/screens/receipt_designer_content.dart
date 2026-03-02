part of 'receipt_designer_screen.dart';

extension ReceiptDesignerContent on _ReceiptDesignerScreenState {
  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'header':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggle(
              'Show Store Logo',
              _showLogo,
              (v) => setState(() => _showLogo = v),
              icon: Icons.image,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'Store Name',
              controller: _storeNameCtrl,
              onChanged: (v) => setState(() => _storeName = v),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'Store Address',
              controller: _addressCtrl,
              onChanged: (v) => setState(() => _address = v),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildToggle(
              'Show Tax/SST ID',
              _showTaxId,
              (v) => setState(() => _showTaxId = v),
            ),
            if (_showTaxId) ...[
              const SizedBox(height: 16),
              _buildTextField(
                'Tax/SST ID',
                controller: _taxIdCtrl,
                onChanged: (v) => setState(() => _taxId = v),
              ),
            ],
          ],
        );
      case 'items':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggle(
              'Show Order Number',
              _showOrderNumber,
              (v) => setState(() => _showOrderNumber = v),
            ),
            const SizedBox(height: 24),
            const Text(
              'ITEM FONT SIZE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildFontSizeBtn('small')),
                const SizedBox(width: 8),
                Expanded(child: _buildFontSizeBtn('normal')),
                const SizedBox(width: 8),
                Expanded(child: _buildFontSizeBtn('large')),
              ],
            )
          ],
        );
      case 'footer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              'Footer Message',
              controller: _footerCtrl,
              onChanged: (v) => setState(() => _footerMessage = v),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildToggle(
              'Show WiFi Details',
              _showWifi,
              (v) => setState(() => _showWifi = v),
            ),
            if (_showWifi) ...[
              const SizedBox(height: 16),
              _buildTextField(
                'WiFi Information',
                controller: _wifiCtrl,
                onChanged: (v) => setState(() => _wifiDetails = v),
                maxLines: 2,
                isMonospace: true,
              ),
            ],
          ],
        );
      case 'advanced':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggle(
              'Print Barcode (Receipt ID)',
              _showBarcode,
              (v) => setState(() => _showBarcode = v),
              icon: Icons.view_headline,
            ),
            if (_showBarcode) ...[
              const SizedBox(height: 16),
              _buildTextField(
                'Barcode Data',
                controller: _barcodeCtrl,
                onChanged: (v) => setState(() => _barcodeData = v),
              ),
            ],
            const SizedBox(height: 24),
            _buildToggle(
              'Print E-Invoice QR Code',
              _showQrCode,
              (v) => setState(() => _showQrCode = v),
              icon: Icons.qr_code,
            ),
            if (_showQrCode) ...[
              const SizedBox(height: 16),
              _buildTextField(
                'QR Data',
                controller: _qrCtrl,
                onChanged: (v) => setState(() => _qrData = v),
                maxLines: 2,
                isMonospace: true,
              ),
            ],
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildToggle(
    String label,
    bool value,
    Function(bool) onChanged, {
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Switch(
          value: value,
          onChanged: (val) => onChanged(val),
          activeColor: _indigo,
        )
      ],
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool isMonospace = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: isMonospace ? 'monospace' : 'sans-serif',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _indigo, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeBtn(String size) {
    final isActive = _itemFontSize == size;
    return InkWell(
      onTap: () => setState(() => _itemFontSize = size),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.indigo.shade50 : Colors.white,
          border: Border.all(
            color: isActive ? _indigo : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            size[0].toUpperCase() + size.substring(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? _indigo : Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
