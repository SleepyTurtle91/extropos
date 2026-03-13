import 'package:extropos/models/receipt_settings_model.dart';

part 'receipt_generator_retail.dart';
part 'receipt_generator_kitchen.dart';

/// Receipt type for dual receipt functionality
enum ReceiptType {
  customer,  // Simplified receipt for customer
  merchant,  // Detailed receipt for merchant records
}
