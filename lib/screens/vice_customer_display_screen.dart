import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:flutter/material.dart';
// import 'package:imin_vice_screen/imin_vice_screen.dart';  // DISABLED - Incompatible with Android SDK 36
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

part 'vice_customer_display_screen_ui.dart';

enum ViceDisplayMode { cart, payment, change, thankYou, idle }

/// Dedicated screen for the vice (back) display
/// This widget runs when the app is launched on the secondary screen
/// and displays customer-facing information like cart items, totals, etc.
class ViceCustomerDisplayScreen extends StatefulWidget {
  const ViceCustomerDisplayScreen({super.key});

  @override
  State<ViceCustomerDisplayScreen> createState() =>
      _ViceCustomerDisplayScreenState();
}

class _ViceCustomerDisplayScreenState extends State<ViceCustomerDisplayScreen> {
  // final IminViceScreen _viceScreenPlugin = IminViceScreen();  // DISABLED - Incompatible with Android SDK 36
  final List<CartItem> _cartItems = [];
  final double _subtotal = 0.0;
  String? _orderNumber;
  String _currency = 'RM';
  // String? _promoUrl; // Unused in current layout, kept for future promotional features
  Timer? _welcomeTimer;
  // Slideshow state
  bool _slideshowEnabled = false;
  List<String> _slideshowImages = [];
  int _currentSlideshowIndex = 0;
  Timer? _slideshowTimer;

  // New state for display modes
  ViceDisplayMode _displayMode = ViceDisplayMode.idle;
  double _paymentAmount = 0.0;
  double _changeAmount = 0.0;
  
  // QR code data
  String _qrData = '';
  
  // Animation controllers
  final bool _showCartAnimation = false;

