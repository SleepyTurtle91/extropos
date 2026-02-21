import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Utility for generating QR code images for printing
class QRCodeGenerator {
  /// Generate a QR code image as bytes for thermal printer
  /// Returns PNG image bytes
  static Future<Uint8List?> generateQRImageBytes({
    required String data,
    int size = 200,
    int padding = 10,
  }) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (qrValidationResult.status != QrValidationStatus.valid) {
        return null;
      }

      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: Colors.black,
        gapless: true,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );

      // Create image with padding
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      // White background
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        paint,
      );

      // Draw QR in center with padding
      final qrSize = size - (padding * 2);
      painter.paint(
        canvas,
        Size(qrSize.toDouble(), qrSize.toDouble()),
      );
      canvas.translate(padding.toDouble(), padding.toDouble());

      final picture = pictureRecorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Generate QR code image for display (not for printing)
  static Widget buildQRWidget({
    required String data,
    double size = 200,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: true,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }
}
