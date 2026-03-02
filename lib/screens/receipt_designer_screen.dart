import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/thermal_preview_widget.dart';
import 'package:flutter/material.dart';

part 'receipt_designer_models.dart';
part 'receipt_designer_operations.dart';
part 'receipt_designer_header.dart';
part 'receipt_designer_content.dart';
part 'receipt_designer_footer.dart';
part 'receipt_designer_preview_helpers.dart';

const _indigo = Color(0xFF4F46E5);
const _emerald = Color(0xFF10B981);

class ReceiptDesignerScreen extends StatefulWidget {
  const ReceiptDesignerScreen({super.key});

  @override
  State<ReceiptDesignerScreen> createState() => _ReceiptDesignerScreenState();
}

class _ReceiptDesignerScreenState extends State<ReceiptDesignerScreen> {
  bool _isLoading = true;
  ReceiptSettings _settings = ReceiptSettings();

  // UI State
  String _paperSize = '80mm';
  String _activeTab = 'header';

  // Receipt Configuration State
  bool _showLogo = true;
  String _storeName = '';
  String _address = '';
  String _taxId = '';
  bool _showTaxId = true;
  bool _showOrderNumber = true;
  String _itemFontSize = 'normal';
  bool _showBarcode = true;
  String _barcodeData = '';
  String _footerMessage = '';
  bool _showWifi = true;
  String _wifiDetails = 'WiFi: DailyGrind_Guest\nPass: coffee123';
  bool _showQrCode = true;
  String _qrData = '';

  final _storeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _wifiCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _qrCtrl = TextEditingController();

  final List<OrderItem> _mockItems = [
    OrderItem('Latte (Hot)', 1, 12.00),
    OrderItem('Avocado Toast', 1, 18.50),
    OrderItem('Espresso', 2, 16.00),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _taxIdCtrl.dispose();
    _footerCtrl.dispose();
    _wifiCtrl.dispose();
    _barcodeCtrl.dispose();
    _qrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 450,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              children: [
                _buildPanelHeader(),
                _buildTabs(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: _buildActiveTabContent(),
                  ),
                ),
                _buildActionsFooter(),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  Positioned(
                    top: 32,
                    right: 32,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: _emerald,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live Preview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Text(
                            '$_paperSize THERMAL OUTPUT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade500,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildThermalPreview(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
