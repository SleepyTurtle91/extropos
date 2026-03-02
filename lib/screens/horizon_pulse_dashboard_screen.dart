import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/services/appwrite_service.dart';
import 'package:extropos/services/horizon_data_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:extropos/widgets/horizon_button.dart';
import 'package:extropos/widgets/horizon_charts.dart';
import 'package:extropos/widgets/horizon_layout.dart';
import 'package:extropos/widgets/horizon_metric_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

part 'horizon_pulse_dashboard_screen_ui.dart';

/// Horizon Admin - Enhanced Pulse Dashboard
/// Real-time business metrics with charts and trends
class HorizonPulseDashboardScreen extends StatefulWidget {
  const HorizonPulseDashboardScreen({super.key});

  @override
  State<HorizonPulseDashboardScreen> createState() => _HorizonPulseDashboardScreenState();
}

class _HorizonPulseDashboardScreenState extends State<HorizonPulseDashboardScreen> {
  final HorizonDataService _dataService = HorizonDataService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isRealtimeConnected = false;

  // Data
  Map<String, dynamic> _salesSummary = {};
  Map<int, double> _hourlySales = {};
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
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

      // Load data
      await _loadDashboardData();
      
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

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load today's sales summary
      final summary = await _dataService.getSalesSummary(
        startDate: DateTime.now().subtract(Duration(days: 1)),
        endDate: DateTime.now(),
      );

      // Load hourly sales for bar chart
      final hourly = await _dataService.getHourlySalesData(
        date: DateTime.now(),
      );

      // Load top products
      final products = await _dataService.getTopSellingProducts(
        limit: 4,
      );

      setState(() {
        _salesSummary = summary;
        _hourlySales = hourly;
        _topProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to transaction changes for live dashboard updates
    _dataService.subscribeToTransactionChanges((response) {
      print('🔄 Dashboard: Received transaction update');
      // Reload dashboard data when new transactions come in
      _loadDashboardData();
    });
    
    setState(() {
      _isRealtimeConnected = true;
    });
  }

  @override
  void dispose() {
    // Unsubscribe from all real-time updates
    _dataService.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('See horizon_pulse_dashboard_screen_ui.dart');
  }
}