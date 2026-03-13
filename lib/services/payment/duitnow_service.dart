import 'package:extropos/services/utils/rounding_service.dart';

/// Pure logic service for generating DuitNow QR EMVCo payload strings.
///
/// This service follows the Merchant Presented Mode (MPM) TLV format and
/// appends a CRC16-CCITT checksum (`ID=63`).
///
/// It is intentionally UI-free (Layer A).
abstract final class DuitNowService {
  static const String _payloadFormatIndicator = '01';
  static const String _poiStatic = '11';
  static const String _poiDynamic = '12';
  static const String _countryCodeMalaysia = 'MY';
  static const String _currencyCodeMyr = '458';
  static const String _merchantAccountInfoId = '26';

  /// PayNet / DuitNow GUI used for merchant account info template.
  ///
  /// Reference commonly used in Malaysian EMV payloads.
  static const String _duitNowGui = 'A0000006150001';

  /// Generate a dynamic DuitNow payload with a required amount.
  ///
  /// The amount is first rounded via [RoundingService.roundCash] to ensure
  /// BNM-compatible totals.
  static String generateDynamicQr({
    required String merchantId,
    required double amount,
    String? reference,
    String merchantName = 'EXTROPOS',
    String merchantCity = 'KUALA LUMPUR',
    String merchantCategoryCode = '0000',
  }) {
    if (merchantId.trim().isEmpty) {
      throw ArgumentError('merchantId cannot be empty');
    }
    if (amount <= 0) {
      throw ArgumentError('amount must be greater than 0 for dynamic QR');
    }

    final roundedAmount = RoundingService.roundCash(amount);
    return _buildPayload(
      merchantId: merchantId,
      amount: roundedAmount,
      reference: reference,
      merchantName: merchantName,
      merchantCity: merchantCity,
      merchantCategoryCode: merchantCategoryCode,
      isDynamic: true,
    );
  }

  /// Generate a static DuitNow payload (no embedded amount).
  static String generateStaticQr({
    required String merchantId,
    String? reference,
    String merchantName = 'EXTROPOS',
    String merchantCity = 'KUALA LUMPUR',
    String merchantCategoryCode = '0000',
  }) {
    if (merchantId.trim().isEmpty) {
      throw ArgumentError('merchantId cannot be empty');
    }

    return _buildPayload(
      merchantId: merchantId,
      amount: null,
      reference: reference,
      merchantName: merchantName,
      merchantCity: merchantCity,
      merchantCategoryCode: merchantCategoryCode,
      isDynamic: false,
    );
  }

  /// Validates whether [payload] has a correct CRC and basic EMV structure.
  static bool isValidPayload(String payload) {
    if (payload.length < 8) return false;
    if (!payload.contains('6304')) return false;

    final idx = payload.lastIndexOf('6304');
    if (idx == -1 || idx + 8 > payload.length) return false;

    final bodyWithCrcId = payload.substring(0, idx + 4);
    final existingCrc = payload.substring(idx + 4, idx + 8).toUpperCase();
    final computed = _crc16Ccitt(bodyWithCrcId);
    return existingCrc == computed;
  }

  static String _buildPayload({
    required String merchantId,
    required String? reference,
    required String merchantName,
    required String merchantCity,
    required String merchantCategoryCode,
    required bool isDynamic,
    required double? amount,
  }) {
    final merchantNameSafe = _sanitizeText(merchantName, maxLength: 25);
    final merchantCitySafe = _sanitizeText(merchantCity, maxLength: 15);
    final merchantIdSafe = _sanitizeText(merchantId, maxLength: 30);
    final referenceSafe = _sanitizeText(reference ?? '', maxLength: 25);
    final mccSafe = _sanitizeDigits(merchantCategoryCode, maxLength: 4)
        .padLeft(4, '0');

    final merchantAccountInfo = _buildMerchantAccountInfo(merchantIdSafe);
    final additionalData = _buildAdditionalData(referenceSafe);

    final buffer = StringBuffer()
      ..write(_tlv('00', _payloadFormatIndicator))
      ..write(_tlv('01', isDynamic ? _poiDynamic : _poiStatic))
      ..write(_tlv(_merchantAccountInfoId, merchantAccountInfo))
      ..write(_tlv('52', mccSafe))
      ..write(_tlv('53', _currencyCodeMyr));

    if (amount != null) {
      buffer.write(_tlv('54', amount.toStringAsFixed(2)));
    }

    buffer
      ..write(_tlv('58', _countryCodeMalaysia))
      ..write(_tlv('59', merchantNameSafe))
      ..write(_tlv('60', merchantCitySafe));

    if (additionalData.isNotEmpty) {
      buffer.write(_tlv('62', additionalData));
    }

    final payloadWithoutCrc = buffer.toString();
    final payloadWithCrcTag = '${payloadWithoutCrc}6304';
    final crc = _crc16Ccitt(payloadWithCrcTag);
    return '$payloadWithCrcTag$crc';
  }

  static String _buildMerchantAccountInfo(String merchantId) {
    final template = StringBuffer()
      ..write(_tlv('00', _duitNowGui))
      ..write(_tlv('01', merchantId));
    return template.toString();
  }

  static String _buildAdditionalData(String reference) {
    if (reference.isEmpty) return '';
    return _tlv('01', reference);
  }

  static String _tlv(String id, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$id$len$value';
  }

  static String _sanitizeText(String value, {required int maxLength}) {
    final cleaned = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
    if (cleaned.isEmpty) return 'N/A';
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  static String _sanitizeDigits(String value, {required int maxLength}) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return digits.length > maxLength
        ? digits.substring(0, maxLength)
        : digits;
  }

  /// CRC16-CCITT (poly 0x1021, init 0xFFFF), result as 4-char uppercase hex.
  static String _crc16Ccitt(String data) {
    var crc = 0xFFFF;
    for (final codeUnit in data.codeUnits) {
      crc ^= (codeUnit << 8);
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
