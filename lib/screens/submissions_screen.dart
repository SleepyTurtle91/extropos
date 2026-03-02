import 'package:flutter/material.dart';
import 'package:extropos/models/einvoice/submission.dart';

/// E-Invoice Submissions Screen
/// Displays history of all invoices submitted to LHDN MyInvois portal
/// Module: feature:einvoice
class SubmissionsScreen extends StatefulWidget {
  final List<Submission> submissions;
  final bool isSyncing;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onSubmitToLhdnClick;
  final VoidCallback onConfigureClick;

  const SubmissionsScreen({
    super.key,
    required this.submissions,
    required this.isSyncing,
    required this.onSearchQueryChanged,
    required this.onSubmitToLhdnClick,
    required this.onConfigureClick,
  });

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E-Invoice Submissions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B), // slate-800
                  ),
                ),
                const Text(
                  'History of all invoices submitted to LHDN MyInvois portal.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B), // slate-500
                  ),
                ),
                const SizedBox(height: 16),

                // Actions Row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _searchController,
                          onChanged: widget.onSearchQueryChanged,
                          decoration: InputDecoration(
                            hintText: 'Search UIN or Buyer...',
                            prefixIcon: const Icon(Icons.search),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed:
                          widget.isSyncing ? null : widget.onSubmitToLhdnClick,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5), // indigo-600
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF4F46E5).withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: widget.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, size: 16),
                      label: const Text('Submit to LHDN'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: widget.onConfigureClick,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Configure'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Submissions List
          Expanded(
            child: widget.submissions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No submissions found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: widget.submissions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return SubmissionItemRow(
                          submission: widget.submissions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Individual submission row widget
class SubmissionItemRow extends StatelessWidget {
  final Submission submission;

  const SubmissionItemRow({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    final isValidated = submission.status == 'Validated';
    final statusColor =
        isValidated ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final statusBg =
        isValidated ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);

    return Card(
      color: Colors.white,
      elevation: 1,
      surfaceTintColor: Colors.transparent, // Prevents Material 3 tinting over white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    submission.date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.buyer,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'UIN: ${submission.uin}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${submission.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      submission.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
