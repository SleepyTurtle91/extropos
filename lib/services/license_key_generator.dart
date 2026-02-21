import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// License type enum
enum LicenseType { trial1Month, trial3Month, lifetime }

/// License key format: EXTRO-XXXX-XXXX-XXXX-XXXX
///
/// Structure:
/// - Part 1: EXTRO (constant prefix)
/// - Part 2: License type code (4 chars)
/// - Part 3: Expiry date encoded (4 chars) or "LIFE" for lifetime
/// - Part 4: Device/instance ID (4 chars) - "0000" for universal keys
/// - Part 5: Checksum (4 chars)
class LicenseKeyGenerator {
  static const String _prefix = 'EXTRO';
  static const String _secret =
      'FlutterPOS-License-Secret-2025'; // Secret for HMAC

  /// Type codes for different license types
  static const Map<LicenseType, String> _typeCodes = {
    LicenseType.trial1Month: '1MTR',
    LicenseType.trial3Month: '3MTR',
    LicenseType.lifetime: 'LIFE',
  };

  /// Generate a license key
  static String generateKey(LicenseType type, {String? deviceId}) {
    final typeCode = _typeCodes[type]!;
    final expiryPart = _generateExpiryPart(type);
    final devicePart = deviceId?.substring(0, 4).toUpperCase() ?? '0000';

    // Create base key without checksum
    final baseKey = '$typeCode$expiryPart$devicePart';

    // Generate checksum
    final checksum = _generateChecksum(baseKey);

    // Format: EXTRO-XXXX-XXXX-XXXX-XXXX
    return '$_prefix-$typeCode-$expiryPart-$devicePart-$checksum';
  }

  /// Generate multiple keys
  static List<String> generateKeys(
    LicenseType type,
    int count, {
    String? deviceId,
  }) {
    final keys = <String>[];
    for (int i = 0; i < count; i++) {
      // Add random component to device ID if generating multiple keys
      final device = deviceId ?? _generateRandomDeviceId();
      keys.add(generateKey(type, deviceId: device));
    }
    return keys;
  }

  /// Validate a license key
  static bool validateKey(String key) {
    try {
      // Remove spaces and convert to uppercase
      final cleanKey = key
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .toUpperCase();

      // Check format: EXTRO + 16 chars
      if (cleanKey.length != 21) return false;
      if (!cleanKey.startsWith(_prefix)) return false;

      // Extract parts
      final parts = key.split('-');
      if (parts.length != 5) return false;

      final typeCode = parts[1];
      final expiryPart = parts[2];
      final devicePart = parts[3];
      final providedChecksum = parts[4];

      // Verify type code
      if (!_typeCodes.values.contains(typeCode)) return false;

      // Verify checksum
      final baseKey = '$typeCode$expiryPart$devicePart';
      final expectedChecksum = _generateChecksum(baseKey);

      if (providedChecksum != expectedChecksum) return false;

      // Check expiry for trial licenses
      if (typeCode != 'LIFE') {
        final expiryDate = _decodeExpiryDate(expiryPart);
        if (expiryDate == null) return false;

        // Key is valid if not expired
        if (DateTime.now().isAfter(expiryDate)) {
          return false; // Expired
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get license type from key
  static LicenseType? getLicenseType(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 5) return null;

      final typeCode = parts[1];
      return _typeCodes.entries
          .firstWhere((entry) => entry.value == typeCode)
          .key;
    } catch (e) {
      return null;
    }
  }

  /// Get expiry date from key (null for lifetime)
  static DateTime? getExpiryDate(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 5) return null;

      final typeCode = parts[1];
      if (typeCode == 'LIFE') return null; // Lifetime, no expiry

      final expiryPart = parts[2];
      return _decodeExpiryDate(expiryPart);
    } catch (e) {
      return null;
    }
  }

  /// Get days remaining (null for lifetime, negative if expired)
  static int? getDaysRemaining(String key) {
    final expiryDate = getExpiryDate(key);
    if (expiryDate == null) return null; // Lifetime

    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  /// Check if key is expired
  static bool isExpired(String key) {
    if (getLicenseType(key) == LicenseType.lifetime) return false;

    final daysRemaining = getDaysRemaining(key);
    return daysRemaining != null && daysRemaining < 0;
  }

  /// Generate expiry part based on license type
  static String _generateExpiryPart(LicenseType type) {
    if (type == LicenseType.lifetime) {
      return 'LIFE';
    }

    // Calculate expiry date
    final now = DateTime.now();
    final expiryDate = type == LicenseType.trial1Month
        ? now.add(const Duration(days: 30))
        : now.add(const Duration(days: 90));

    // Encode as base36 (compact representation)
    // Format: YYMM (e.g., 2501 = January 2025)
    final year = expiryDate.year % 100; // Last 2 digits
    final month = expiryDate.month;
    final day = expiryDate.day;

    // Encode as 4 characters: YY + MM + DD in base36
    final encoded = (year * 10000 + month * 100 + day)
        .toRadixString(36)
        .toUpperCase();
    return encoded.padLeft(4, '0');
  }

  /// Decode expiry date from encoded part
  static DateTime? _decodeExpiryDate(String encoded) {
    try {
      if (encoded == 'LIFE') return null;

      final value = int.parse(encoded, radix: 36);
      final year = 2000 + (value ~/ 10000);
      final month = (value % 10000) ~/ 100;
      final day = value % 100;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Generate checksum using HMAC-SHA256
  static String _generateChecksum(String data) {
    final key = utf8.encode(_secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    // Take first 3 bytes and convert to base36
    final checksum = digest.bytes
        .sublist(0, 3)
        .fold(0, (sum, byte) => sum * 256 + byte);

    // Convert to base36 and take exactly 4 characters
    final checksumStr = checksum.toRadixString(36).toUpperCase();
    // Take last 4 characters if longer, pad if shorter
    if (checksumStr.length >= 4) {
      return checksumStr.substring(checksumStr.length - 4);
    }
    return checksumStr.padLeft(4, '0');
  }

  /// Generate random device ID
  static String _generateRandomDeviceId() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Get license type display name
  static String getLicenseTypeName(LicenseType type) {
    switch (type) {
      case LicenseType.trial1Month:
        return '1 Month Trial';
      case LicenseType.trial3Month:
        return '3 Month Trial';
      case LicenseType.lifetime:
        return 'Lifetime License';
    }
  }

  /// Get license duration in days
  static int getLicenseDuration(LicenseType type) {
    switch (type) {
      case LicenseType.trial1Month:
        return 30;
      case LicenseType.trial3Month:
        return 90;
      case LicenseType.lifetime:
        return -1; // Unlimited
    }
  }

  /// Format key for display (with dashes)
  static String formatKey(String key) {
    final cleaned = key.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (cleaned.length != 21) return key;

    return '${cleaned.substring(0, 5)}-${cleaned.substring(5, 9)}-${cleaned.substring(9, 13)}-${cleaned.substring(13, 17)}-${cleaned.substring(17, 21)}';
  }
}
