import 'dart:async';

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/vice_display_state.dart';
import 'package:extropos/services/cart_calculation_service.dart';
import 'package:extropos/services/cart_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/payment/duitnow_service.dart';
import 'package:extropos/widgets/display/vice_customer_qr.dart';
import 'package:flutter/material.dart';

/// Layer C screen: orchestrates customer-facing vice display updates.
///
/// It listens to [DualDisplayService.viceStateStream] and renders a minimal,
/// retail-fast customer view focused on total + DuitNow QR.
class ViceDisplayScreen extends StatefulWidget {
  const ViceDisplayScreen({super.key});

  @override
  State<ViceDisplayScreen> createState() => _ViceDisplayScreenState();
}

class _ViceDisplayScreenState extends State<ViceDisplayScreen> {
  late ViceDisplayState _state;
  StreamSubscription<ViceDisplayState>? _subscription;

  @override
  void initState() {
    super.initState();
    _state = DualDisplayService().currentViceState;

    // Primary source: orchestrated vice stream from DualDisplayService.
    _subscription = DualDisplayService().viceStateStream.listen((nextState) {
      if (!mounted) return;
      setState(() => _state = nextState);
    });

    // Fallback source: direct cart observer.
    // This keeps the vice screen responsive in flows that update CartService
    // directly without calling DualDisplayService.
    CartService.instance.addListener(_handleCartChanged);
    _handleCartChanged();
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_handleCartChanged);
    _subscription?.cancel();
    super.dispose();
  }

  void _handleCartChanged() {
    final cartItems = CartService.instance.items;
    final info = BusinessInfo.instance;

    if (cartItems.isEmpty) {
      if (!mounted) return;
      setState(() {
        _state = ViceDisplayState.idle(
          businessName: info.businessName,
          currencySymbol: info.currencySymbol,
        );
      });
      return;
    }

    final subtotal = CartService.instance.getSubtotal();
    final total = CartCalculationService.calculateTotal(
      cartItems,
      info,
      cashPayment: true,
    );

    String qrData = '';
    try {
      qrData = DuitNowService.generateDynamicQr(
        merchantId: _resolveMerchantId(info),
        amount: total,
        merchantName: info.businessName,
        merchantCity: info.city,
      );
    } catch (_) {
      qrData = '';
    }

    if (!mounted) return;
    setState(() {
      _state = ViceDisplayState(
        mode: ViceDisplayMode.cart,
        businessName: info.businessName,
        title: 'SCAN TO PAY',
        subtitle: 'DuitNow QR',
        cartItems: cartItems.map((item) => item.toJson()).toList(),
        subtotal: subtotal,
        total: total,
        currencySymbol: info.currencySymbol,
        qrData: qrData,
        reference: null,
        updatedAt: DateTime.now(),
      );
    });
  }

  String _resolveMerchantId(BusinessInfo info) {
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

  @override
  Widget build(BuildContext context) {
    final shouldShowQr = _state.hasQr && _state.hasAmount;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: shouldShowQr
                ? _buildQrView(context)
                : _buildIdleView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _state.businessName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _state.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _state.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildQrView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _state.businessName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ViceCustomerQR(
            qrData: _state.qrData,
            totalAmount: _state.total,
            currencySymbol: _state.currencySymbol,
            title: _state.title,
            subtitle: _state.subtitle,
            reference: _state.reference,
          ),
        ),
      ],
    );
  }
}
