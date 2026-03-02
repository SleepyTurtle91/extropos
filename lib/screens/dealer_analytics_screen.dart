import 'package:extropos/services/dealer_analytics_service.dart';
import 'package:flutter/material.dart';

part 'dealer_analytics_screen_ui.dart';

/// Dealer Analytics Screen
/// Shows sales and performance metrics for dealer's managed tenants
class DealerAnalyticsScreen extends StatefulWidget {
  const DealerAnalyticsScreen({super.key});

  @override
  State<DealerAnalyticsScreen> createState() => _DealerAnalyticsScreenState();
}

class _DealerAnalyticsScreenState extends State<DealerAnalyticsScreen> {
  String _selectedPeriod = '30d';
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _revenueTrendData = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsData = await DealerAnalyticsService.instance.getAnalyticsData(_selectedPeriod);
      final revenueTrendData = await DealerAnalyticsService.instance.getRevenueTrendData(_selectedPeriod);

      setState(() {
        _analyticsData = analyticsData;
        _revenueTrendData = revenueTrendData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => throw UnimplementedError(
        'See dealer_analytics_screen_ui.dart',
      );

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }
}
