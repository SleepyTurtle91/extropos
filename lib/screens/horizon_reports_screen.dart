import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/services/appwrite_service.dart';
import 'package:extropos/services/horizon_data_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:extropos/widgets/horizon_button.dart';
import 'package:extropos/widgets/horizon_layout.dart';
import 'package:flutter/material.dart';

part 'horizon_reports_ui.dart';
part 'horizon_reports_helpers.dart';

/// Horizon Admin - Reports & Analytics Screen
/// Comprehensive business analytics with charts and comparisons
class HorizonReportsScreen extends StatefulWidget {
  const HorizonReportsScreen({super.key});

  @override
  State<HorizonReportsScreen> createState() => _HorizonReportsScreenState();
}

class _HorizonReportsScreenState extends State<HorizonReportsScreen> {
  final HorizonDataService _dataService = HorizonDataService();
  DateTimeRange? _dateRange;
  String _reportType = 'Daily';
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Report data
  Map<String, dynamic> _salesSummary = {};
  List<Map<String, dynamic>> _topProducts = [];
  Map<int, double> _hourlySales = {};
  Map<int, double> _previousHourlySales = {};
  Map<String, double> _categorySales = {};
  Map<String, double> _paymentMethods = {};
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      // Initialize Appwrite client
      final appwriteService = AppwriteService.instance;
      if (!appwriteService.isInitialized) {
        await appwriteService.initialize();
      }

      // Initialize data service
      if (appwriteService.client != null) {
        await _dataService.initialize(appwriteService.client!);
      } else {
        throw Exception('Appwrite client is null');
      }

      // Load report data
      await _loadReportData();
      
      // Subscribe to real-time updates
      _subscribeToUpdates();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final startDate = _dateRange?.start;
      final endDate = _dateRange?.end;

      // Load sales summary
      final summary = await _dataService.getSalesSummary(
        startDate: startDate,
        endDate: endDate,
      );

      // Load top products
      final products = await _dataService.getTopSellingProducts(
        startDate: startDate,
        endDate: endDate,
        limit: 10,
      );

      // Load hourly sales for the selected period
      final hourly = await _dataService.getHourlySalesData(
        date: _dateRange?.end ?? DateTime.now(),
      );

      // Load previous period hourly sales (previous day)
      final previousDate = (_dateRange?.end ?? DateTime.now()).subtract(Duration(days: 1));
      final previousHourly = await _dataService.getHourlySalesData(
        date: previousDate,
      );

      // Load category sales
      final categorySales = await _dataService.getCategorySalesData(
        startDate: startDate,
        endDate: endDate,
      );

      // Load payment method data
      final paymentData = await _dataService.getPaymentMethodData(
        startDate: startDate,
        endDate: endDate,
      );

      // Load categories for mapping
      final categories = await _dataService.getCategories();

      setState(() {
        _salesSummary = summary;
        _topProducts = products;
        _hourlySales = hourly;
        _previousHourlySales = previousHourly;
        _categorySales = categorySales;
        _paymentMethods = paymentData;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load report data: $e';
        _isLoading = false;
      });
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to transaction changes for live report updates
    _dataService.subscribeToTransactionChanges((response) {
      print('🔄 Reports: Received transaction update');
      // Reload report data when new transactions come in
      _loadReportData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return HorizonLayout(
        breadcrumbs: const ['Reports', 'Analytics'],
        currentRoute: '/reports',
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading reports...'),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_hasError) {
      return HorizonLayout(
        breadcrumbs: const ['Reports', 'Analytics'],
        currentRoute: '/reports',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: HorizonColors.rose),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 24),
              HorizonButton(
                text: 'Retry',
                type: HorizonButtonType.primary,
                icon: Icons.refresh,
                onPressed: _loadReportData,
              ),
            ],
          ),
        ),
      );
    }

    return const ComingSoonPlaceholder(
      title: 'Horizon Reports',
      subtitle: 'Cloud analytics reports are coming soon.',
    );
  }
}
