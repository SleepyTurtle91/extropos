import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/employee_performance_models.dart';
import 'package:extropos/services/employee_performance_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'employee_performance_screen_overview_ui.dart';
part 'employee_performance_screen_shifts_ui.dart';

class EmployeePerformanceScreen extends StatefulWidget {
  const EmployeePerformanceScreen({super.key});

  @override
  State<EmployeePerformanceScreen> createState() =>
      _EmployeePerformanceScreenState();
}

class _EmployeePerformanceScreenState extends State<EmployeePerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  List<EmployeePerformance> _performances = [];
  List<EmployeeRanking> _rankings = [];
  ShiftReport? _selectedShiftReport;
  String? _selectedUserId;
  bool _isLoading = false;

  final _performanceService = EmployeePerformanceService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final performances = await _performanceService.getEmployeePerformance(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );

      final rankings = await _performanceService.getEmployeeLeaderboard(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
        limit: 10,
      );

      setState(() {
        _performances = performances;
        _rankings = rankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastHelper.showToast(context, 'Error loading performance data: $e');
      }
    }
  }

  Future<void> _loadShiftReport(String userId) async {
    try {
      final report = await _performanceService.getShiftReport(
        userId: userId,
        shiftStart: _dateRange.start,
        shiftEnd: _dateRange.end,
      );

      setState(() {
        _selectedShiftReport = report;
        _selectedUserId = userId;
      });
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error loading shift report: $e');
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      await _loadData();
    }
  }

  Future<void> _exportCsv() async {
    try {
      final path = await _performanceService.saveEmployeePerformanceCsv(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );

      if (mounted) {
        ToastHelper.showToast(context, 'Report exported to: $path');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error exporting report: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Performance'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Overview'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Leaderboard'),
            Tab(icon: Icon(Icons.access_time), text: 'Shift Reports'),
          ],
        ),
      ),
      body: Column(
        children: [
          buildDateRangeDisplay(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      buildOverviewTab(),
                      buildLeaderboardTab(),
                      buildShiftReportsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

