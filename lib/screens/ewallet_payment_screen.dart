import 'dart:async';

import 'package:extropos/services/e_wallet_service.dart';
import 'package:extropos/services/ewallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EWalletPaymentScreen extends StatefulWidget {
  final double amount;
  final String methodName; // e.g., 'E-Wallet' or specific provider
  final String? merchantId;
  final String orderRef; // caller-provided reference

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
  int? _txId;
  String _qrData = '';
  bool _marking = false;
  Timer? _autoSimulateTimer;
  Timer? _pollTimer;
  Timer? _expiryTimer;
  bool _sandbox = true;
  int _remainingSeconds = 300; // 5 minutes default
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    // Load settings to determine sandbox and merchant id
    final settings = await EWalletService.instance.getSettings();
    _sandbox = (settings['use_sandbox'] as bool?) ?? true;

    // Build QR via provider adapter (supports real API or static fallback)
    final qrResult = await EWalletProviderRegistry
        .forSettings(settings)
        .createDynamicQR(
          amount: widget.amount,
          referenceId: widget.orderRef,
          settings: settings,
        );
    
    // Create pending e-wallet transaction record with expiry
    final txId = await EWalletService.instance.createPendingTransaction(
      transactionId: qrResult.transactionId,
      paymentMethod: widget.methodName,
      amount: widget.amount,
      referenceId: widget.orderRef,
      qrExpiresAt: qrResult.expiresAt,
    );
    
    if (!mounted) return;
    setState(() {
      _txId = txId;
      _qrData = qrResult.qrData;
    });

    // Start polling local status every 2s (baseline without gateway callbacks)
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (!mounted || _txId == null) return;
      final status = await EWalletService.instance.getTransactionStatus(id: _txId!);
      if (status == 'success') {
        t.cancel();
        if (!mounted) return;
        Navigator.pop(context, {'success': true, 'reference': widget.orderRef});
      } else if (status == 'failed') {
        t.cancel();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-Wallet payment failed')),
        );
      } else if (status == 'expired') {
        t.cancel();
        if (!mounted) return;
        setState(() => _isExpired = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code expired. Please generate a new one.')),
        );
      }
    });
    
    // Start expiry countdown timer
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _txId == null) return;
      final remaining = await EWalletService.instance.getQRRemainingSeconds(id: _txId!);
      if (remaining <= 0) {
        t.cancel();
        await EWalletService.instance.markExpired(id: _txId!);
        if (!mounted) return;
        setState(() {
          _isExpired = true;
          _remainingSeconds = 0;
        });
      } else {
        if (!mounted) return;
        setState(() => _remainingSeconds = remaining);
      }
    });

    // Optional: Auto-simulate success after 15s in sandbox/demo
    if (_sandbox) {
      _autoSimulateTimer = Timer(const Duration(seconds: 15), () async {
        if (!mounted || _txId == null) return;
        await EWalletService.instance.markSuccess(id: _txId!);
        if (!mounted) return;
        Navigator.pop(context, {'success': true, 'reference': widget.orderRef});
      });
    }
  }

  @override
  void dispose() {
    _autoSimulateTimer?.cancel();
    _pollTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _markAsPaid() async {
    if (_txId == null) return;
    setState(() => _marking = true);
    await EWalletService.instance.markSuccess(id: _txId!);
    if (!mounted) return;
    setState(() => _marking = false);
    Navigator.pop(context, {'success': true, 'reference': widget.orderRef});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Wallet Payment'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_sandbox)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Chip(
                  label: const Text('SANDBOX MODE'),
                  backgroundColor: Colors.amber.shade100,
                  labelStyle: const TextStyle(color: Colors.black87),
                ),
              ),
            Text(
              widget.methodName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'RM ${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            if (_qrData.isEmpty)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 220,
                        gapless: true,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // QR Expiry Countdown
                  if (_isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'QR Code Expired',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_remainingSeconds < 60)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Expires in ${_remainingSeconds}s',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Expires in ${(_remainingSeconds / 60).floor()}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              'Reference: ${widget.orderRef}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _marking
                      ? null
                      : () => Navigator.pop(context, {'success': false}),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: _marking ? null : _markAsPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  icon: _marking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Paid'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
