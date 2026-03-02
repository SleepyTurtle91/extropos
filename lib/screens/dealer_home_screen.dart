import 'package:extropos/services/license_key_generator.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

part 'dealer_home_screen_ui.dart';
part 'dealer_home_screen_dialogs.dart';

/// Dealer Portal Home Screen
/// For dealer registration and tenant management
class DealerHomeScreen extends StatefulWidget {
  const DealerHomeScreen({super.key});

  @override
  State<DealerHomeScreen> createState() => _DealerHomeScreenState();
}

class _DealerHomeScreenState extends State<DealerHomeScreen> {
  Future<String> _validateTestLicense(String key) async {
    try {
      // Validate key format and checksum
      final isValid = LicenseKeyGenerator.validateKey(key);

      if (!isValid) {
        return '❌ Invalid License Key\n\nThe license key format or checksum is invalid.';
      }

      // Get license details
      final licenseType = LicenseKeyGenerator.getLicenseType(key);
      final expiryDate = LicenseKeyGenerator.getExpiryDate(key);
      final daysRemaining = LicenseKeyGenerator.getDaysRemaining(key);
      final isExpired = LicenseKeyGenerator.isExpired(key);

      if (licenseType == null) {
        return '❌ Invalid License Key\n\nCould not determine license type';
      }

      String message = '✅ Valid License Key\n\n';
      message += 'License Type: ${licenseType.name.toUpperCase()}\n';

      if (licenseType != LicenseType.lifetime) {
        message +=
            'Expiry Date: ${expiryDate?.toString().split(' ')[0] ?? 'N/A'}\n';

        if (isExpired) {
          message += 'Status: ❌ EXPIRED\n';
          message += 'Days Past Expiry: ${daysRemaining?.abs() ?? 0}';
        } else {
          message += 'Status: ✅ ACTIVE\n';
          message += 'Days Remaining: ${daysRemaining ?? 0}';
        }
      } else {
        message += 'Status: ✅ LIFETIME LICENSE';
      }

      return message;
    } catch (e) {
      return '❌ Validation Error\n\n$e';
    }
  }
}
