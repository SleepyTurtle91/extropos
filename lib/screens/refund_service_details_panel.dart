part of 'refund_service_screen.dart';

/// Extension containing refund details panel UI
extension RefundServiceDetailsPanel on _RefundServiceScreenState {
  /// Build main refund details panel
  Widget buildDetailsPanel() {
    final tx = _selectedTransaction!;
    final isFormValid = _refundItems.isNotEmpty && _refundReason.isNotEmpty && _refundMethod.isNotEmpty;

    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.slate200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderCol('RECEIPT ID', tx.id, isLarge: true),
              _buildHeaderCol('CUSTOMER', tx.customer),
              _buildHeaderCol('ORIGINAL TOTAL', 'RM ${tx.total.toStringAsFixed(2)}', isLarge: true),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('PAID VIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
                    child: Text(tx.paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  )
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Items List
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SELECT ITEMS TO REFUND', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                        TextButton(
                          onPressed: selectAllItems,
                          child: Text(isWholeBill ? 'ALL SELECTED' : 'SELECT ALL', style: TextStyle(color: isWholeBill ? AppColors.rose600 : AppColors.indigo600, fontWeight: FontWeight.w900)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: tx.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = tx.items[index];
                          final selected = _refundItems.contains(item.id);
                          return InkWell(
                            onTap: () => toggleItem(item.id),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.rose50 : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: selected ? AppColors.rose500 : AppColors.slate100, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: selected ? AppColors.rose600 : AppColors.slate100, borderRadius: BorderRadius.circular(12)),
                                    child: Icon(selected ? Icons.check : Icons.local_offer, color: selected ? Colors.white : AppColors.slate400),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(item.category.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.slate400, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Column(
                                      children: [
                                        const Text('RESTOCK?', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                                        Switch(
                                          value: _restockMap[item.id] ?? true,
                                          activeColor: AppColors.emerald500,
                                          onChanged: (val) {
                                            setState(() => _restockMap[item.id] = val);
                                          },
                                        )
                                      ],
                                    ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('RM ${(item.price * item.qty).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                      Text('Qty: ${item.qty}', style: const TextStyle(fontSize: 10, color: AppColors.slate400, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Summary Sidebar
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.slate200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SUMMARY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                          if (isWholeBill)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.rose100, borderRadius: BorderRadius.circular(4)),
                              child: const Text('FULL VOID', style: TextStyle(color: AppColors.rose600, fontSize: 8, fontWeight: FontWeight.w900)),
                            )
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('REASON FOR RETURN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _refundReason.isEmpty ? null : _refundReason,
                        hint: const Text('Select a reason...'),
                        items: ['Damaged Goods', 'Expired Item', 'Wrong Order Taken', 'Customer Change of Mind', 'Full Bill Cancellation']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _refundReason = val ?? ''),
                        decoration: InputDecoration(
                          filled: true, fillColor: AppColors.slate50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.rose500)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('REFUND VIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 3,
                          children: [
                            _buildMethodBtn('Original', Icons.refresh),
                            _buildMethodBtn('Cash', Icons.attach_money),
                            _buildMethodBtn('E-Wallet', Icons.account_balance_wallet),
                            _buildMethodBtn('Credit', Icons.person),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(height: 1, color: AppColors.slate100),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ITEMS SELECTED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                          Text('${_refundItems.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL REFUND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                          Text('RM ${refundTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.rose600)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (!isWholeBill && _refundItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            width: double.infinity, height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                selectAllItems();
                                setState(() => _refundReason = 'Full Bill Cancellation');
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: const Text('Return Whole Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity, height: 64,
                        child: ElevatedButton(
                          onPressed: isFormValid ? () => setState(() => _currentView = RefundView.auth) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isWholeBill ? AppColors.rose600 : AppColors.rose500,
                            disabledBackgroundColor: AppColors.slate200,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                          child: Text(isWholeBill ? 'Void Whole Bill' : 'Authorize Refund', style: TextStyle(color: isFormValid ? Colors.white : AppColors.slate400, fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: resetSelection,
                          child: const Text('Reset Selection', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  /// Build refund method button
  Widget _buildMethodBtn(String method, IconData icon) {
    final sel = _refundMethod == method;
    return InkWell(
      onTap: () => setState(() => _refundMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: sel ? AppColors.rose50 : AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.rose500 : Colors.transparent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: sel ? AppColors.rose600 : AppColors.slate400),
            const SizedBox(width: 8),
            Text(method.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: sel ? AppColors.rose600 : AppColors.slate400)),
          ],
        ),
      ),
    );
  }

  /// Build header column helper
  Widget _buildHeaderCol(String title, String value, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate400)),
        Text(value, style: TextStyle(fontSize: isLarge ? 18 : 14, fontWeight: isLarge ? FontWeight.w900 : FontWeight.bold)),
      ],
    );
  }
}