  @override
  void initState() {
    super.initState();
    // TEMPORARILY DISABLED: YouTube playback (will re-implement after cart updates are stable)
    // _loadYouTubeSettings();
    _showWelcome();

    // DISABLED - imin_vice_screen incompatible with Android SDK 36
    /* ORIGINAL CODE - Listen to cart updates:
      try {
        developer.log('Vice: Received stream event: $event');
        ... (full original listener code) ...
      } catch (e) {
        developer.log('Vice: Error handling stream event: $e');
      }
    });
    END ORIGINAL CODE */

    // Rotate welcome message every 5 seconds (when cart is empty)
    _welcomeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _cartItems.isEmpty) {
        _showWelcome();
      }
    });

    // Load promo URL from SharedPreferences if set; otherwise use BusinessInfo.logo
    // _loadPromoUrl(); // Commented out - not used in current 70/30 split layout
    _loadSlideshowSettings();
  }

  void _handleStatusUpdate(dynamic arguments) {
    try {
      developer.log('Vice: Handling status update with args: $arguments');
      // Handle both direct Map and JSON string
      final Map<String, dynamic> data = (arguments is String)
          ? jsonDecode(arguments)
          : (arguments is Map ? Map<String, dynamic>.from(arguments) : {});

      final String status = data['status']?.toString() ?? 'IDLE';
      developer.log('Vice: Status update -> $status');

      setState(() {
        switch (status) {
          case 'PAYMENT':
            _displayMode = ViceDisplayMode.payment;
            _paymentAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            _currency = data['currency']?.toString() ?? _currency;
            break;
          case 'CHANGE':
            _displayMode = ViceDisplayMode.change;
            _changeAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            _currency = data['currency']?.toString() ?? _currency;
            break;
          case 'THANK_YOU':
            _displayMode = ViceDisplayMode.thankYou;
            break;
          case 'IDLE':
          default:
            _displayMode = _cartItems.isNotEmpty
                ? ViceDisplayMode.cart
                : ViceDisplayMode.idle;
            break;
        }
      });
    } catch (e) {
      developer.log('Vice: Error handling status update: $e');
    }
  }

  Future<void> _loadSlideshowSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('vice_slideshow_enabled') ?? false;
      final images = prefs.getStringList('vice_slideshow_images') ?? [];

      setState(() {
        _slideshowEnabled = enabled;
        _slideshowImages = images;
      });

      // Start slideshow if enabled and no cart items
      if (_slideshowEnabled &&
          _slideshowImages.isNotEmpty &&
          _cartItems.isEmpty) {
        _startSlideshow();
      }
    } catch (e) {
      // ignore
    }
  }

  void _startSlideshow() {
    _slideshowTimer?.cancel();
    if (_slideshowImages.isNotEmpty) {
      _slideshowTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted && _cartItems.isEmpty && _slideshowEnabled) {
          setState(() {
            _currentSlideshowIndex =
                (_currentSlideshowIndex + 1) % _slideshowImages.length;
          });
        }
      });
    }
  }

  void _stopSlideshow() {
    _slideshowTimer?.cancel();
    _slideshowTimer = null;
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    _slideshowTimer?.cancel();
    super.dispose();
  }
  void _showWelcome() {
    // Welcome display logic - currently not used in center panel
    // but kept for future reference and welcome animations
  }

  // Commented out - promotional URL loading not used in current 70/30 split layout
  // Future<void> _loadPromoUrl() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final url = prefs.getString('vice_promo_image_url');
  //     if (url != null && url.isNotEmpty) {
  //       setState(() {
  //         _promoUrl = url;
  //       });
  //     } else if (BusinessInfo.instance.logo != null &&
  //         BusinessInfo.instance.logo!.isNotEmpty) {
  //       setState(() => _promoUrl = BusinessInfo.instance.logo);
  //     }
  //   } catch (e) {
  //     // ignore
  //     if (BusinessInfo.instance.logo != null) {
  //       setState(() => _promoUrl = BusinessInfo.instance.logo);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Log render state
    developer.log(
      'Vice: build() - cart: ${_cartItems.length} items, mode: $_displayMode',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50), // Dark navy background matching reference
      body: Stack(
        children: [
          // Background topographic pattern
          Positioned.fill(
            child: CustomPaint(painter: TopographicPatternPainter()),
          ),
          // Modern 3-column layout
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Order Summary Section (Left) - 30%
                Expanded(flex: 3, child: buildModernOrderSummary()),
                const SizedBox(width: 24),
                // Featured Item Section (Center) - 40%
                Expanded(flex: 4, child: buildModernFeaturedProduct()),
                const SizedBox(width: 24),
                // Status/Rewards Section (Right) - 30%
                Expanded(flex: 3, child: buildModernStatusCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Topographic Pattern Painter for Background
class TopographicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF1E2D3F).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw organic wavy lines with varied amplitudes
    for (int i = 0; i < 20; i++) {
      final path = Path();
      final baseY = size.height * (i / 20);
      path.moveTo(0, baseY);

      for (double x = 0; x <= size.width; x += 15) {
        final phase1 = (x / 100) * 3.14159 * 2;
        final phase2 = ((x + i * 50) / 150) * 3.14159 * 2;
        final amplitude = 8 + (i % 3) * 4;
        final y = baseY + amplitude * (math.sin(phase1) * 0.6 + math.sin(phase2) * 0.4);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    // Draw second layer with phase offset for depth
    paint.color = const Color(0xFF1E2D3F).withOpacity(0.25);
    paint.strokeWidth = 1.0;
    for (int i = 0; i < 15; i++) {
      final path = Path();
      final baseX = size.width * (i / 15);
      path.moveTo(baseX, 0);

      for (double y = 0; y <= size.height; y += 15) {
        final phase1 = (y / 80) * 3.14159 * 2 + 1.5;
        final phase2 = ((y + i * 40) / 120) * 3.14159 * 2;
        final amplitude = 6 + (i % 2) * 3;
        final x = baseX + amplitude * (math.sin(phase1) * 0.5 + math.sin(phase2) * 0.5);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
