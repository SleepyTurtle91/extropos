import 'package:extropos/services/license_service.dart';
import 'package:extropos/services/tenant_service.dart';
import 'package:flutter/material.dart';

class CountersManagementScreen extends StatefulWidget {
  const CountersManagementScreen({super.key});

  @override
  State<CountersManagementScreen> createState() =>
      _CountersManagementScreenState();
}

class _CountersManagementScreenState extends State<CountersManagementScreen> {
  final List<String> _availableCounters = [];
  String? _assignedCounter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    setState(() => _isLoading = true);
    try {
      final counters = await TenantService.instance.getAvailableCounters();
      final assigned = LicenseService.instance.counterId;

      setState(() {
        _availableCounters.addAll(counters);
        _assignedCounter = assigned.isNotEmpty ? assigned : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading counters: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignCounter(String counterId) async {
    try {
      await TenantService.instance.assignCounter(counterId);
      setState(() => _assignedCounter = counterId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Counter assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning counter: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Counters'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_availableCounters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.computer, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Counters Available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No registered POS counters found',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableCounters.length,
      itemBuilder: (context, index) {
        final counterId = _availableCounters[index];
        final isAssigned = counterId == _assignedCounter;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              Icons.computer,
              color: isAssigned ? Colors.green : Colors.blue,
            ),
            title: Text('Counter ${index + 1}'),
            subtitle: Text('ID: $counterId'),
            trailing: isAssigned
                ? const Chip(
                    label: Text('Assigned'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                : ElevatedButton(
                    onPressed: () => _assignCounter(counterId),
                    child: const Text('Assign'),
                  ),
          ),
        );
      },
    );
  }
}
