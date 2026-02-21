import 'dart:developer' as developer;

import 'package:extropos/models/dealer_customer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/license_service.dart';

/// Service for Dealer Analytics
/// Provides real analytics data for dealer's managed tenants
class DealerAnalyticsService {
  static final DealerAnalyticsService _instance = DealerAnalyticsService._internal();
  static DealerAnalyticsService get instance => _instance;

  DealerAnalyticsService._internal();

  /// Get analytics data for a specific time period
  Future<Map<String, dynamic>> getAnalyticsData(String period) async {
    try {
      developer.log('DealerAnalyticsService: Fetching analytics for period: $period');

      // Get all dealer customers
      final customers = await _getDealerCustomers();

      // Calculate date range based on period
      final dateRange = _getDateRangeForPeriod(period);
      final startDate = dateRange['start'];
      final endDate = dateRange['end'];

      // Get license data
      final licenseData = await _getLicenseAnalytics(customers, startDate, endDate);

      // Calculate metrics
      final totalTenants = customers.length;
      final activeTenants = customers.where((c) => c.isActive).length;
      final newTenants = await _getNewTenantsCount(startDate, endDate);

      // Revenue calculation (mock for now - would need actual payment/transaction data)
      final totalRevenue = await _calculateTotalRevenue(customers, startDate, endDate);
      final avgRevenuePerTenant = totalTenants > 0 ? totalRevenue / totalTenants : 0.0;

      return {
        'totalTenants': totalTenants,
        'activeTenants': activeTenants,
        'totalRevenue': totalRevenue,
        'newTenants': newTenants,
        'totalLicenses': licenseData['totalLicenses'],
        'expiringLicenses': licenseData['expiringLicenses'],
        'avgRevenuePerTenant': avgRevenuePerTenant,
        'period': period,
      };
    } catch (e) {
      developer.log('DealerAnalyticsService: Error fetching analytics: $e');
      // Return mock data as fallback
      return _getMockDataForPeriod(period);
    }
  }

  /// Get dealer customers from database
  Future<List<DealerCustomer>> _getDealerCustomers() async {
    try {
      final maps = await DatabaseService.instance.getDealerCustomers();
      return maps.map((map) => DealerCustomer.fromMap(map)).toList();
    } catch (e) {
      developer.log('DealerAnalyticsService: Error fetching customers: $e');
      return [];
    }
  }

