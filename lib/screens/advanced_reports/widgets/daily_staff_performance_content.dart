import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:flutter/material.dart';

class DailyStaffPerformanceContent extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const DailyStaffPerformanceContent({
    super.key,
    required this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final staffData = reportData['staffData'] as List<dynamic>;
    final summary = reportData['summary'] as Map<String, dynamic>;
    final businessDate =
        DateTime.parse(reportData['businessDate'] as String);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Staff Performance Report',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Business Date: ${FormattingService.formatDate(businessDate.toIso8601String())}',
                  ),
                  const Text('Report Type: Consolidated Staff Summary'),
                  Text(
                    'Tax Entity: ${BusinessInfo.instance.businessName} | SST No: ${BusinessInfo.instance.taxNumber ?? 'N/A'}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sales Performance Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Sales Performance Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('Login Time')),
                        DataColumn(label: Text('Logout Time')),
                        DataColumn(label: Text('Gross Sales (RM)')),
                        DataColumn(label: Text('Disc (RM)')),
                        DataColumn(label: Text('Net Sales (RM)')),
                        DataColumn(label: Text('Trans Count')),
                      ],
                      rows: [
                        ...staffData.map(
                          (staff) => DataRow(
                            cells: [
                              DataCell(Text(staff['userName'] as String)),
                              DataCell(
                                Text(_formatTime(staff['loginTime'] as String?)),
                              ),
                              DataCell(
                                Text(_formatTime(staff['logoutTime'] as String?)),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    staff['grossSales'] as double,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    staff['discounts'] as double,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    staff['netSales'] as double,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  (staff['transactionCount'] as int).toString(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataRow(
                          cells: [
                            const DataCell(
                              Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataCell(Text('')),
                            const DataCell(Text('')),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  summary['totalGrossSales'] as double,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  summary['totalDiscounts'] as double,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  summary['totalNetSales'] as double,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                (summary['totalTransactions'] as int).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // SST & Tax Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. SST & Tax Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('SST 6% (F&B)')),
                        DataColumn(label: Text('SST 8% (Other)')),
                        DataColumn(label: Text('Tax-Exempt')),
                        DataColumn(label: Text('Total SST')),
                      ],
                      rows: [
                        ...staffData.map(
                          (staff) => DataRow(
                            cells: [
                              DataCell(Text(staff['userName'] as String)),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    (staff['taxBreakdown'] as Map<String, dynamic>)['0.06'] ?? 0,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    (staff['taxBreakdown'] as Map<String, dynamic>)['0.08'] ?? 0,
                                  ),
                                ),
                              ),
                              const DataCell(Text('0.00')),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    (staff['taxBreakdown'] as Map<String, dynamic>).values.fold<double>(
                                          0,
                                          (sum, amount) => sum + (amount as double),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataRow(
                          cells: [
                            const DataCell(
                              Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['taxBreakdown'] as Map)['0.06'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['taxBreakdown'] as Map)['0.08'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const DataCell(Text('0.00')),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['taxBreakdown'] as Map).values.fold<double>(
                                        0,
                                        (sum, amount) => sum + (amount as double),
                                      ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Payment Method Audit
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3. Payment Method Audit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('Cash')),
                        DataColumn(label: Text('Credit Card')),
                        DataColumn(label: Text('TNG/GrabPay')),
                        DataColumn(label: Text('ShopeePay')),
                      ],
                      rows: [
                        ...staffData.map(
                          (staff) => DataRow(
                            cells: [
                              DataCell(Text(staff['userName'] as String)),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    (staff['paymentMethods'] as Map<String, dynamic>)['Cash'] ?? 0,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    (staff['paymentMethods'] as Map<String, dynamic>)['Credit Card'] ?? 0,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    (staff['paymentMethods'] as Map<String, dynamic>)['TNG / GrabPay'] ?? 0,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    (staff['paymentMethods'] as Map<String, dynamic>)['ShopeePay'] ?? 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataRow(
                          cells: [
                            const DataCell(
                              Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['paymentMethodTotals'] as Map)['Cash'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['paymentMethodTotals'] as Map)['Credit Card'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['paymentMethodTotals'] as Map)['TNG / GrabPay'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['paymentMethodTotals'] as Map)['ShopeePay'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Error & Security Log
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '4. Error & Security Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('Voids/Deleted Items')),
                        DataColumn(label: Text('Manual Overrides')),
                        DataColumn(label: Text('Refund Amount (RM)')),
                      ],
                      rows: [
                        ...staffData.map(
                          (staff) => DataRow(
                            cells: [
                              DataCell(Text(staff['userName'] as String)),
                              DataCell(
                                Text((staff['voids'] as int).toString()),
                              ),
                              DataCell(
                                Text((staff['overrides'] as int).toString()),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    staff['refunds'] as double,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataRow(
                          cells: [
                            const DataCell(
                              Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                (summary['totalVoids'] as int).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                (summary['totalOverrides'] as int).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  summary['totalRefunds'] as double,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dateTime = DateTime.parse(isoString);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }
}
