import 'package:extropos/models/business_session_model.dart';
import 'package:extropos/services/business_session_service.dart';
import 'package:extropos/widgets/business_session_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BusinessSessionsScreen extends StatefulWidget {
  const BusinessSessionsScreen({super.key});

  @override
  State<BusinessSessionsScreen> createState() => _BusinessSessionsScreenState();
}

class _BusinessSessionsScreenState extends State<BusinessSessionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Sessions'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Consumer<BusinessSessionService>(
        builder: (context, sessionService, _) {
          final isOpen = sessionService.isBusinessOpen;
          final currentSession = sessionService.currentSession;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard(isOpen, currentSession),
              const SizedBox(height: 24),
              const Text(
                'Session History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('History view coming soon'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bool isOpen, BusinessSession? session) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOpen ? Icons.check_circle : Icons.store_mall_directory,
                  color: isOpen ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen ? 'Business is Open' : 'Business is Closed',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOpen && session != null)
                      Text(
                        'Opened: ${session.openDate.toString().substring(0, 16)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isOpen) ...[
              _buildInfoRow(
                'Opening Cash',
                'RM ${session?.openingCash.toStringAsFixed(2) ?? "0.00"}',
              ),
              if (session?.notes != null && session!.notes!.isNotEmpty)
                _buildInfoRow('Notes', session.notes!),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCloseBusinessDialog(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close Business Day'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Start a new business day to begin processing transactions.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showOpenBusinessDialog(context),
                  icon: const Icon(Icons.store),
                  label: const Text('Open Business Day'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _showOpenBusinessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const OpenBusinessDialog(),
    );
  }

  Future<void> _showCloseBusinessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const CloseBusinessDialog(),
    );
  }
}
