import 'dart:async';
import 'package:extropos/services/e_wallet_service.dart';
import 'package:extropos/services/payment/payment_gateway.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Screen for processing e-wallet payments (Boost, GrabPay, TNG)
class EWalletPaymentScreen extends StatefulWidget {
  final double amount;
  final String methodName;
  final String orderRef;
  final String? merchantId;

  const EWalletPaymentScreen({
    super.key,
    required this.amount,
    required this.methodName,
    required this.orderRef,
    this.merchantId,
  });

  @override
  State<EWalletPaymentScreen> createState() => _EWalletPaymentScreenState();
}

class _EWalletPaymentScreenState extends State<EWalletPaymentScreen> {
  bool _isLoading = true;
  String? _qrData;
  String? _paymentId;
  Timer? _statusTimer;
  int _secondsRemaining = 300; // 5 minutes timeout
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() => _isLoading = true);

    try {
      final result = await EWalletService.instance.generatePaymentQR(
        amount: widget.amount,
        methodName: widget.methodName,
        orderRef: widget.orderRef,
      );

      if (result != null) {
        setState(() {
          _qrData = result['qr_data'];
          _paymentId = result['payment_id'];
          _isLoading = false;
        });
        _startPolling();
      } else {
        if (mounted) {
          ToastHelper.showToast(context, 'Failed to generate QR code');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error: $e');
        Navigator.pop(context);
      }
    }
  }

  void _startPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() => _isExpired = true);
        return;
      }

      setState(() => _secondsRemaining -= 3);

      if (_paymentId != null) {
        final paymentStatus = await EWalletService.instance.checkPaymentStatus(_paymentId!);
        if (paymentStatus.status == PaymentStatusEnum.success) {
          timer.cancel();
          if (mounted) {
            ToastHelper.showToast(context, 'Payment Successful!');
            Navigator.pop(context, {'success': true, 'paymentId': _paymentId});
          }
        } else if (paymentStatus.status == PaymentStatusEnum.failed) {
          timer.cancel();
          if (mounted) {
            ToastHelper.showToast(context, 'Payment Failed');
            Navigator.pop(context, {'success': false});
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.methodName} Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmCancel(),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Amount: RM ${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_qrData != null && !_isExpired)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrData!,
                          version: QrVersions.auto,
                          size: 250.0,
                        ),
                      )
                    else if (_isExpired)
                      const Icon(Icons.error_outline, size: 100, color: Colors.red),
                    
                    const SizedBox(height: 32),
                    if (!_isExpired) ...[
                      const Text(
                        'Please scan the QR code to pay',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Expires in: ${_formatTime(_secondsRemaining)}',
                        style: TextStyle(
                          color: _secondsRemaining < 60 ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'QR Code Expired',
                        style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _generateQR,
                        child: const Text('Regenerate QR'),
                      ),
                    ],
                    const SizedBox(height: 48),
                    OutlinedButton(
                      onPressed: () => _checkStatusManually(),
                      child: const Text('I have paid (Manual Check)'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _checkStatusManually() async {
    if (_paymentId == null) return;
    
    setState(() => _isLoading = true);
    final paymentStatus = await EWalletService.instance.checkPaymentStatus(_paymentId!);
    setState(() => _isLoading = false);

    if (paymentStatus.status == PaymentStatusEnum.success) {
      if (mounted) {
        ToastHelper.showToast(context, 'Payment Successful!');
        Navigator.pop(context, {'success': true, 'paymentId': _paymentId});
      }
    } else {
      if (mounted) {
        ToastHelper.showToast(context, 'Payment not yet received');
      }
    }
  }

  void _confirmCancel() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to cancel this e-wallet payment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, {'success': false, 'canceled': true});
    }
  }
}
