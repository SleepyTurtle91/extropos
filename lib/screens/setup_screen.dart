import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_mode.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

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
  static const _indigo = Color(0xFF4F46E5);
  static const _emerald = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _sky = Color(0xFF0EA5E9);
  static const _rose = Color(0xFFF43F5E);
  static const _slate900 = Color(0xFF0F172A);
  static const _slate800 = Color(0xFF1E293B);
  static const _slate600 = Color(0xFF475569);

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

  void _handleNext() {
    if (_isNextDisabled()) return;
    if (_step < _totalSteps) {
      setState(() => _step++);
    } else {
      _finishSetup();
    }
  }

  void _handleBack() {
    if (_step > 1) {
      setState(() => _step--);
    }
  }

  bool _isNextDisabled() {
    if (_step == 1) {
      return _storeNameCtrl.text.trim().isEmpty || _businessType.isEmpty;
    }
    if (_step == 2) return _terminalIdCtrl.text.trim().isEmpty;
    if (_step == 3) {
      final pin = _ownerPinCtrl.text.trim();
      final confirm = _confirmPinCtrl.text.trim();
      return _ownerNameCtrl.text.trim().isEmpty ||
          pin.length != 4 ||
          confirm.length != 4 ||
          pin != confirm;
    }
    return false;
  }

  Future<void> _finishSetup() async {
    if (_isProcessing) return;

    final storeName = _storeNameCtrl.text.trim();
    final ownerName = _ownerNameCtrl.text.trim();
    final ownerEmail = _ownerEmailCtrl.text.trim();
    final pin = _ownerPinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();

    if (storeName.isEmpty || _businessType.isEmpty) {
      ToastHelper.showToast(context, 'Complete the business profile first');
      return;
    }
    if (_terminalIdCtrl.text.trim().isEmpty) {
      ToastHelper.showToast(context, 'Enter a terminal ID');
      return;
    }
    if (ownerName.isEmpty || pin.length != 4 || confirm.length != 4) {
      ToastHelper.showToast(context, 'Enter a valid 4-digit PIN');
      return;
    }
    if (pin != confirm) {
      ToastHelper.showToast(context, 'PINs do not match');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await ConfigService.instance.setStoreName(storeName);
      await ConfigService.instance
          .setTerminalId(_terminalIdCtrl.text.trim().toUpperCase());
      await ConfigService.instance.setSyncMode(_syncMode);
      await ConfigService.instance.setBusinessType(_businessType);

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'business_info',
        {
          'name': storeName,
          'email': ownerEmail.isEmpty ? null : ownerEmail,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: ['1'],
      );

      final mode = _mapBusinessMode(_businessType);
      await BusinessInfo.updateInstance(
        BusinessInfo.instance.copyWith(
          businessName: storeName,
          ownerName: ownerName,
          email: ownerEmail,
          selectedBusinessMode: mode,
        ),
      );

      await ConfigService.instance.setSetupDone(true);

      final String newAdminId = const Uuid().v4();
      await db.delete('users', where: 'id = ?', whereArgs: ['1']);

      final user = User(
        id: newAdminId,
        username: ownerName.replaceAll(' ', '_').toLowerCase(),
        fullName: ownerName,
        email: ownerEmail,
        role: UserRole.admin,
        pin: pin,
      );

      await DatabaseService.instance.insertUser(user);

      try {
        await PinStore.instance.setAdminPin(pin);
      } catch (e) {
        debugPrint('Failed to save admin PIN: $e');
      }

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _step = 6;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ToastHelper.showToast(context, 'Setup failed: $e');
      debugPrint('Setup error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
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

  Widget _buildProgressBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.only(bottom: 48),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                final stepNum = (index ~/ 2) + 1;
                final isPast = _step > stepNum;
                final isActive = _step >= stepNum;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? _indigo : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? _indigo : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _indigo.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isPast
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '$stepNum',
                            style: TextStyle(
                              color:
                                  isActive ? Colors.white : Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }

              final stepNum = (index ~/ 2) + 1;
              final isActive = _step > stepNum;
              return Expanded(
                child: Container(
                  height: 4,
                  color: isActive ? _indigo : Colors.grey.shade200,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUSINESS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'TERMINAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'OWNER',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'DATABASE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'READY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

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

  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.monitor,
            _emerald,
            Colors.green.shade50,
            'Terminal Setup',
            'Configure this device for your store network.',
          ),
          const SizedBox(height: 40),
          _buildInputLabel('TERMINAL ID'),
          TextFormField(
            controller: _terminalIdCtrl,
            onChanged: (_) => setState(() {}),
            inputFormatters: [UpperCaseTextFormatter()],
            decoration: _inputDecoration('e.g. TERM-01'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Used for identifying transactions from this specific device.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hardware Integration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detect attached printers & scanners',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text(
                    'Auto-Detect',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final pinMismatch = _confirmPinCtrl.text.isNotEmpty &&
        _ownerPinCtrl.text.trim() != _confirmPinCtrl.text.trim();

    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.person,
            _amber,
            Colors.amber.shade50,
            'Owner Setup',
            'Create the primary manager account for the system.',
          ),
          const SizedBox(height: 40),
          _buildInputLabel('MANAGER NAME'),
          TextFormField(
            controller: _ownerNameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration('e.g. Alex Johnson'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 24),
          _buildInputLabel('MANAGER EMAIL (OPTIONAL)'),
          TextFormField(
            controller: _ownerEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('e.g. alex@example.com'),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('4-DIGIT PIN'),
                    TextFormField(
                      controller: _ownerPinCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _pinInputDecoration(false),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('CONFIRM PIN'),
                    TextFormField(
                      controller: _confirmPinCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _pinInputDecoration(pinMismatch),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pinMismatch)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'PINs do not match.',
                style: TextStyle(
                  color: _rose,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.cloud,
            _sky,
            Colors.lightBlue.shade50,
            'Database & Sync',
            'Choose how ExtroPOS stores your data.',
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: Colors.grey.shade200, width: 2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Opacity(
              opacity: 0.6,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cloud Sync',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'COMING SOON',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: _indigo,
                                  letterSpacing: 1,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Automatically backup data, sync across multiple terminals, and access real-time online reports.',
                          style: TextStyle(
                            color: Colors.grey,
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _syncMode = 'local'),
            borderRadius: BorderRadius.circular(32),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _syncMode == 'local'
                    ? const Color(0xFFF8FAFC)
                    : Colors.white,
                border: Border.all(
                  color: _syncMode == 'local' ? _slate800 : Colors.grey.shade200,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: _syncMode == 'local'
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _syncMode == 'local' ? _slate800 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.dns,
                      color:
                          _syncMode == 'local' ? Colors.white : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Only',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _syncMode == 'local'
                                ? _slate800
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data is stored securely on this device only. Works fully offline, but no automatic backups.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      key: const ValueKey(5),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.check_circle,
            Colors.grey.shade600,
            Colors.grey.shade100,
            'Ready to Initialize',
            'Review your settings before creating the database.',
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Business',
                  _storeNameCtrl.text.trim().isEmpty
                      ? 'Not set'
                      : _storeNameCtrl.text.trim(),
                  subtext: _businessType.isEmpty
                      ? null
                      : _businessType.toUpperCase(),
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'Terminal ID',
                  _terminalIdCtrl.text.trim().isEmpty
                      ? 'Not set'
                      : _terminalIdCtrl.text.trim(),
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'Owner Account',
                  _ownerNameCtrl.text.trim().isEmpty
                      ? 'Not set'
                      : _ownerNameCtrl.text.trim(),
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'Storage Mode',
                  _syncMode == 'local' ? 'Local Only' : 'Cloud Sync',
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {String? subtext}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 14,
          ),
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
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _indigo,
                  letterSpacing: 1,
                ),
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

  Widget _buildSuccessScreen() {
    return Container(
      color: _indigo,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 32),
          const Text(
            "You're All Set!",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "ExtroPOS is configured and ready for business.\nLet's make some sales.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.indigo.shade100,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _indigo,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 12,
              shadowColor: Colors.black.withOpacity(0.5),
            ),
            child: const Text(
              'Launch Point of Sale',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _step == 1 ? null : _handleBack,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledForegroundColor: Colors.grey.shade300,
            ),
          ),
          ElevatedButton(
            onPressed: _isNextDisabled() ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _step == _totalSteps ? _emerald : _indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade400,
              elevation: _isNextDisabled() ? 0 : 8,
              shadowColor:
                  (_step == _totalSteps ? _emerald : _indigo).withOpacity(0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _step == _totalSteps ? 'Initialize System' : 'Continue',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_step != _totalSteps) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ]
              ],
            ),
          )
        ],
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
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
