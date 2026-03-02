import 'package:flutter/material.dart';

class AmountInputWidget extends StatelessWidget {
  final TextEditingController amountController;
  final String currencySymbol;
  final String label;
  final String? hintText;
  final bool readOnly;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const AmountInputWidget({
    super.key,
    required this.amountController,
    required this.currencySymbol,
    this.label = 'Amount',
    this.hintText,
    this.readOnly = false,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              readOnly: readOnly,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    currencySymbol,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                hintText: hintText ?? '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (validator != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Builder(
                  builder: (context) {
                    final error = validator!(amountController.text);
                    if (error != null) {
                      return Text(
                        error,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
