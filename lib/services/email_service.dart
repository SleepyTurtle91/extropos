import 'dart:io';
import 'package:extropos/models/business_info_model.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Service for sending emails using SMTP
class EmailService {
  static final EmailService instance = EmailService._init();
  EmailService._init();

  /// Send an email using configured SMTP settings
  Future<bool> sendEmail({
    required String recipient,
    required String subject,
    required String body,
    bool isHtml = false,
    List<File>? attachments,
  }) async {
    final businessInfo = BusinessInfo.instance;

    if (businessInfo.smtpHost == null || businessInfo.smtpUsername == null || businessInfo.smtpPassword == null) {
      print('🔥 SMTP not configured');
      return false;
    }

    final smtpServer = SmtpServer(
      businessInfo.smtpHost!,
      port: businessInfo.smtpPort ?? 587,
      username: businessInfo.smtpUsername,
      password: businessInfo.smtpPassword,
      ssl: businessInfo.smtpUseSsl ?? false,
    );

    final message = Message()
      ..from = Address(businessInfo.smtpUsername!, businessInfo.businessName)
      ..recipients.add(recipient)
      ..subject = subject
      ..attachments.addAll(attachments?.map((f) => FileAttachment(f)) ?? []);

    if (isHtml) {
      message.html = body;
    } else {
      message.text = body;
    }

    try {
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent: ${sendReport.toString()}');
      return true;
    } on MailerException catch (e) {
      print('🔥 Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('🔥 General email error: $e');
      return false;
    }
  }

  /// Send receipt email to customer
  Future<bool> sendReceiptEmail({
    required String recipient,
    required String receiptNumber,
    required String htmlContent,
    File? pdfAttachment,
  }) async {
    return await sendEmail(
      recipient: recipient,
      subject: 'Receipt for Order #$receiptNumber - ${BusinessInfo.instance.businessName}',
      body: htmlContent,
      isHtml: true,
      attachments: pdfAttachment != null ? [pdfAttachment] : null,
    );
  }
}
