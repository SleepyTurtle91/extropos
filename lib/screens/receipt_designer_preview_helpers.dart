part of 'receipt_designer_screen.dart';

extension ReceiptDesignerPreviewHelpers on _ReceiptDesignerScreenState {
  Widget _buildThermalPreview() {
    return ThermalPreviewWidget(
      paperSize: _paperSize,
      showLogo: _showLogo,
      storeName: _storeName,
      address: _address,
      showTaxId: _showTaxId,
      taxId: _taxId,
      itemFontSize: _itemFontSize,
      showOrderNumber: _showOrderNumber,
      showWifi: _showWifi,
      wifiDetails: _wifiDetails,
      showBarcode: _showBarcode,
      showQrCode: _showQrCode,
      footerMessage: _footerMessage,
      mockItems: _mockItems,
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.5;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54),
              ),
            );
          }),
        );
      },
    );
  }
}
