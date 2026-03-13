import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/vice_display_state.dart';
import 'package:extropos/services/cart_calculation_service.dart';
import 'package:extropos/services/imin_printer_service.dart';
import 'package:extropos/services/payment/duitnow_service.dart';
import 'package:extropos/services/utils/rounding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

/// Service for managing dual display (customer display) functionality
class DualDisplayService {
  static final DualDisplayService _instance = DualDisplayService._internal();
  factory DualDisplayService() => _instance;
  DualDisplayService._internal();

  IminPrinterService? _iminService;
  bool _isSupported = false;
  bool _isEnabled = false;
  bool _showWelcomeMessage = true;
  bool _showOrderTotal = true;
  bool _showPaymentAmount = true;
  bool _showChangeAmount = true;
  bool _showThankYouMessage = true;
  Timer? _keepAliveTimer;
  String _lastDisplayedContent = '';
  final StreamController<ViceDisplayState> _viceStateController =
      StreamController<ViceDisplayState>.broadcast();
  ViceDisplayState _currentViceState = ViceDisplayState.idle();

  String get lastDisplayedContent => _lastDisplayedContent;

  Stream<ViceDisplayState> get viceStateStream => _viceStateController.stream;

  ViceDisplayState get currentViceState => _currentViceState;

  /// Initialize the dual display service
  Future<void> initialize() async {
    await _loadSettings();
    _emitViceState(
      ViceDisplayState.idle(
        businessName: BusinessInfo.instance.businessName,
        currencySymbol: BusinessInfo.instance.currencySymbol,
      ),
    );

    if (!Platform.isAndroid) {
      developer.log(
        'DualDisplay: Running in virtual mode (non-Android, Flutter vice screen only)',
      );
      return;
    }

    try {
      developer.log('DualDisplay: Starting initialization...');
      _iminService = IminPrinterService();
      await _iminService!.initialize();
      _isSupported = await _iminService!.isDualDisplaySupported();
      developer.log('DualDisplay: Hardware support detected: $_isSupported');

      if (_isSupported && _isEnabled) {
        await wakeScreen();
        developer.log('DualDisplay: Screen wake attempted');
        _startKeepAliveTimer();
        developer.log('DualDisplay: Keep-alive timer started');
      }
      if (_isEnabled && _showWelcomeMessage) {
        await showWelcome();
      }
    } catch (e) {
      developer.log('DualDisplay: Initialization failed: $e');
    }
  }

  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('dual_display_enabled') ?? true;
      _showWelcomeMessage = prefs.getBool('dual_display_show_welcome') ?? true;
      _showOrderTotal = prefs.getBool('dual_display_show_total') ?? true;
      _showPaymentAmount = prefs.getBool('dual_display_show_payment') ?? true;
      _showChangeAmount = prefs.getBool('dual_display_show_change') ?? true;
      _showThankYouMessage =
          prefs.getBool('dual_display_show_thank_you') ?? true;
    } catch (e) {
      _isEnabled = true;
    }
  }

  bool get isAvailable => _iminService != null && _isSupported && _isEnabled;

  bool get isSupported => _isSupported;

  bool get isEnabled => _isEnabled;

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dual_display_enabled', enabled);
      developer.log('DualDisplay: Enabled set to $enabled');
    } catch (e) {
      developer.log('DualDisplay: Failed to save enabled state: $e');
    }
  }

  Future<void> showWelcome() async {
    if (!_showWelcomeMessage) return;

    _lastDisplayedContent =
        'Welcome\n${BusinessInfo.instance.businessName.toUpperCase()}';
    _emitViceState(
      ViceDisplayState.idle(
        businessName: BusinessInfo.instance.businessName,
        currencySymbol: BusinessInfo.instance.currencySymbol,
      ),
    );

    if (!isAvailable) return;

    try {
      developer.log('DualDisplay: Vice screen opened for welcome display');
      developer.log(
        'DualDisplay: Last displayed content: $_lastDisplayedContent',
      );
    } catch (e) {
      developer.log('DualDisplay: Failed to open vice screen for welcome: $e');
    }
  }

  Future<void> wakeScreen() async {
    if (!isAvailable) return;
    try {
      await _iminService?.wakeViceScreen();
      developer.log('DualDisplay: Physical vice screen wake requested');
    } catch (e) {
      developer.log('DualDisplay: Failed to wake physical vice screen: $e');
    }
  }

  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      if (!isAvailable || !_isEnabled) {
        timer.cancel();
        return;
      }

      developer.log('DualDisplay: Keep-alive wake attempt');
      await wakeScreen();
    });
  }

  void stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    developer.log('DualDisplay: Keep-alive timer stopped');
  }

  void dispose() {
    stopKeepAlive();
    if (!_viceStateController.isClosed) {
      _viceStateController.close();
    }
  }

  Future<void> _sendStatusUpdate(
    String status, {
    double? amount,
    String? currency,
  }) async {
    if (!isAvailable) return;
    developer.log(
      'DualDisplay: Status update -> $status, amount=$amount, currency=$currency',
    );
  }

  Future<void> showOrderTotal(double total, String currency) async {
    final currencySymbol = _resolveCurrencySymbol(currency);
    final roundedTotal = RoundingService.roundCash(total);

    _lastDisplayedContent =
        'Total Amount\n$currencySymbol${roundedTotal.toStringAsFixed(2)}';

    _emitViceState(
      ViceDisplayState(
        mode: ViceDisplayMode.payment,
        businessName: BusinessInfo.instance.businessName,
        title: 'TOTAL AMOUNT',
        subtitle: 'Scan to pay with DuitNow',
        cartItems: const [],
        subtotal: roundedTotal,
        total: roundedTotal,
        currencySymbol: currencySymbol,
        qrData: _buildDuitNowPayload(roundedTotal),
        reference: null,
        updatedAt: DateTime.now(),
      ),
    );

    if (!isAvailable || !_showOrderTotal) return;

    await _sendStatusUpdate(
      'PAYMENT',
      amount: roundedTotal,
      currency: currencySymbol,
    );
  }

  Future<void> showPaymentAmount(double amount, String currency) async {
    final currencySymbol = _resolveCurrencySymbol(currency);
    final roundedAmount = RoundingService.roundCash(amount);

    _lastDisplayedContent =
        'Payment\n$currencySymbol${roundedAmount.toStringAsFixed(2)}';

    _emitViceState(
      ViceDisplayState(
        mode: ViceDisplayMode.payment,
        businessName: BusinessInfo.instance.businessName,
        title: 'PAYMENT',
        subtitle: 'Please complete your payment',
        cartItems: const [],
        subtotal: roundedAmount,
        total: roundedAmount,
        currencySymbol: currencySymbol,
        qrData: _buildDuitNowPayload(roundedAmount),
        reference: null,
        updatedAt: DateTime.now(),
      ),
    );

    if (!isAvailable || !_showPaymentAmount) return;

    await _sendStatusUpdate(
      'PAYMENT',
      amount: roundedAmount,
      currency: currencySymbol,
    );
  }

  Future<void> showChange(double change, String currency) async {
    if (change <= 0) return;

    final currencySymbol = _resolveCurrencySymbol(currency);
    final roundedChange = RoundingService.roundCash(change);

    _emitViceState(
      ViceDisplayState(
        mode: ViceDisplayMode.change,
        businessName: BusinessInfo.instance.businessName,
        title: 'CHANGE',
        subtitle: 'Please collect your balance',
        cartItems: const [],
        subtotal: roundedChange,
        total: roundedChange,
        currencySymbol: currencySymbol,
        qrData: '',
        reference: null,
        updatedAt: DateTime.now(),
      ),
    );

    if (!isAvailable || !_showChangeAmount) return;
    _lastDisplayedContent =
        'Change\n$currencySymbol${roundedChange.toStringAsFixed(2)}';

    await _sendStatusUpdate(
      'CHANGE',
      amount: roundedChange,
      currency: currencySymbol,
    );
  }

  Future<void> showThankYou() async {
    _lastDisplayedContent = 'Thank You!\nPlease Come Again';

    _emitViceState(
      ViceDisplayState(
        mode: ViceDisplayMode.thankYou,
        businessName: BusinessInfo.instance.businessName,
        title: 'THANK YOU',
        subtitle: 'Please come again',
        cartItems: const [],
        subtotal: 0.0,
        total: 0.0,
        currencySymbol: BusinessInfo.instance.currencySymbol,
        qrData: '',
        reference: null,
        updatedAt: DateTime.now(),
      ),
    );

    if (!isAvailable || !_showThankYouMessage) return;

    await _sendStatusUpdate('THANK_YOU');
  }

  Future<void> clear() async {
    _emitViceState(
      ViceDisplayState.idle(
        businessName: BusinessInfo.instance.businessName,
        currencySymbol: BusinessInfo.instance.currencySymbol,
      ),
    );

    if (!isAvailable) return;

    await _sendStatusUpdate('IDLE');
  }

  Future<void> showText(String text) async {
    if (!isAvailable) return;
    developer.log('DualDisplay: showText requested -> $text');
  }

  Future<void> showCartItems(
    List<Map<String, dynamic>> items,
    double subtotal,
    String currency, {
    String? orderNumber,
    double? total,
  }) async {
    developer.log(
      'DualDisplay: showCartItems called - items: ${items.length}, subtotal: $subtotal, currency: $currency',
    );

    final currencySymbol = _resolveCurrencySymbol(currency);
    final roundedTotal = RoundingService.roundCash(total ?? subtotal);
    final qrData = roundedTotal > 0
        ? _buildDuitNowPayload(roundedTotal, reference: orderNumber)
        : '';

    _emitViceState(
      items.isEmpty
          ? ViceDisplayState.idle(
              businessName: BusinessInfo.instance.businessName,
              currencySymbol: currencySymbol,
            )
          : ViceDisplayState(
              mode: ViceDisplayMode.cart,
              businessName: BusinessInfo.instance.businessName,
              title: 'SCAN TO PAY',
              subtitle: 'DuitNow QR',
              cartItems: items,
              subtotal: subtotal,
              total: roundedTotal,
              currencySymbol: currencySymbol,
              qrData: qrData,
              reference: orderNumber,
              updatedAt: DateTime.now(),
            ),
    );

    if (!isAvailable) {
      developer.log(
        'DualDisplay: Physical display unavailable; Flutter vice stream updated only',
      );
      return;
    }

    await _sendStatusUpdate(
      'CART',
      amount: roundedTotal,
      currency: currencySymbol,
    );
  }

  Future<void> showCartItemsFromObjects(
    List<CartItem> cartItems,
    String currency, {
    String? orderNumber,
  }) async {
    final items = cartItems.map((item) => item.toJson()).toList();
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final total = CartCalculationService.calculateTotal(
      cartItems,
      BusinessInfo.instance,
      cashPayment: true,
    );
    await showCartItems(
      items,
      subtotal,
      currency,
      orderNumber: orderNumber,
      total: total,
    );
  }

  Future<void> showItemAdded(
    String itemName,
    int quantity,
    double price,
    String currency,
  ) async {
    final currencySymbol = _resolveCurrencySymbol(currency);
    final roundedPrice = RoundingService.roundCash(price);

    final displayName = itemName.length > 20
        ? '${itemName.substring(0, 17)}...'
        : itemName;
    final text =
        'Added to cart:\n\n$quantity x $displayName\n$currencySymbol${roundedPrice.toStringAsFixed(2)}';

    _lastDisplayedContent = text;
    _emitViceState(
      ViceDisplayState(
        mode: ViceDisplayMode.message,
        businessName: BusinessInfo.instance.businessName,
        title: 'ITEM ADDED',
        subtitle: text,
        cartItems: const [],
        subtotal: roundedPrice,
        total: roundedPrice,
        currencySymbol: currencySymbol,
        qrData: '',
        reference: null,
        updatedAt: DateTime.now(),
      ),
    );

    if (!isAvailable) return;

  }

  String _resolveCurrencySymbol(String currency) {
    return currency.isEmpty ? BusinessInfo.instance.currencySymbol : currency;
  }

  void _emitViceState(ViceDisplayState state) {
    _currentViceState = state;
    if (!_viceStateController.isClosed) {
      _viceStateController.add(state);
    }
  }

  String _resolveMerchantId() {
    final info = BusinessInfo.instance;
    final candidates = [
      info.taxNumber,
      info.registrationNumber,
      info.phone,
      info.email,
    ];
    for (final candidate in candidates) {
      final value = (candidate ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return 'EXTROPOS';
  }

  String _buildDuitNowPayload(double total, {String? reference}) {
    try {
      return DuitNowService.generateDynamicQr(
        merchantId: _resolveMerchantId(),
        amount: total,
        reference: reference,
        merchantName: BusinessInfo.instance.businessName,
        merchantCity: BusinessInfo.instance.city,
      );
    } catch (e) {
      developer.log('DualDisplay: Failed to build DuitNow payload: $e');
      return '';
    }
  }
}
