import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:intl/intl.dart';

/// Service for generating HTML email templates for reports
class EmailTemplateService {
  static final EmailTemplateService instance = EmailTemplateService._init();
  EmailTemplateService._init();

  final _currencyFormatter = NumberFormat.currency(
    symbol: 'RM ',
    decimalDigits: 2,
  );
  final _dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
  final _timeFormatter = DateFormat('h:mm a');

  /// Generate HTML email for scheduled report
  String generateScheduledReportEmail({
    required String reportType,
    required String reportName,
    required ReportPeriod period,
    required Map<String, dynamic> reportData,
    List<String>? attachmentFilenames,
  }) {
    final businessInfo = BusinessInfo.instance;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      margin: 0;
      padding: 0;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 600px;
      margin: 20px auto;
      background: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .header {
      background: linear-gradient(135deg, #2563EB 0%, #1E40AF 100%);
      color: white;
      padding: 30px 20px;
      text-align: center;
    }
    .header h1 {
      margin: 0 0 10px 0;
      font-size: 24px;
      font-weight: 600;
    }
    .header p {
      margin: 0;
      opacity: 0.9;
      font-size: 14px;
    }
    .content {
      padding: 30px 20px;
    }
    .business-info {
      text-align: center;
      margin-bottom: 30px;
      padding-bottom: 20px;
      border-bottom: 2px solid #f0f0f0;
    }
    .business-info h2 {
      margin: 0 0 5px 0;
      font-size: 20px;
      color: #2563EB;
    }
    .business-info p {
      margin: 3px 0;
      font-size: 13px;
      color: #666;
    }
    .report-summary {
      background: #f8fafc;
      border-radius: 6px;
      padding: 20px;
      margin-bottom: 25px;
    }
    .report-summary h3 {
      margin: 0 0 15px 0;
      font-size: 16px;
      color: #1e293b;
    }
    .summary-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #e2e8f0;
    }
    .summary-row:last-child {
      border-bottom: none;
    }
    .summary-label {
      font-size: 14px;
      color: #64748b;
    }
    .summary-value {
      font-size: 14px;
      font-weight: 600;
      color: #1e293b;
    }
    .attachments {
      background: #fef3c7;
      border-left: 4px solid #f59e0b;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .attachments h4 {
      margin: 0 0 10px 0;
      font-size: 14px;
      color: #92400e;
    }
    .attachment-list {
      list-style: none;
      padding: 0;
      margin: 0;
    }
    .attachment-list li {
      padding: 5px 0;
      font-size: 13px;
      color: #78350f;
    }
    .attachment-list li:before {
      content: "📎 ";
      margin-right: 5px;
    }
    .footer {
      background: #f8fafc;
      padding: 20px;
      text-align: center;
      font-size: 12px;
      color: #64748b;
      border-top: 1px solid #e2e8f0;
    }
    .footer p {
      margin: 5px 0;
    }
    .cta-button {
      display: inline-block;
      background: #2563EB;
      color: white;
      padding: 12px 24px;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 500;
      margin: 20px 0;
    }
    .metric-card {
      background: white;
      border: 1px solid #e2e8f0;
      border-radius: 6px;
      padding: 15px;
      margin: 10px 0;
    }
    .metric-card h4 {
      margin: 0 0 8px 0;
      font-size: 13px;
      color: #64748b;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .metric-card .value {
      font-size: 28px;
      font-weight: 700;
      color: #1e293b;
    }
    .metric-card .trend {
      font-size: 12px;
      margin-top: 5px;
    }
    .trend.up {
      color: #16a34a;
    }
    .trend.down {
      color: #dc2626;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${_escapeHtml(reportName)}</h1>
      <p>${_escapeHtml(reportType)} • ${_formatPeriodLabel(period)}</p>
    </div>
    
    <div class="content">
      <div class="business-info">
        <h2>${_escapeHtml(businessInfo.businessName)}</h2>
        ${businessInfo.address.isNotEmpty ? '<p>${_escapeHtml(businessInfo.address)}</p>' : ''}
        ${businessInfo.phone.isNotEmpty ? '<p>📞 ${_escapeHtml(businessInfo.phone)}</p>' : ''}
        ${businessInfo.email.isNotEmpty ? '<p>✉️ ${_escapeHtml(businessInfo.email)}</p>' : ''}
      </div>
      
      ${_buildReportContent(reportType, reportData)}
      
      ${attachmentFilenames != null && attachmentFilenames.isNotEmpty ? '''
      <div class="attachments">
        <h4>📄 Report Attachments</h4>
        <ul class="attachment-list">
          ${attachmentFilenames.map((f) => '<li>${_escapeHtml(f)}</li>').join('\n          ')}
        </ul>
      </div>
      ''' : ''}
    </div>
    
    <div class="footer">
      <p>Generated by FlutterPOS v1.0.14</p>
      <p>${_dateFormatter.format(DateTime.now())} at ${_timeFormatter.format(DateTime.now())}</p>
      <p style="margin-top: 10px; color: #94a3b8;">
        This is an automated report. Please do not reply to this email.
      </p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build report-specific content based on report type
  String _buildReportContent(String reportType, Map<String, dynamic> data) {
    switch (reportType.toLowerCase()) {
      case 'daily_sales':
      case 'sales':
        return _buildSalesReportContent(data);
      case 'product_performance':
      case 'products':
        return _buildProductReportContent(data);
      case 'employee_performance':
      case 'employees':
        return _buildEmployeeReportContent(data);
      case 'profit_loss':
        return _buildProfitLossContent(data);
      case 'comparative_analysis':
        return _buildComparativeAnalysisContent(data);
      default:
        return _buildGenericReportContent(data);
    }
  }

  /// Build sales report content
  String _buildSalesReportContent(Map<String, dynamic> data) {
    final totalSales = data['totalSales'] as double? ?? 0.0;
    final transactionCount = data['transactionCount'] as int? ?? 0;
    final averageTransaction = transactionCount > 0
        ? totalSales / transactionCount
        : 0.0;
    final taxAmount = data['taxAmount'] as double? ?? 0.0;

    return '''
    <div class="report-summary">
      <h3>📊 Sales Summary</h3>
      <div class="summary-row">
        <span class="summary-label">Total Sales</span>
        <span class="summary-value">${_currencyFormatter.format(totalSales)}</span>
      </div>
      <div class="summary-row">
        <span class="summary-label">Transactions</span>
        <span class="summary-value">$transactionCount</span>
      </div>
      <div class="summary-row">
        <span class="summary-label">Average Transaction</span>
        <span class="summary-value">${_currencyFormatter.format(averageTransaction)}</span>
      </div>
      ${taxAmount > 0 ? '''
      <div class="summary-row">
        <span class="summary-label">Tax Collected</span>
        <span class="summary-value">${_currencyFormatter.format(taxAmount)}</span>
      </div>
      ''' : ''}
    </div>
''';
  }

  /// Build product performance content
  String _buildProductReportContent(Map<String, dynamic> data) {
    final topProducts = data['topProducts'] as List? ?? [];

    return '''
    <div class="report-summary">
      <h3>🏆 Top Performing Products</h3>
      ${topProducts.isEmpty ? '<p style="text-align: center; color: #94a3b8;">No product data available</p>' : topProducts.take(5).map((product) {
            final name = product['name'] as String? ?? 'Unknown';
            final quantity = product['quantity'] as int? ?? 0;
            final revenue = product['revenue'] as double? ?? 0.0;
            return '''
      <div class="summary-row">
        <span class="summary-label">$name ($quantity sold)</span>
        <span class="summary-value">${_currencyFormatter.format(revenue)}</span>
      </div>
''';
          }).join()}
    </div>
''';
  }

  /// Build employee performance content
  String _buildEmployeeReportContent(Map<String, dynamic> data) {
    final employees = data['employees'] as List? ?? [];

    return '''
    <div class="report-summary">
      <h3>👥 Employee Performance</h3>
      ${employees.isEmpty ? '<p style="text-align: center; color: #94a3b8;">No employee data available</p>' : employees.take(5).map((emp) {
            final name = emp['name'] as String? ?? 'Unknown';
            final sales = emp['totalSales'] as double? ?? 0.0;
            final transactions = emp['transactionCount'] as int? ?? 0;
            return '''
      <div class="summary-row">
        <span class="summary-label">$name ($transactions txns)</span>
        <span class="summary-value">${_currencyFormatter.format(sales)}</span>
      </div>
''';
          }).join()}
    </div>
''';
  }

  /// Build profit & loss content
  String _buildProfitLossContent(Map<String, dynamic> data) {
    final revenue = data['revenue'] as double? ?? 0.0;
    final costs = data['costs'] as double? ?? 0.0;
    final profit = revenue - costs;
    final margin = revenue > 0 ? (profit / revenue * 100) : 0.0;

    return '''
    <div class="metric-card">
      <h4>Total Revenue</h4>
      <div class="value">${_currencyFormatter.format(revenue)}</div>
    </div>
    
    <div class="metric-card">
      <h4>Total Costs</h4>
      <div class="value">${_currencyFormatter.format(costs)}</div>
    </div>
    
    <div class="metric-card">
      <h4>Net Profit</h4>
      <div class="value" style="color: ${profit >= 0 ? '#16a34a' : '#dc2626'}">
        ${_currencyFormatter.format(profit)}
      </div>
      <div class="trend ${profit >= 0 ? 'up' : 'down'}">
        ${margin.toStringAsFixed(1)}% Profit Margin
      </div>
    </div>
''';
  }

  /// Build comparative analysis content
  String _buildComparativeAnalysisContent(Map<String, dynamic> data) {
    final current = data['currentPeriod'] as Map<String, dynamic>? ?? {};
    final previous = data['previousPeriod'] as Map<String, dynamic>? ?? {};
    final currentSales = current['totalSales'] as double? ?? 0.0;
    final previousSales = previous['totalSales'] as double? ?? 0.0;
    final change = currentSales - previousSales;
    final changePercent = previousSales > 0
        ? (change / previousSales * 100)
        : 0.0;

    return '''
    <div class="metric-card">
      <h4>Current Period Sales</h4>
      <div class="value">${_currencyFormatter.format(currentSales)}</div>
      <div class="trend ${changePercent >= 0 ? 'up' : 'down'}">
        ${changePercent >= 0 ? '▲' : '▼'} ${changePercent.abs().toStringAsFixed(1)}% 
        ${changePercent >= 0 ? 'increase' : 'decrease'} from previous period
      </div>
    </div>
    
    <div class="report-summary">
      <h3>📈 Period Comparison</h3>
      <div class="summary-row">
        <span class="summary-label">Previous Period</span>
        <span class="summary-value">${_currencyFormatter.format(previousSales)}</span>
      </div>
      <div class="summary-row">
        <span class="summary-label">Current Period</span>
        <span class="summary-value">${_currencyFormatter.format(currentSales)}</span>
      </div>
      <div class="summary-row">
        <span class="summary-label">Change</span>
        <span class="summary-value" style="color: ${change >= 0 ? '#16a34a' : '#dc2626'}">
          ${change >= 0 ? '+' : ''}${_currencyFormatter.format(change)}
        </span>
      </div>
    </div>
''';
  }

  /// Build generic report content
  String _buildGenericReportContent(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return '<p style="text-align: center; color: #94a3b8;">No data available for this report</p>';
    }

    return '''
    <div class="report-summary">
      <h3>📋 Report Data</h3>
      ${data.entries.map((entry) {
      if (entry.value is num) {
        final value = entry.value is double ? _currencyFormatter.format(entry.value) : entry.value.toString();
        return '''
      <div class="summary-row">
        <span class="summary-label">${_formatLabel(entry.key)}</span>
        <span class="summary-value">$value</span>
      </div>
''';
      }
      return '';
    }).join()}
    </div>
''';
  }

  /// Format period label for display
  String _formatPeriodLabel(ReportPeriod period) {
    if (period.label.isNotEmpty) return period.label;

    final start = DateFormat('MMM d, yyyy').format(period.startDate);
    final end = DateFormat('MMM d, yyyy').format(period.endDate);
    return '$start - $end';
  }

  /// Format label by splitting camelCase and capitalizing
  String _formatLabel(String label) {
    return label
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Escape HTML special characters
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Generate plain text version of email (for email clients that don't support HTML)
  String generatePlainTextEmail({
    required String reportType,
    required String reportName,
    required ReportPeriod period,
    required Map<String, dynamic> reportData,
    List<String>? attachmentFilenames,
  }) {
    final businessInfo = BusinessInfo.instance;
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln(reportName);
    buffer.writeln('$reportType • ${_formatPeriodLabel(period)}');
    buffer.writeln('=' * 60);
    buffer.writeln();
    buffer.writeln(businessInfo.businessName);
    if (businessInfo.address.isNotEmpty) {
      buffer.writeln(businessInfo.address);
    }
    if (businessInfo.phone.isNotEmpty) {
      buffer.writeln('Phone: ${businessInfo.phone}');
    }
    buffer.writeln();
    buffer.writeln('-' * 60);
    buffer.writeln('REPORT SUMMARY');
    buffer.writeln('-' * 60);

    // Add key metrics
    if (reportData['totalSales'] != null) {
      buffer.writeln(
        'Total Sales: ${_currencyFormatter.format(reportData['totalSales'])}',
      );
    }
    if (reportData['transactionCount'] != null) {
      buffer.writeln('Transactions: ${reportData['transactionCount']}');
    }

    if (attachmentFilenames != null && attachmentFilenames.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Attachments:');
      for (final filename in attachmentFilenames) {
        buffer.writeln('  • $filename');
      }
    }

    buffer.writeln();
    buffer.writeln('-' * 60);
    buffer.writeln('Generated by FlutterPOS v1.0.14');
    buffer.writeln(
      '${_dateFormatter.format(DateTime.now())} at ${_timeFormatter.format(DateTime.now())}',
    );
    buffer.writeln('=' * 60);

    return buffer.toString();
  }
}