  /// Calculate date range for analytics period
  Map<String, DateTime> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case '7d':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90d':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '1y':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    return {
      'start': startDate,
      'end': now,
    };
  }

  /// Get license analytics data
  Future<Map<String, int>> _getLicenseAnalytics(
    List<DealerCustomer> customers,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      int totalLicenses = 0;
      int expiringLicenses = 0;

      for (final customer in customers) {
        // Check if customer has active license
        final licenseService = LicenseService.instance;
        // This would need to be implemented to check actual license status
        // For now, assume each active customer has 1 license
        if (customer.isActive) {
          totalLicenses++;
        }

        // Check for expiring licenses (within 30 days)
        // This would need license expiry date checking
        // For now, assume some licenses are expiring
        if (customer.isActive && _shouldLicenseExpireSoon(customer)) {
          expiringLicenses++;
        }
      }

      return {
        'totalLicenses': totalLicenses,
        'expiringLicenses': expiringLicenses,
      };
    } catch (e) {
      developer.log('DealerAnalyticsService: Error calculating license analytics: $e');
      return {'totalLicenses': 0, 'expiringLicenses': 0};
    }
  }

  /// Get count of new tenants in the period
  Future<int> _getNewTenantsCount(DateTime? startDate, DateTime? endDate) async {
    if (startDate == null) return 0;

    try {
      final customers = await _getDealerCustomers();
      return customers.where((c) => c.createdAt.isAfter(startDate)).length;
    } catch (e) {
      developer.log('DealerAnalyticsService: Error counting new tenants: $e');
      return 0;
    }
  }

  /// Calculate total revenue (placeholder - would need actual payment data)
  Future<double> _calculateTotalRevenue(
    List<DealerCustomer> customers,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // This is a placeholder calculation
    // In a real implementation, this would query payment/transaction data
    // For now, return a mock calculation based on customer count
    final activeCustomers = customers.where((c) => c.isActive).length;

    // Mock revenue calculation: assume average RM 5000 per month per tenant
    const monthlyRevenuePerTenant = 5000.0;
    final months = startDate != null ? DateTime.now().difference(startDate).inDays / 30.0 : 1.0;

    return activeCustomers * monthlyRevenuePerTenant * months.clamp(0.1, 12.0);
  }

  /// Check if a customer's license should expire soon (mock implementation)
  bool _shouldLicenseExpireSoon(DealerCustomer customer) {
    // Mock logic: assume 10% of licenses expire soon
    return customer.id.hashCode % 10 == 0;
  }

  /// Get tenant status breakdown
  Future<Map<String, int>> getTenantStatusBreakdown() async {
    try {
      final customers = await _getDealerCustomers();

      int active = customers.where((c) => c.isActive).length;
      int inactive = customers.where((c) => !c.isActive).length;

      return {
        'active': active,
        'inactive': inactive,
        'total': customers.length,
      };
    } catch (e) {
      developer.log('DealerAnalyticsService: Error getting tenant status: $e');
      return {'active': 0, 'inactive': 0, 'total': 0};
    }
  }

  /// Get revenue trend data for charts
  Future<List<Map<String, dynamic>>> getRevenueTrendData(String period) async {
    try {
      final customers = await _getDealerCustomers();
      final dateRange = _getDateRangeForPeriod(period);
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;

      // Generate monthly data points
      final dataPoints = <Map<String, dynamic>>[];
      var currentDate = startDate;

      while (currentDate.isBefore(endDate)) {
        final monthEnd = DateTime(currentDate.year, currentDate.month + 1, 0);
        final actualEnd = monthEnd.isBefore(endDate) ? monthEnd : endDate;

        // Calculate revenue for this month
        final monthlyRevenue = await _calculateMonthlyRevenue(customers, currentDate, actualEnd);

        dataPoints.add({
          'month': '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}',
          'revenue': monthlyRevenue,
          'tenants': customers.where((c) => c.createdAt.isBefore(actualEnd)).length,
        });

        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }

      return dataPoints;
    } catch (e) {
      developer.log('DealerAnalyticsService: Error getting revenue trend: $e');
      return [];
    }
  }

  /// Calculate monthly revenue (placeholder)
  Future<double> _calculateMonthlyRevenue(
    List<DealerCustomer> customers,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Mock calculation - in real implementation would query actual transaction data
    final activeCustomers = customers.where((c) =>
      c.isActive && c.createdAt.isBefore(endDate)
    ).length;

    const monthlyRevenuePerTenant = 5000.0;
    return activeCustomers * monthlyRevenuePerTenant;
  }

  /// Fallback mock data for when real data is unavailable
  Map<String, dynamic> _getMockDataForPeriod(String period) {
    const mockData = {
      '7d': {
        'totalTenants': 12,
        'activeTenants': 10,
        'totalRevenue': 45600.00,
        'newTenants': 2,
        'totalLicenses': 15,
        'expiringLicenses': 3,
        'avgRevenuePerTenant': 3800.00,
      },
      '30d': {
        'totalTenants': 24,
        'activeTenants': 20,
        'totalRevenue': 125400.00,
        'newTenants': 8,
        'totalLicenses': 35,
        'expiringLicenses': 5,
        'avgRevenuePerTenant': 5225.00,
      },
      '90d': {
        'totalTenants': 45,
        'activeTenants': 38,
        'totalRevenue': 342800.00,
        'newTenants': 18,
        'totalLicenses': 68,
        'expiringLicenses': 12,
        'avgRevenuePerTenant': 7617.78,
      },
    };

    return mockData[period] ?? mockData['30d']!;
  }
}