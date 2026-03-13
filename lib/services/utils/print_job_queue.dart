import 'dart:async';
import 'dart:developer' as dev;

/// Status of a queued print job.
enum PrintJobStatus { pending, printing, completed, failed }

/// A single queued print job.
class PrintJob {
  final String id;
  final String label;
  final Future<bool> Function() execute;
  PrintJobStatus status;
  String? errorMessage;

  PrintJob({
    required this.id,
    required this.label,
    required this.execute,
    this.status = PrintJobStatus.pending,
  });
}

/// Non-blocking, sequential print-job queue.
///
/// Callers enqueue a [PrintJob] and receive a [Future] that resolves when
/// the job finishes (or fails). The UI is never blocked — the queue drains
/// in the background using chained Futures.
///
/// Usage:
/// ```dart
/// final queue = PrintJobQueue.instance;
/// final success = await queue.enqueue(PrintJob(
///   id: transactionId,
///   label: 'Receipt #123',
///   execute: () => printerService.printReceipt(receiptData, printer),
/// ));
/// ```
class PrintJobQueue {
  PrintJobQueue._();
  static final PrintJobQueue instance = PrintJobQueue._();

  final List<PrintJob> _jobs = [];
  bool _isProcessing = false;

  // Notifies listeners of job-status changes (status + id).
  final _statusController =
      StreamController<PrintJob>.broadcast();

  /// Stream of job status events, suitable for UI feedback.
  Stream<PrintJob> get statusStream => _statusController.stream;

  /// All jobs in the queue (read-only view).
  List<PrintJob> get jobs => List.unmodifiable(_jobs);

  /// Number of jobs waiting to print.
  int get pendingCount =>
      _jobs.where((j) => j.status == PrintJobStatus.pending).length;

  /// Enqueue [job] and start the queue drain if it is idle.
  ///
  /// Returns a [Future<bool>] that completes with `true` on success,
  /// `false` on failure. The caller is NOT blocked while other jobs run.
  Future<bool> enqueue(PrintJob job) {
    _jobs.add(job);
    _statusController.add(job);
    final completer = Completer<bool>();

    // Pair a completer with this job so we can resolve it later.
    _completers[job.id] = completer;

    if (!_isProcessing) {
      _drain();
    }

    return completer.future;
  }

  final Map<String, Completer<bool>> _completers = {};

  Future<void> _drain() async {
    _isProcessing = true;
    while (true) {
      final pending = _jobs
          .where((j) => j.status == PrintJobStatus.pending)
          .toList();
      if (pending.isEmpty) break;

      final job = pending.first;
      job.status = PrintJobStatus.printing;
      _notify(job);

      bool success = false;
      try {
        success = await job.execute();
        job.status =
            success ? PrintJobStatus.completed : PrintJobStatus.failed;
        if (!success) job.errorMessage = 'Print returned false';
      } catch (e, st) {
        job.status = PrintJobStatus.failed;
        job.errorMessage = e.toString();
        dev.log('PrintJobQueue: job ${job.id} failed', error: e, stackTrace: st);
      }

      _notify(job);

      final completer = _completers.remove(job.id);
      completer?.complete(success);
    }
    _isProcessing = false;
  }

  void _notify(PrintJob job) {
    if (!_statusController.isClosed) {
      _statusController.add(job);
    }
  }

  /// Remove all completed / failed jobs from the history list.
  void clearHistory() {
    _jobs.removeWhere(
      (j) =>
          j.status == PrintJobStatus.completed ||
          j.status == PrintJobStatus.failed,
    );
  }

  /// Cancel a pending job by id. Returns true if found and removed.
  bool cancel(String jobId) {
    final idx = _jobs.indexWhere(
      (j) => j.id == jobId && j.status == PrintJobStatus.pending,
    );
    if (idx == -1) return false;
    final job = _jobs.removeAt(idx);
    job.status = PrintJobStatus.failed;
    job.errorMessage = 'Cancelled';
    _completers.remove(jobId)?.complete(false);
    return true;
  }

  /// Dispose the queue (call on app shutdown).
  void dispose() {
    _statusController.close();
  }
}
