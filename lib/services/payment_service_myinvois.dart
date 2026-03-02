part of 'payment_service.dart';

extension PaymentServiceMyInvois on PaymentService {
  /// Submit transaction to MyInvois if enabled and production guard passes
  Future<void> _submitToMyInvoisIfEnabled({
    required String receiptNumber,
    required List<CartItem> cartItems,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required String paymentMethod,
  }) async {
    try {
      final info = BusinessInfo.instance;

      if (!info.isMyInvoisEnabled) {
        developer.log('MyInvois: Disabled, skipping submission');
        return;
      }

      if (TrainingModeService.instance.isTrainingMode) {
        developer.log('MyInvois: Training mode, skipping submission');
        return;
      }

      if (!info.useMyInvoisSandbox) {
        final testSuccess = info.myInvoisLastTestSuccess == true;
        final testTime = info.myInvoisLastTestedAt;
        final guardHours = info.myInvoisProductionGuardHours;

        if (!testSuccess || testTime == null) {
          developer.log(
            '⚠️ MyInvois: Production blocked - no successful test recorded',
          );
          return;
        }

        final testDate = DateTime.fromMillisecondsSinceEpoch(testTime);
        final hoursSinceTest = DateTime.now().difference(testDate).inHours;

        if (hoursSinceTest >= guardHours) {
          developer.log(
            '⚠️ MyInvois: Production blocked - test is $hoursSinceTest hours old (guard: $guardHours hours)',
          );
          return;
        }
      }

      final transactionData = {
        'receiptNumber': receiptNumber,
        'items': cartItems
            .map((item) => {
                  'name': item.product.name,
                  'quantity': item.quantity,
                  'unitPrice': item.product.price,
                  'total': item.totalPrice,
                })
            .toList(),
        'subtotal': subtotal,
        'taxAmount': tax,
        'serviceChargeAmount': serviceCharge,
        'totalAmount': total,
        'paymentMethod': paymentMethod,
      };

      final service = MyInvoiceService(
        useSandboxOverride: info.useMyInvoisSandbox,
      );
      final documentUUID = await service.submitInvoice(transactionData);

      if (documentUUID != null) {
        developer.log(
          '✅ MyInvois: Invoice submitted successfully [${info.useMyInvoisSandbox ? 'sandbox' : 'production'}] - UUID: $documentUUID',
        );
      } else {
        developer.log(
          '⚠️ MyInvois: Invoice submission failed, queued for manual retry',
        );
      }
    } catch (e) {
      developer.log('❌ MyInvois: Submission error - $e');
    }
  }
}
