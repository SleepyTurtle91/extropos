// ignore_for_file: unused_element

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/enum_models.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/setup_step3_panel.dart';
import 'package:extropos/widgets/setup_step4_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

part 'setup_screen_large_widgets.dart';
part 'setup_screen_medium_widgets.dart';
part 'setup_screen_small_widgets.dart';
part 'setup_screen_futures.dart';
part 'setup_screen_operations.dart';
part 'setup_screen_helpers.dart';

const _indigo = Color(0xFF4F46E5);
const _emerald = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _sky = Color(0xFF0EA5E9);
const _rose = Color(0xFFF43F5E);
const _slate900 = Color(0xFF0F172A);
const _slate800 = Color(0xFF1E293B);
const _slate600 = Color(0xFF475569);

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _storeNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _terminalIdCtrl = TextEditingController(text: 'TERM-01');

  int _step = 1;
  final int _totalSteps = 5;
  bool _isProcessing = false;

  String _businessType = '';
  String _syncMode = 'local';

  @override
  void initState() {
    super.initState();
    final config = ConfigService.instance;
    if (config.storeName.isNotEmpty) {
      _storeNameCtrl.text = config.storeName;
    }
    final terminalId = config.terminalId;
    if (terminalId.isNotEmpty) {
      _terminalIdCtrl.text = terminalId;
    }
    _syncMode = config.syncMode.isNotEmpty ? config.syncMode : 'local';
    _businessType = config.businessType;
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _ownerPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    _terminalIdCtrl.dispose();
    super.dispose();
  }





  BusinessMode _mapBusinessMode(String value) {
    switch (value) {
      case 'retail':
        return BusinessMode.retail;
      case 'cafe':
        return BusinessMode.cafe;
      case 'restaurant':
        return BusinessMode.restaurant;
      default:
        return BusinessMode.retail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _indigo,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _indigo.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'E',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ExtroPOS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _slate800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    if (_step <= _totalSteps) _buildProgressBar(),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            maxWidth: 680,
                            minHeight: 450,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder:
                                          (Widget child, Animation<double> animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.05, 0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildStepContent(_step),
                                    ),
                                  ),
                                  if (_step <= _totalSteps) _buildBottomNav(),
                                ],
                              ),
                              if (_isProcessing) _buildProcessingOverlay(),
                              if (_step == 6) _buildSuccessScreen(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_step <= _totalSteps)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'EXTROPOS INSTALLATION WIZARD • V2.4.8',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            letterSpacing: 2,
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









  Widget _buildStepHeader(
    IconData icon,
    Color color,
    Color bgColor,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: _indigo, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }
  InputDecoration _pinInputDecoration(bool isError) {
    return InputDecoration(
      hintText: '....',
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 12),
        child: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
      ),
      filled: true,
      fillColor: isError ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isError ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isError ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isError ? _rose : _amber,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }
}