part of 'sales_history_screen.dart';

/// Extension containing filter UI section
extension SalesHistoryFilters on _SalesHistoryScreenState {
  /// Build filter section with date range and payment method
  Widget buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _from ??
                      DateTime.now().subtract(
                        const Duration(days: 7),
                      ),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null && mounted) {
                  setState(() => _from = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _from == null
                      ? 'Any'
                      : _from!.toIso8601String().split('T').first,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _to ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null && mounted) {
                  setState(() => _to = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _to == null
                      ? 'Any'
                      : _to!.toIso8601String().split('T').first,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _selectedPaymentMethodId,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All'),
                ),
                ..._paymentMethods.map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name),
                  ),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _selectedPaymentMethodId = v),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => loadOrders(page: 0),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
