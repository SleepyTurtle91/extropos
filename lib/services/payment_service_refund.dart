part of 'payment_service.dart';

extension PaymentServiceRefund on PaymentService {
  /// Process a refund for a completed order
  Future<PaymentResult> processRefund({
    required String orderId,
    required double refundAmount,
    required PaymentMethod paymentMethod,
    String? reason,
    String? userId,
  }) async {
    try {
      if (refundAmount <= 0) {
        return PaymentResult.failure(
          errorMessage: 'Refund amount must be greater than zero',
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
          amountPaid: refundAmount,
        );
      }

      if (TrainingModeService.instance.isTrainingMode) {
        developer.log('TRAINING MODE: Refund processed (no database update)');

        return PaymentResult.success(
          transactionId:
              'TRAIN-REFUND-${DateTime.now().millisecondsSinceEpoch}',
          receiptNumber:
              'TRAIN-REFUND-${DateTime.now().millisecondsSinceEpoch}',
          amountPaid: refundAmount,
          change: 0.0,
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
        );
      }

      final success = await DatabaseService.instance.refundOrder(
        orderId: orderId,
        refundAmount: refundAmount,
        paymentMethodId: paymentMethod.id,
        reason: reason,
        userId: userId,
      );

      if (!success) {
        return PaymentResult.failure(
          errorMessage: 'Failed to process refund in database',
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
          amountPaid: refundAmount,
        );
      }

      final receiptNumber = 'REFUND-${DateTime.now().millisecondsSinceEpoch}';

      developer.log('Refund processed successfully: $receiptNumber');

      return PaymentResult.success(
        transactionId: orderId,
        receiptNumber: receiptNumber,
        amountPaid: refundAmount,
        change: 0.0,
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
      );
    } catch (e) {
      developer.log('Error processing refund: $e');
      return PaymentResult.failure(
        errorMessage: 'Refund processing failed: ${e.toString()}',
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
        amountPaid: refundAmount,
      );
    }
  }
}
