import 'dart:convert';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/merchant_model.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

part 'sales_history_operations.dart';
part 'sales_history_order_details.dart';
part 'sales_history_void_dialog.dart';
part 'sales_history_refund_dialog.dart';
part 'sales_history_receipt.dart';
part 'sales_history_filters.dart';
part 'sales_history_order_list.dart';

// Note: writes CSV to `exports/` folder in project root.

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  DateTime? _from;
  DateTime? _to;
  String? _selectedPaymentMethodId;
  List<PaymentMethod> _paymentMethods = [];

  int _page = 0;
  final int _pageSize = 50;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    loadPaymentMethods();
    loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: exportCsv,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadOrders,
              child: Column(
                children: [
                  buildFiltersSection(),
                  Expanded(child: buildOrderList()),
                ],
              ),
            ),
    );
  }
}
