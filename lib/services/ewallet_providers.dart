import 'dart:developer' as developer;

import 'package:extropos/services/ewallet_api_clients.dart';

abstract class EWalletProvider {
  Future<DynamicQRResult> createDynamicQR({
    required double amount,
    required String referenceId,
    required Map<String, dynamic> settings,
  });
}

class DynamicQRResult {
  final String qrData;
  final String transactionId;
  final DateTime? expiresAt;
  final bool isStaticFallback;

  DynamicQRResult({
    required this.qrData,
    required this.transactionId,
    this.expiresAt,
    this.isStaticFallback = false,
  });
}

class DuitNowProvider implements EWalletProvider {
  @override
  Future<DynamicQRResult> createDynamicQR({
    required double amount,
    required String referenceId,
    required Map<String, dynamic> settings,
  }) async {
    final merchantId = (settings['merchant_id'] as String?) ?? '';
    final useSandbox = (settings['use_sandbox'] as bool?) ?? true;
    final apiKey = (settings['api_key'] as String?) ?? '';
    final callbackUrl = (settings['callback_url'] as String?) ?? '';
    
    // Try real API if credentials provided
    if (apiKey.isNotEmpty && merchantId.isNotEmpty) {
      try {
        final client = DuitNowAPIClient(
          baseUrl: useSandbox ? 'https://sandbox-api.duitnow.my' : 'https://api.duitnow.my',
          apiKey: apiKey,
          useSandbox: useSandbox,
        );
        
        final response = await client.createDynamicQR(
          merchantId: merchantId,
          amount: amount,
          currency: 'MYR',
          referenceId: referenceId,
          callbackUrl: callbackUrl.isNotEmpty ? callbackUrl : null,
          expiryMinutes: 5,
        );
        
        developer.log('✅ DuitNow API: Generated dynamic QR (expires: ${response.expiresAt})');
        
        return DynamicQRResult(
          qrData: response.qrData,
          transactionId: response.transactionId,
          expiresAt: response.expiresAt,
          isStaticFallback: false,
        );
      } catch (e) {
        developer.log('⚠️ DuitNow API failed, using static QR: $e');
        // Fall through to static QR
      }
    }
    
    // Fallback: Generate static EMVCo QR
    final qrData = _buildEMVCoQR(
      merchantId: merchantId.isNotEmpty ? merchantId : 'STATIC_MERCHANT',
      amount: amount,
      referenceId: referenceId,
      sandbox: useSandbox,
    );
    
    return DynamicQRResult(
      qrData: qrData,
      transactionId: referenceId,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      isStaticFallback: true,
    );
  }
  
  String _buildEMVCoQR({
    required String merchantId,
    required double amount,
    required String referenceId,
    required bool sandbox,
  }) {
    final buffer = StringBuffer();
    
    // Payload Format Indicator (ID 00)
    buffer.write(_tlv('00', '01'));
    
    // Point of Initiation Method (ID 01) - 11=static, 12=dynamic
    buffer.write(_tlv('01', '12'));
    
    // Merchant Account (ID 26-51) - using 26 for DuitNow
    final merchantAcc = StringBuffer();
    merchantAcc.write(_tlv('00', sandbox ? 'MY.DUITNOW.SANDBOX' : 'MY.DUITNOW'));
    merchantAcc.write(_tlv('01', merchantId));
    buffer.write(_tlv('26', merchantAcc.toString()));
    
    // Transaction Currency (ID 53) - 458 = MYR
    buffer.write(_tlv('53', '458'));
    
    // Transaction Amount (ID 54)
    buffer.write(_tlv('54', amount.toStringAsFixed(2)));
    
    // Country Code (ID 58) - MY = Malaysia
    buffer.write(_tlv('58', 'MY'));
    
    // Merchant Name (ID 59)
    buffer.write(_tlv('59', 'DuitNow Merchant'));
    
    // Merchant City (ID 60)
    buffer.write(_tlv('60', 'Kuala Lumpur'));
    
    // Additional Data (ID 62) - includes reference
    final additionalData = StringBuffer();
    additionalData.write(_tlv('05', referenceId)); // Reference Label
    buffer.write(_tlv('62', additionalData.toString()));
    
    // CRC Placeholder
    buffer.write('6304');
    
    // Calculate CRC16-CCITT
    final crc = _calculateCRC16(buffer.toString());
    buffer.write(crc.toRadixString(16).toUpperCase().padLeft(4, '0'));
    
    return buffer.toString();
  }
  
  String _tlv(String tag, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$tag$length$value';
  }
  
  int _calculateCRC16(String data) {
    int crc = 0xFFFF;
    final bytes = data.codeUnits;
    
    for (final byte in bytes) {
      crc ^= byte << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
      }
    }
    
    return crc & 0xFFFF;
  }
}

class PlaceholderProvider implements EWalletProvider {
  @override
  Future<DynamicQRResult> createDynamicQR({
    required double amount,
    required String referenceId,
    required Map<String, dynamic> settings,
  }) async {
    // Generic placeholder payload
    final provider = (settings['provider'] as String?) ?? 'provider';
    final mid = (settings['merchant_id'] as String?) ?? 'MERCHANT-LOCAL';
    final qrData = 'QR|PROVIDER=$provider|MID=$mid|AMT=${amount.toStringAsFixed(2)}|REF=$referenceId';
    
    return DynamicQRResult(
      qrData: qrData,
      transactionId: referenceId,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      isStaticFallback: true,
    );
  }
}

class EWalletProviderRegistry {
  static EWalletProvider forSettings(Map<String, dynamic> settings) {
    final p = (settings['provider'] as String?)?.toLowerCase() ?? 'duitnow';
    switch (p) {
      case 'duitnow':
        return DuitNowProvider();
      case 'grabpay':
      case 'tng':
      case 'boost':
      case 'shopeepay':
        return PlaceholderProvider();
      default:
        return PlaceholderProvider();
    }
  }
}
