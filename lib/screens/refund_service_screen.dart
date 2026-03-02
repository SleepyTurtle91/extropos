import 'package:extropos/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'refund_service_operations.dart';
part 'refund_service_header.dart';
part 'refund_service_left_panel.dart';
part 'refund_service_lookup_state.dart';
part 'refund_service_details_panel.dart';
part 'refund_service_auth_panel.dart';
part 'refund_service_success_panel.dart';

// --- Theme Colors ---
class AppColors {
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber800 = Color(0xFF92400E);
  static const Color indigo600 = Color(0xFF4F46E5);
}

// --- Models ---
enum RefundView { lookup, details, auth, success }

class TransactionItem {
  final int id;
  final String name;
  final double price;
  final int qty;
  final String category;

  TransactionItem(this.id, this.name, this.price, this.qty, this.category);
}

class Transaction {
  final String id;
  final String date;
  final String time;
  final String cashier;
  final String customer;
  final String customerPhone;
  final double total;
  final String paymentMethod;
  final String status;
  final List<TransactionItem> items;

  Transaction(this.id, this.date, this.time, this.cashier, this.customer,
      this.customerPhone, this.total, this.paymentMethod, this.status, this.items);
}

// --- Refund Service Screen ---
class RefundServiceScreen extends StatefulWidget {
  const RefundServiceScreen({super.key});

  @override
  State<RefundServiceScreen> createState() => _RefundServiceScreenState();
}

class _RefundServiceScreenState extends State<RefundServiceScreen> {
  RefundView _currentView = RefundView.lookup;
  String _searchQuery = '';
  Transaction? _selectedTransaction;
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoadingTransactions = false;

  Set<int> _refundItems = {};
  Map<int, bool> _restockMap = {};

  String _refundReason = '';
  String _refundMethod = '';
  String _internalNotes = '';
  String _managerPin = '';

  @override
  void initState() {
    super.initState();
    loadRecentTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildHeader(),
          Container(height: 1, color: AppColors.slate200),
          Expanded(
            child: Row(
              children: [
                buildLeftPanel(),
                Container(width: 1, color: AppColors.slate200),
                Expanded(child: buildRightPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRightPanel() {
    return Container(
      color: AppColors.slate50,
      padding: const EdgeInsets.all(48),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: buildCurrentView(),
      ),
    );
  }

  Widget buildCurrentView() {
    switch (_currentView) {
      case RefundView.lookup:
        return buildLookupEmptyState();
      case RefundView.details:
        return _selectedTransaction != null ? buildDetailsPanel() : buildLookupEmptyState();
      case RefundView.auth:
        return buildAuthPanel();
      case RefundView.success:
        return buildSuccessPanel();
    }
  }
}
