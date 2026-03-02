import 'package:extropos/models/payment_models.dart';
import 'package:flutter/material.dart';

class PaymentMethodSelectorWidget extends StatelessWidget {
  final List<PaymentMethod> availablePaymentMethods;
  final PaymentMethod? selectedPaymentMethod;
  final Function(PaymentMethod) onPaymentMethodChanged;

  const PaymentMethodSelectorWidget({
    super.key,
    required this.availablePaymentMethods,
    this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (availablePaymentMethods.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No payment methods available',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              Wrap(
                spacing: isNarrow ? 8 : 12,
                runSpacing: 8,
                children: availablePaymentMethods
                    .where((m) => m.status == PaymentMethodStatus.active)
                    .map((method) {
                  final isSelected = selectedPaymentMethod?.id == method.id;
                  return ChoiceChip(
                    label: Text(method.name),
                    selected: isSelected,
                    onSelected: (_) {
                      if (!isSelected) {
                        onPaymentMethodChanged(method);
                      }
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
