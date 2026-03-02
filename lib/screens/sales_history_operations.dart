part of 'sales_history_screen.dart';

/// Extension containing data operations for sales history screen
extension SalesHistoryOperations on _SalesHistoryScreenState {
  /// Load payment methods from database
  Future<void> loadPaymentMethods() async {
    final methods = await DatabaseService.instance.getPaymentMethods();
    if (!mounted) return;
    setState(() {
      _paymentMethods = methods;
    });
  }

  /// Load orders with current filters and pagination
  Future<void> loadOrders({int page = 0}) async {
    setState(() => _loading = true);
    final offset = page * _pageSize;
    final orders = await DatabaseService.instance.getOrders(
      from: _from,
      to: _to,
      paymentMethodId: _selectedPaymentMethodId,
      offset: offset,
      limit: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _page = page;
      _hasMore = orders.length == _pageSize;
      _loading = false;
    });
  }

  /// Export orders to CSV file
  Future<void> exportCsv() async {
    final currentContext = context; // capture early for toast/UI calls
    try {
      // Let the OS-native dialog handle filename and location in one step
      // Build a slug for the business name to make the filename filesystem-safe
      final bizSlug = BusinessInfo.instance.businessName
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .trim();
      String dateRangeSegment = '';
      if (_from != null || _to != null) {
        final f = _from != null
            ? _from!.toIso8601String().split('T').first
            : 'any';
        final t = _to != null ? _to!.toIso8601String().split('T').first : 'any';
        dateRangeSegment = '_${f}_to_$t';
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final suggestedName =
          'sales_history_$bizSlug${dateRangeSegment}_$timestamp.csv';
      final location = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );
      if (location == null) return; // user cancelled

      // Generate CSV (per-order-item rows)
      final csv = await DatabaseService.instance.exportOrdersCsv(
        from: _from,
        to: _to,
        paymentMethodId: _selectedPaymentMethodId,
        limit: 100000,
      );

      if (csv.trim().isEmpty) {
        if (!mounted) return;
        ToastHelper.showToast(currentContext, 'No orders to export');
        return;
      }

      final file = File(location.path);
      await file.writeAsString(csv);

      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Exported orders to ${location.path}');
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Export failed: $e');
    }
  }

  /// Parse modifiers from order item notes JSON
  List<Map<String, dynamic>> parseModifiersFromNotes(
    Map<String, dynamic> item,
  ) {
    final notes = item['notes'];
    if (notes == null) return [];
    try {
      final decoded = jsonDecode(notes);
      if (decoded is Map<String, dynamic> && decoded['modifiers'] is List) {
        final mods = (decoded['modifiers'] as List)
            .map<Map<String, dynamic>>(
              (m) => {
                'name': m['name'] ?? m['item_name'] ?? '',
                'price': (m['priceAdjustment'] as num?)?.toDouble() ?? 0.0,
              },
            )
            .toList();
        return mods;
      }
    } catch (e) {
      developer.log(
        'Failed to parse modifiers from notes: $e',
        name: 'sales_history',
      );
    }
    return [];
  }
}
