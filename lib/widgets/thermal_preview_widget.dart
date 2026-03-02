import 'package:flutter/material.dart';

class ThermalPreviewWidget extends StatelessWidget {
  final String paperSize;
  final bool showLogo;
  final String storeName;
  final String address;
  final bool showTaxId;
  final String taxId;
  final String itemFontSize;
  final bool showOrderNumber;
  final bool showWifi;
  final String wifiDetails;
  final bool showBarcode;
  final bool showQrCode;
  final String footerMessage;
  final List<dynamic> mockItems; // Accept dynamic to avoid circular imports

  const ThermalPreviewWidget({
    required this.paperSize,
    required this.showLogo,
    required this.storeName,
    required this.address,
    required this.showTaxId,
    required this.taxId,
    required this.itemFontSize,
    required this.showOrderNumber,
    required this.showWifi,
    required this.wifiDetails,
    required this.showBarcode,
    required this.showQrCode,
    required this.footerMessage,
    required this.mockItems,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width = paperSize == '80mm' ? 350.0 : 260.0;
    final baseFontSize = paperSize == '80mm' ? 14.0 : 12.0;
    final headerSize = paperSize == '80mm' ? 24.0 : 20.0;

    double itemSize;
    if (itemFontSize == 'small') {
      itemSize = baseFontSize - 4;
    } else if (itemFontSize == 'large') {
      itemSize = baseFontSize + 2;
    } else {
      itemSize = baseFontSize - 2;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'monospace', color: Colors.black87),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (showLogo) ...[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black26,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Icon(Icons.image, color: Colors.black26, size: 24),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  storeName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: headerSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize - 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showTaxId && taxId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    taxId,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: baseFontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildDashedLine(baseFontSize),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date: 22/02/2026',
                      style: TextStyle(
                        fontSize: baseFontSize - 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Time: 14:30',
                      style: TextStyle(
                        fontSize: baseFontSize - 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showOrderNumber)
                      Text(
                        'Order: #082',
                        style: TextStyle(
                          fontSize: baseFontSize - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      'Term: 01',
                      style: TextStyle(
                        fontSize: baseFontSize - 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDashedLine(baseFontSize),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ITEM',
                      style: TextStyle(fontSize: itemSize, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'AMT',
                      style: TextStyle(fontSize: itemSize, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._buildMockItemsList(itemSize),
                const SizedBox(height: 16),
                _buildDashedLine(baseFontSize),
                const SizedBox(height: 16),
                _buildSummaryRow('Subtotal', 'RM 46.50', baseFontSize),
                const SizedBox(height: 4),
                _buildSummaryRow('SST (8%)', 'RM 3.72', baseFontSize),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black87, width: 2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: baseFontSize + 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'RM 50.22',
                        style: TextStyle(
                          fontSize: baseFontSize + 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDashedLine(baseFontSize),
                const SizedBox(height: 16),
                _buildSummaryRow('Paid (Credit Card)', 'RM 50.22', baseFontSize),
                const SizedBox(height: 24),
                Text(
                  footerMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize - 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showWifi) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black38)),
                    child: Text(
                      wifiDetails,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: baseFontSize - 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (showBarcode) ...[
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Container(
                        height: 40,
                        width: double.infinity,
                        color: Colors.black87,
                        margin: const EdgeInsets.only(bottom: 4),
                      ),
                      Text(
                        'RCP-82910482',
                        style: TextStyle(
                          fontSize: baseFontSize - 4,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  )
                ],
                if (showQrCode) ...[
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black87, width: 2),
                        ),
                        child: const Icon(Icons.qr_code, size: 64, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      const Text('Scan for feedback')
                    ],
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMockItemsList(double itemSize) {
    return mockItems
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(item.qty as int)}x ${item.name as String}',
                  style: TextStyle(
                    fontSize: itemSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  (item.price as double).toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: itemSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildSummaryRow(String label, String amount, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize - 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: fontSize - 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine(double fontSize) {
    return Row(
      children: List.generate(
        25,
        (_) => Text(
          '-',
          style: TextStyle(fontSize: fontSize - 2),
        ),
      ),
    );
  }
}
