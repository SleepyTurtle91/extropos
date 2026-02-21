import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Result returned from the scanner with optional price override (for scale barcodes).
class ScannedProductResult {
  ScannedProductResult({required this.product, this.overridePrice});

  final Product product;
  final double? overridePrice;
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  String _scanResult = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String code = barcode.rawValue ?? '';

      if (code.isNotEmpty) {
        setState(() {
          _isScanning = false;
          _scanResult = code;
        });

        // Look up product by barcode (supports embedded-price scale codes)
        final product = await _findProductByBarcode(code);

        if (product != null) {
          // Return the product to the previous screen
          if (mounted) {
            Navigator.of(context).pop(product);
          }
        } else {
          // Show error and allow rescanning
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Product not found for barcode: $code'),
                action: SnackBarAction(
                  label: 'Scan Again',
                  onPressed: () {
                    setState(() {
                      _isScanning = true;
                      _scanResult = '';
                    });
                  },
                ),
              ),
            );
          }
        }
      }
    }
  }

  Future<ScannedProductResult?> _findProductByBarcode(String barcode) async {
    try {
      final items = await DatabaseService.instance.getItems();
      final categories = await DatabaseService.instance.getCategories();

      final scaleParse = _parseScaleBarcode(barcode);
      if (scaleParse != null) {
        final match = items
            .where(
              (item) =>
                  item.barcode == scaleParse.itemCode ||
                  item.sku == scaleParse.itemCode ||
                  (item.barcode != null &&
                      item.barcode!.endsWith(scaleParse.itemCode)),
            )
            .firstOrNull;

        if (match != null) {
          final product = _itemToProduct(match, categories);
          return ScannedProductResult(
            product: product,
            overridePrice: scaleParse.price,
          );
        }
      }

      final matchingItem = items
          .where((item) => item.barcode == barcode || item.sku == barcode)
          .firstOrNull;

      if (matchingItem != null) {
        final product = _itemToProduct(matchingItem, categories);
        return ScannedProductResult(product: product);
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  _ScaleBarcodeParseResult? _parseScaleBarcode(String raw) {
    final code = raw.trim();
    if (code.length < 12) return null;

    final prefix = code.substring(0, 2);
    const supportedPrefixes = {
      '20', // Common price-embedded prefix (RONGTA/CAS)
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29', // ASHICA often uses 29xx
    };
    if (!supportedPrefixes.contains(prefix)) return null;

    // Format: PP IIIII PPPPP C
    // PP = prefix, IIIII = item/PLU, PPPPP = price in cents, C = checksum (ignored)
    if (code.length < 13) return null;
    final itemCode = code.substring(2, 7);
    final priceStr = code.substring(7, 12);
    final priceCents = int.tryParse(priceStr);
    if (priceCents == null) return null;

    return _ScaleBarcodeParseResult(
      itemCode: itemCode,
      price: priceCents / 100,
    );
  }

  Product _itemToProduct(Item item, List<Category> categories) {
    final category = categories
        .where((c) => c.id == item.categoryId)
        .firstOrNull;

    return Product(
      item.name,
      item.price,
      category?.name ?? 'Uncategorized',
      item.icon,
      imagePath: item.imageUrl,
      printerOverride: item.printerOverride,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          // Overlay with scan area
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Stack(
              children: [
                // Top overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: Container(color: Colors.black.withOpacity(0.7)),
                ),
                // Bottom overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: Container(color: Colors.black.withOpacity(0.7)),
                ),
                // Left overlay
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2,
                  left: 0,
                  width: MediaQuery.of(context).size.width * 0.1,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Container(color: Colors.black.withOpacity(0.7)),
                ),
                // Right overlay
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2,
                  right: 0,
                  width: MediaQuery.of(context).size.width * 0.1,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Container(color: Colors.black.withOpacity(0.7)),
                ),
                // Scan area border
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2,
                  left: MediaQuery.of(context).size.width * 0.1,
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Center instructions
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isScanning
                            ? 'Position barcode within the frame'
                            : 'Processing...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_scanResult.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Scanned: $_scanResult',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Cancel button
          Positioned(
            bottom: 32,
            left: 32,
            right: 32,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleBarcodeParseResult {
  const _ScaleBarcodeParseResult({required this.itemCode, required this.price});

  final String itemCode;
  final double price;
}
