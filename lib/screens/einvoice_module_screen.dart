import 'package:flutter/material.dart';
import 'package:extropos/models/einvoice/lhdn_config.dart';
import 'package:extropos/models/einvoice/submission.dart';
import 'package:extropos/models/einvoice/unconsolidated_receipt.dart';
import 'package:extropos/screens/submissions_screen.dart';
import 'package:extropos/screens/consolidate_screen.dart';
import 'package:extropos/screens/lhdn_config_dialog.dart';
import 'package:extropos/services/einvoice_business_logic_service.dart';
import 'package:extropos/services/einvoice_service.dart';

/// E-Invoice Module Main Screen (Layer C - Orchestration)
/// Routes between Submissions, Consolidate, and Config based on tab selection
/// Manages state and delegates business logic to Layer A services
class EInvoiceModuleScreen extends StatefulWidget {
  const EInvoiceModuleScreen({super.key});

  @override
  State<EInvoiceModuleScreen> createState() => _EInvoiceModuleScreenState();
}

class _EInvoiceModuleScreenState extends State<EInvoiceModuleScreen> {
  final _einvoiceService = EInvoiceService.instance;
  final _businessLogic = EInvoiceBusinessLogicService();

  final int _selectedTabIndex = 0;
  List<Submission> _submissions = [];
  final List<UnconsolidatedReceipt> _unconsolidatedReceipts = [];
  LhdnConfig _config = LhdnConfig();
  bool _isLoading = false;
  bool _isSyncing = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load config
      _config = _einvoiceService.config != null
          ? LhdnConfig(
              businessName: _einvoiceService.config!.businessName,
              tin: _einvoiceService.config!.tin,
              regNo: '', // Add if available in EInvoiceConfig
              clientId: _einvoiceService.config!.clientId,
              clientSecret: _einvoiceService.config!.clientSecret,
            )
          : LhdnConfig();

      // Load submissions
      if (_einvoiceService.isConfigured) {
        final docs = await _einvoiceService.getRecentDocuments();
        _submissions = docs
            .map((doc) => Submission(
                  id: doc['uuid'] ?? 'N/A',
                  date: doc['invoiceDate'] ?? 'N/A',
                  buyer: doc['customerName'] ?? 'Unknown',
        // Load submissions
        if (_einvoiceService.isConfigured) {
          final docs = await _einvoiceService.getRecentDocuments();
          _submissions = docs
              .map((doc) => Submission.fromJson(doc))
              .toList();

          // Sort by date (newest first)
          _submissions = EInvoiceBusinessLogicService.sortSubmissionsByDate(
            _submissions,
          );
        }

    /// Map API document status to display status
    /// Official MyInvois API values: Submitted, Valid, Invalid, Cancelled
    String getStatusDisplay(String apiStatus) {
      switch (apiStatus) {
        case 'Submitted':
          return 'Awaiting Validation';
        case 'Valid':
          return 'Validated';
        case 'Invalid':
          return 'Failed Validation';
        case 'Cancelled':
          return 'Cancelled';
        default:
          return apiStatus;
      }
    }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String mapDocumentStatus(String? status) {
    switch (status) {
      case 'valid':
        return 'Validated';
      case 'invalid':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  void handleSearchQueryChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void handleSubmitToLhdn() async {
    setState(() => _isSyncing = true);
    try {
      // Implementation: Submit consolidate receipts to LHDN
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipts submitted to LHDN')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void handleConsolodate() async {
    setState(() => _isSyncing = true);
    try {
      // Implementation: Consolidate receipts
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipts consolidated successfully')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Consolidation failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void handleConfigureClick() {
    showDialog(
      context: context,
      builder: (context) => LhdnConfigDialog(
        initialConfig: _config,
        onDismiss: () => Navigator.pop(context),
        onSave: (newConfig) {
          // Save config here
          setState(() => _config = newConfig);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuration saved')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('E-Invoice')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Get filtered submissions
    final filteredSubmissions =
        EInvoiceBusinessLogicService.filterSubmissions(
      _submissions,
      _searchQuery,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('E-Invoice Management'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Submissions'),
              Tab(icon: Icon(Icons.layers), text: 'Consolidate'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Submissions Tab
            SubmissionsScreen(
              submissions: filteredSubmissions,
              isSyncing: _isSyncing,
              onSearchQueryChanged: handleSearchQueryChanged,
              onSubmitToLhdnClick: handleSubmitToLhdn,
              onConfigureClick: handleConfigureClick,
            ),
            // Consolidate Tab
            ConsolidateScreen(
              unconsolidatedReceipts: _unconsolidatedReceipts,
              isConsolidating: _isSyncing,
              onConsolidateClick: handleConsolodate,
            ),
          ],
        ),
      ),
    );
  }
}
