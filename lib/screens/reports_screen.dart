import 'dart:io';

import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/screens/sales_history_screen.dart';
import 'package:extropos/screens/shift_reports_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/kpi_card.dart';
import 'package:extropos/widgets/report_date_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

part 'reports_screen_methods.dart';
part 'reports_screen_widgets.dart';
part 'reports_screen_exports.dart';

/// Modern Reports Dashboard Screen
/// Provides comprehensive analytics and reporting capabilities
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth();
  String? _selectedCategory;
  String? _selectedStaff;
  bool _showComparison = false;

  SalesSummary? _salesSummary;
  SalesSummary? _comparisonSummary;
  List<ProductPerformance> _topProducts = [];
  List<StaffPerformance> _staffPerformance = [];
  List<ProductAnalytics> _productAnalytics = [];
  List<DailySales> _dailySales = [];
  List<String> _categories = [];
  final List<String> _staffMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFilters();
    loadReportsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadReportsData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadReportsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Advanced Filters
                    _buildAdvancedFilters(),
                    const SizedBox(height: 24),

                    // KPI Cards with Comparison
                    if (_salesSummary != null) ...[
                      _buildKPIGrid(_salesSummary!, _comparisonSummary),
                      const SizedBox(height: 32),
                    ],

                    // Charts Section
                    const Text(
                      'Sales Trends',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSalesChart(),
                    const SizedBox(height: 32),

                    // Staff Performance
                    const Text(
                      'Staff Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStaffPerformance(),
                    const SizedBox(height: 32),

                    // Product Analytics
                    const Text(
                      'Product Analytics (ABC Analysis)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProductAnalytics(),
                    const SizedBox(height: 32),

                    // Top Products
                    const Text(
                      'Top Performing Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopProductsList(),
                    const SizedBox(height: 32),

                    // Quick Actions
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }
}
