import 'package:extropos/models/business_info_model.dart';

class FormattingService {
  FormattingService._();

  static String currency(num value) {
    final info = BusinessInfo.instance;
    return '${info.currencySymbol} ${value.toStringAsFixed(2)}';
  }

  static String formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  static String formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
