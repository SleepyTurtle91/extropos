import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/services/imin_printer_service.dart';
// import 'package:imin_vice_screen/imin_vice_screen.dart';  // DISABLED - Incompatible with Android SDK 36
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

/// Service for managing dual display (customer display) functionality
class DualDisplayService {
  static final DualDisplayService _instance = DualDisplayService._internal();
  factory DualDisplayService() => _instance;
  DualDisplayService._internal();

  IminPrinterService? _iminService;
  // final IminViceScreen _viceScreenPlugin = IminViceScreen();  // DISABLED
  bool _isSupported = false;  // Always false when imin_vice_screen is disabled
  bool _isEnabled = false;
  bool _showWelcomeMessage = true;
  bool _showOrderTotal = true;
  bool _showPaymentAmount = true;
  bool _showChangeAmount = true;
  bool _showThankYouMessage = true;
  Timer? _keepAliveTimer;
  String _lastDisplayedContent = '';

  /// Last content displayed on vice screen (useful for tests/debugging)
  String get lastDisplayedContent => _lastDisplayedContent;

  /// Initialize the dual display service
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      developer.log('DualDisplay: Skipping initialization (not Android)');
      return;
    }

    try {
      developer.log('DualDisplay: Starting initialization...');
      _iminService = IminPrinterService();
      await _iminService!.initialize();
      // _isSupported = _iminService!.hasViceScreen;  // DISABLED
      _isSupported = false;  // Always false when imin_vice_screen is disabled
      developer.log('DualDisplay: Hardware support detected: $_isSupported');

      if (_isSupported) {
        await _loadSettings();
        developer.log('DualDisplay: Enabled: $_isEnabled');

        // Wake up the screen first (unlock if locked)
        if (_isEnabled) {
          await wakeScreen();
          developer.log('DualDisplay: Screen wake attempted');

          // Start keep-alive timer to prevent screen from locking
          _startKeepAliveTimer();
          developer.log('DualDisplay: Keep-alive timer started');
        }

        // Show welcome message if enabled
        if (_isEnabled && _showWelcomeMessage) {
          await showWelcome();
        }
      }
    } catch (e) {
      developer.log('DualDisplay: Initialization failed: $e');
    }
  }

  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Enable by default if dual display hardware is detected
      _isEnabled = prefs.getBool('dual_display_enabled') ?? true;
      _showWelcomeMessage = prefs.getBool('dual_display_show_welcome') ?? true;
      _showOrderTotal = prefs.getBool('dual_display_show_total') ?? true;
      _showPaymentAmount = prefs.getBool('dual_display_show_payment') ?? true;
      _showChangeAmount = prefs.getBool('dual_display_show_change') ?? true;
      _showThankYouMessage =
          prefs.getBool('dual_display_show_thank_you') ?? true;
    } catch (e) {
      // Use defaults - enable if hardware detected
      _isEnabled = true;
    }
  }

  /// Check if dual display is available and enabled
  bool get isAvailable => _iminService != null && _isSupported && _isEnabled;

  /// Check if dual display hardware is supported
  bool get isSupported => _isSupported;

  /// Check if dual display is enabled
  bool get isEnabled => _isEnabled;

  /// Enable or disable dual display
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

  /// Show welcome message on customer display
  Future<void> showWelcome() async {
    if (!isAvailable || !_showWelcomeMessage) return;

    try {
      developer.log('DualDisplay: Vice screen opened for welcome display');
      developer.log(
        'DualDisplay: Last displayed content: $_lastDisplayedContent',
      );

      // The ViceCustomerDisplayScreen will show the welcome message by default
      // (when cart is empty)

      // The ViceCustomerDisplayScreen will show the welcome message by default
      // (when cart is empty)
    } catch (e) {
      developer.log('DualDisplay: Failed to open vice screen for welcome: $e');
    }
  }

  /// Wake up the customer display screen (unlock if locked)
  Future<void> wakeScreen() async {
    if (!isAvailable) return;
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    /* ORIGINAL CODE:
    try {
      developer.log('DualDisplay: Attempting to wake screen (Flutter Mode)...');
      await _viceScreenPlugin.doubleScreenOpen();
      developer.log('DualDisplay: Screen wake successful (Flutter Mode)');
    } catch (e) {
      developer.log('DualDisplay: Failed to wake screen: $e');
    }
    */
  }

  /// Start periodic keep-alive timer to prevent screen lock
  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();

    // Wake screen every 30 seconds to prevent lock screen
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

  /// Stop keep-alive timer
  void stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    developer.log('DualDisplay: Keep-alive timer stopped');
  }

  /// Dispose resources
  void dispose() {
    stopKeepAlive();
  }

  /// Send status update to vice screen
  Future<void> _sendStatusUpdate(
    String status, {
    double? amount,
    String? currency,
  }) async {
    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    /* ORIGINAL CODE:
    try {
      await _viceScreenPlugin.doubleScreenOpen();
      final data = {
        'status': status,
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
      };
      await _viceScreenPlugin.sendMsgToViceScreen('UPDATE_STATUS', params: data);
    } catch (e) {
      developer.log('DualDisplay: Failed to send status update: $e');
    }
    */
  }

  /// Show order total on customer display
  Future<void> showOrderTotal(double total, String currency) async {
    if (!isAvailable || !_showOrderTotal) return;
    final currencySymbol = (currency.isEmpty)
        ? BusinessInfo.instance.currencySymbol
        : currency;
    _lastDisplayedContent =
        'Total Amount\n$currencySymbol${total.toStringAsFixed(2)}';

    // Use Flutter display instead of LCD
    await _sendStatusUpdate('PAYMENT', amount: total, currency: currencySymbol);
  }

  /// Show payment amount on customer display
  Future<void> showPaymentAmount(double amount, String currency) async {
    if (!isAvailable || !_showPaymentAmount) return;
    final currencySymbol = (currency.isEmpty)
        ? BusinessInfo.instance.currencySymbol
        : currency;
    _lastDisplayedContent =
        'Payment\n$currencySymbol${amount.toStringAsFixed(2)}';

    // Use Flutter display instead of LCD
    await _sendStatusUpdate(
      'PAYMENT',
      amount: amount,
      currency: currencySymbol,
    );
  }

  /// Show change amount on customer display
  Future<void> showChange(double change, String currency) async {
    if (!isAvailable || !_showChangeAmount) return;
    if (change <= 0) return;
    final currencySymbol = (currency.isEmpty)
        ? BusinessInfo.instance.currencySymbol
        : currency;
    _lastDisplayedContent =
        'Change\n$currencySymbol${change.toStringAsFixed(2)}';

    // Use Flutter display instead of LCD
    await _sendStatusUpdate('CHANGE', amount: change, currency: currencySymbol);
  }

  /// Show thank you message on customer display
  Future<void> showThankYou() async {
    if (!isAvailable || !_showThankYouMessage) return;

    _lastDisplayedContent = 'Thank You!\nPlease Come Again';

    // Use Flutter display instead of LCD
    await _sendStatusUpdate('THANK_YOU');
  }

  /// Clear the customer display
  Future<void> clear() async {
    if (!isAvailable) return;

    // Reset to IDLE (Welcome screen or empty cart)
    await _sendStatusUpdate('IDLE');
  }

  /// Show custom text on customer display
  Future<void> showText(String text) async {
    if (!isAvailable) return;

    // For custom text, we might still need LCD if the Flutter UI doesn't support it
    // But for consistency, we'll try to keep the Flutter UI active
    // Currently ignoring custom text for Flutter UI to prevent context switching
    // await _iminService!.displayOnViceScreen(text);
  }

  /// Show cart items on customer display using stream-based communication
  Future<void> showCartItems(
    List<Map<String, dynamic>> items,
    double subtotal,
    String currency, {
    String? orderNumber,
  }) async {
    developer.log(
      'DualDisplay: showCartItems called - items: ${items.length}, subtotal: $subtotal, currency: $currency',
    );

    if (!isAvailable) {
      developer.log(
        'DualDisplay: ERROR - Not available (isAvailable = false), skipping cart display',
      );
      developer.log(
        'DualDisplay: Check Settings > Dual Display Settings is enabled',
      );
      return;
    }

    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    /* ORIGINAL CODE:
    try {
      developer.log('DualDisplay: Opening vice screen...');
      await _viceScreenPlugin.doubleScreenOpen();
      developer.log('DualDisplay: Vice screen opened successfully');

      // Send cart data via vice screen stream
      final cartData = {
        'items': items,
        'subtotal': subtotal,
        'currency': currency.isEmpty
            ? BusinessInfo.instance.currencySymbol
            : currency,
        if (orderNumber != null) 'orderNumber': orderNumber,
      };
      developer.log(
        'DualDisplay: Prepared cart data with ${items.length} items',
      );

      final encodedData = jsonEncode(cartData);
      developer.log(
        'DualDisplay: JSON encoded cart data (${encodedData.length} chars)',
      );

      await _viceScreenPlugin.sendMsgToViceScreen(
        'CART_UPDATE',
        params: {'cartData': encodedData},
      );

      developer.log('DualDisplay: Cart data sent via stream successfully');
    } catch (e, stackTrace) {
      developer.log('DualDisplay: ERROR - Failed to send cart data: $e');
      developer.log('DualDisplay: Stack trace: $stackTrace');
    }
    */
  }

  /// Show cart items from CartItem objects (convenience method)
  Future<void> showCartItemsFromObjects(
    List<CartItem> cartItems,
    String currency, {
    String? orderNumber,
  }) async {
    final items = cartItems.map((item) => item.toJson()).toList();
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    await showCartItems(items, subtotal, currency, orderNumber: orderNumber);
  }

  /// Show single item added to cart
  Future<void> showItemAdded(
    String itemName,
    int quantity,
    double price,
    String currency,
  ) async {
    if (!isAvailable) return;

    final currencySymbol = (currency.isEmpty)
        ? BusinessInfo.instance.currencySymbol
        : currency;

    final displayName = itemName.length > 20
        ? '\${itemName.substring(0, 17)}...'
        : itemName;
    final text =
        'Added to cart:\n\n$quantity x $displayName\n$currencySymbol\${price.toStringAsFixed(2)}';

    _lastDisplayedContent = text;
    // await _iminService!.displayOnViceScreen(text);  // DISABLED - imin_vice_screen incompatible
  }
}
