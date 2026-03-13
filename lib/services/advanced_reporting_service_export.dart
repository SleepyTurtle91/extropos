part of 'advanced_reporting_service.dart';

extension AdvancedReportingServiceExport on AdvancedReportingService {
  // ==================== EMAIL DELIVERY ====================

  /// Execute scheduled report and send via email
  Future<bool> executeScheduledReport(ScheduledReport report) async {
    try {
      final emailService = EmailTemplateService.instance;
      final businessInfo = BusinessInfo.instance;

      // Check if business email is configured
      if (businessInfo.email.isEmpty) {
        print('Cannot send report: Business email not configured');
        return false;
      }

      // Generate report data based on type
      final reportData = await _generateReportData(
        report.reportType,
        report.period,
      );

      // Generate export files if formats specified
      List<String> attachmentFilenames = [];
      if (report.exportFormats.isNotEmpty) {
        // Note: Export functionality can be added when needed
        // For now, reports are sent as HTML email only
        attachmentFilenames = report.exportFormats.map((format) {
          return '${report.name}_${_formatDate(DateTime.now())}.${format.toString().split('.').last.toLowerCase()}';
        }).toList();
      }

      // Generate HTML email
      final htmlBody = emailService.generateScheduledReportEmail(
        reportType: report.reportType.toString().split('.').last,
        reportName: report.name,
        period: report.period,
        reportData: reportData,
        attachmentFilenames: attachmentFilenames,
      );

      // Send email to all recipients using SMTP
      bool allSucceeded = true;
      for (final recipient in report.recipientEmails) {
        final success = await _sendEmailViaSMTP(
          from: businessInfo.email,
          to: recipient,
          subject: '${report.name} - ${report.period.label}',
          htmlBody: htmlBody,
        );

        if (!success) {
          allSucceeded = false;
          print('Failed to send email to $recipient');
        }
      }

      // Update next run time and last run time
      final updatedReport = report.copyWith(
        lastRun: DateTime.now(),
        nextRun: _calculateNextRun(DateTime.now(), report.frequency),
      );
      await updateScheduledReport(updatedReport);

      return allSucceeded;
    } catch (e) {
      print('Error executing scheduled report: $e');
      return false;
    }
  }

  /// Send email via SMTP (using generic SMTP server)
  Future<bool> _sendEmailViaSMTP({
    required String from,
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    try {
      // Get business info for SMTP configuration
      final businessInfo = BusinessInfo.instance;

      // SMTP configuration from BusinessInfo
      final smtpServer = SmtpServer(
        businessInfo.smtpHost ?? 'smtp.gmail.com',
        port: businessInfo.smtpPort ?? 587,
        username: businessInfo.smtpUsername ?? from,
        password: businessInfo.smtpPassword ?? '',
        ignoreBadCertificate: false,
        ssl: businessInfo.smtpUseSsl ?? false,
        allowInsecure: true,
      );

      // Create message
      final message = Message()
        ..from = Address(from, BusinessInfo.instance.businessName)
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlBody;

      // Send message
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Error sending email via SMTP: $e');
      return false;
    }
  }

  /// Format date for filename
  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// Generate report data based on report type
  Future<Map<String, dynamic>> _generateReportData(
    ReportType reportType,
    ReportPeriod period,
  ) async {
    // This is a placeholder - in production, this would query actual sales data
    // from the database based on the period
    switch (reportType) {
      case ReportType.salesSummary:
        return {
          'totalSales': 1234.56,
          'transactionCount': 45,
          'taxAmount': 123.45,
        };
      case ReportType.productSales:
        return {
          'topProducts': [
            {'name': 'Product A', 'quantity': 10, 'revenue': 100.0},
            {'name': 'Product B', 'quantity': 8, 'revenue': 80.0},
          ],
        };
      case ReportType.employeePerformance:
        return {
          'employees': [
            {'name': 'John', 'totalSales': 500.0, 'transactionCount': 20},
            {'name': 'Jane', 'totalSales': 450.0, 'transactionCount': 18},
          ],
        };
      case ReportType.profitLoss:
        return {'revenue': 1000.0, 'costs': 600.0};
      default:
        return {};
    }
  }
}
