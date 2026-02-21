import 'package:extropos/services/reports_test_data_generator.dart';
import 'package:flutter/material.dart';

/// Screen to generate test data for reports dashboard testing
class GenerateTestDataScreen extends StatefulWidget {
  const GenerateTestDataScreen({super.key});

  @override
  State<GenerateTestDataScreen> createState() => _GenerateTestDataScreenState();
}

class _GenerateTestDataScreenState extends State<GenerateTestDataScreen> {
  bool _isGenerating = false;
  String _statusMessage = '';
  int _daysBack = 30;
  int _ordersPerDay = 10;

  Future<void> _generateData() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating test data...';
    });

    try {
      await ReportsTestDataGenerator.instance.generateSalesData(
        daysBack: _daysBack,
        ordersPerDay: _ordersPerDay,
      );

      await ReportsTestDataGenerator.instance.printSalesSummary();

      setState(() {
        _statusMessage =
            '✅ Successfully generated ${_daysBack * _ordersPerDay} orders!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _clearData() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Clearing test data...';
    });

    try {
      await ReportsTestDataGenerator.instance.clearTestData();

      setState(() {
        _statusMessage = '✅ Test data cleared!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Test Data'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reports Dashboard Test Data Generator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate realistic sales data to test the Modern Reports Dashboard',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Days back slider
            Text(
              'Days of History: $_daysBack days',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _daysBack.toDouble(),
              min: 7,
              max: 90,
              divisions: 83,
              label: '$_daysBack days',
              onChanged: _isGenerating
                  ? null
                  : (value) {
                      setState(() {
                        _daysBack = value.toInt();
                      });
                    },
            ),
            const SizedBox(height: 16),

            // Orders per day slider
            Text(
              'Orders Per Day: $_ordersPerDay orders',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _ordersPerDay.toDouble(),
              min: 5,
              max: 50,
              divisions: 45,
              label: '$_ordersPerDay orders',
              onChanged: _isGenerating
                  ? null
                  : (value) {
                      setState(() {
                        _ordersPerDay = value.toInt();
                      });
                    },
            ),
            const SizedBox(height: 32),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What will be generated:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('• Total Orders: ~${_daysBack * _ordersPerDay}'),
                  Text('• Date Range: Last $_daysBack days'),
                  Text('• Daily Orders: ~$_ordersPerDay (varies ±2)'),
                  const Text('• 75% completed, 25% cancelled'),
                  const Text('• Mixed payment methods (Cash, Card, E-Wallet)'),
                  const Text('• Mixed order types (Retail, Cafe, Restaurant)'),
                  const Text('• Random products from 4 categories'),
                  const Text('• Realistic time distribution (9 AM - 9 PM)'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Generate button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateData,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_chart),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate Test Data',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clear button
            OutlinedButton.icon(
              onPressed: _isGenerating ? null : _clearData,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear Test Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('Error')
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error')
                        ? Colors.red.shade900
                        : Colors.green.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
