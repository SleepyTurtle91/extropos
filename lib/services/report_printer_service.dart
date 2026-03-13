import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart' as pos_printer;
import 'package:extropos/services/printer_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_io/io.dart';

part 'report_printer_service_thermal.dart';
part 'report_printer_service_pdf.dart';

/// Service for generating and printing sales reports in various formats
class ReportPrinterService {
  static final ReportPrinterService _instance = ReportPrinterService._internal();
  factory ReportPrinterService() => _instance;
  ReportPrinterService._internal();
  static ReportPrinterService get instance => _instance;

  Future<void> printThermal({
    required String thermalText,
    required int paperWidth,
  }) async {
    // Logic moved to caller or specific platform service to avoid context
    developer.log('Thermal report ready for printing: ${thermalText.length} chars');
  }
}
