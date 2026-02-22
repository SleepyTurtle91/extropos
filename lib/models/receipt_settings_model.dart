class ReceiptSettings {
  final String headerText;
  final String footerText;
  final bool showLogo;
  final bool showDateTime;
  final bool showOrderNumber;
  final bool showCashierName;
  final bool showTaxBreakdown;
  final bool showServiceChargeBreakdown;
  final bool showThankYouMessage;
  final bool showTaxId;
  final String taxIdText;
  final bool showWifiDetails;
  final String wifiDetails;
  final bool showBarcode;
  final String barcodeData;
  final bool showQrCode;
  final String qrData;
  final bool autoPrint;
  final ReceiptPaperSize paperSize;
  final int paperWidth; // in mm
  final int fontSize;
  final String thankYouMessage;
  final String termsAndConditions;

  // Kitchen Docket Template Settings
  final String kitchenHeaderText;
  final String kitchenFooterText;
  final bool kitchenShowDateTime;
  final bool kitchenShowTable;
  final bool kitchenShowOrderNumber;
  final bool kitchenShowModifiers;
  final int kitchenFontSize;
  final KitchenTemplateStyle kitchenTemplateStyle;

  ReceiptSettings({
    this.headerText = 'ExtroPOS',
    this.footerText = 'Thank you for your business!',
    this.showLogo = true,
    this.showDateTime = true,
    this.showOrderNumber = true,
    this.showCashierName = true,
    this.showTaxBreakdown = true,
    this.showServiceChargeBreakdown = true,
    this.showThankYouMessage = true,
    this.showTaxId = true,
    this.taxIdText = '',
    this.showWifiDetails = false,
    this.wifiDetails = '',
    this.showBarcode = false,
    this.barcodeData = '',
    this.showQrCode = false,
    this.qrData = '',
    this.autoPrint = true,
    this.paperSize = ReceiptPaperSize.mm80,
    this.paperWidth = 80,
    this.fontSize = 12,
    this.thankYouMessage = 'Thank you! Please come again.',
    this.termsAndConditions = '',
    // Kitchen defaults
    this.kitchenHeaderText = 'Kitchen Order',
    this.kitchenFooterText = '',
    this.kitchenShowDateTime = true,
    this.kitchenShowTable = true,
    this.kitchenShowOrderNumber = true,
    this.kitchenShowModifiers = true,
    this.kitchenFontSize = 14,
    this.kitchenTemplateStyle = KitchenTemplateStyle.standard,
  });

  ReceiptSettings copyWith({
    String? headerText,
    String? footerText,
    bool? showLogo,
    bool? showDateTime,
    bool? showOrderNumber,
    bool? showCashierName,
    bool? showTaxBreakdown,
    bool? showServiceChargeBreakdown,
    bool? showThankYouMessage,
    bool? showTaxId,
    String? taxIdText,
    bool? showWifiDetails,
    String? wifiDetails,
    bool? showBarcode,
    String? barcodeData,
    bool? showQrCode,
    String? qrData,
    bool? autoPrint,
    ReceiptPaperSize? paperSize,
    int? paperWidth,
    int? fontSize,
    String? thankYouMessage,
    String? termsAndConditions,
    String? kitchenHeaderText,
    String? kitchenFooterText,
    bool? kitchenShowDateTime,
    bool? kitchenShowTable,
    bool? kitchenShowOrderNumber,
    bool? kitchenShowModifiers,
    int? kitchenFontSize,
    KitchenTemplateStyle? kitchenTemplateStyle,
  }) {
    return ReceiptSettings(
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
      showLogo: showLogo ?? this.showLogo,
      showDateTime: showDateTime ?? this.showDateTime,
      showOrderNumber: showOrderNumber ?? this.showOrderNumber,
      showCashierName: showCashierName ?? this.showCashierName,
      showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
      showServiceChargeBreakdown:
          showServiceChargeBreakdown ?? this.showServiceChargeBreakdown,
      showThankYouMessage: showThankYouMessage ?? this.showThankYouMessage,
        showTaxId: showTaxId ?? this.showTaxId,
        taxIdText: taxIdText ?? this.taxIdText,
        showWifiDetails: showWifiDetails ?? this.showWifiDetails,
        wifiDetails: wifiDetails ?? this.wifiDetails,
        showBarcode: showBarcode ?? this.showBarcode,
        barcodeData: barcodeData ?? this.barcodeData,
        showQrCode: showQrCode ?? this.showQrCode,
        qrData: qrData ?? this.qrData,
      autoPrint: autoPrint ?? this.autoPrint,
      paperSize: paperSize ?? this.paperSize,
      paperWidth: paperWidth ?? this.paperWidth,
      fontSize: fontSize ?? this.fontSize,
      thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      kitchenHeaderText: kitchenHeaderText ?? this.kitchenHeaderText,
      kitchenFooterText: kitchenFooterText ?? this.kitchenFooterText,
      kitchenShowDateTime: kitchenShowDateTime ?? this.kitchenShowDateTime,
      kitchenShowTable: kitchenShowTable ?? this.kitchenShowTable,
      kitchenShowOrderNumber:
          kitchenShowOrderNumber ?? this.kitchenShowOrderNumber,
      kitchenShowModifiers: kitchenShowModifiers ?? this.kitchenShowModifiers,
      kitchenFontSize: kitchenFontSize ?? this.kitchenFontSize,
      kitchenTemplateStyle: kitchenTemplateStyle ?? this.kitchenTemplateStyle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headerText': headerText,
      'footerText': footerText,
      'showLogo': showLogo,
      'showDateTime': showDateTime,
      'showOrderNumber': showOrderNumber,
      'showCashierName': showCashierName,
      'showTaxBreakdown': showTaxBreakdown,
      'showServiceChargeBreakdown': showServiceChargeBreakdown,
      'showThankYouMessage': showThankYouMessage,
      'showTaxId': showTaxId,
      'taxIdText': taxIdText,
      'showWifiDetails': showWifiDetails,
      'wifiDetails': wifiDetails,
      'showBarcode': showBarcode,
      'barcodeData': barcodeData,
      'showQrCode': showQrCode,
      'qrData': qrData,
      'autoPrint': autoPrint,
      'paperSize': paperSize.name,
      'paperWidth': paperWidth,
      'fontSize': fontSize,
      'thankYouMessage': thankYouMessage,
      'termsAndConditions': termsAndConditions,
      'kitchenHeaderText': kitchenHeaderText,
      'kitchenFooterText': kitchenFooterText,
      'kitchenShowDateTime': kitchenShowDateTime,
      'kitchenShowTable': kitchenShowTable,
      'kitchenShowOrderNumber': kitchenShowOrderNumber,
      'kitchenShowModifiers': kitchenShowModifiers,
      'kitchenFontSize': kitchenFontSize,
      'kitchenTemplateStyle': kitchenTemplateStyle.name,
    };
  }

  factory ReceiptSettings.fromJson(Map<String, dynamic> json) {
    return ReceiptSettings(
      headerText: json['headerText'] as String? ?? 'ExtroPOS',
      footerText:
          json['footerText'] as String? ?? 'Thank you for your business!',
      showLogo: json['showLogo'] as bool? ?? true,
      showDateTime: json['showDateTime'] as bool? ?? true,
      showOrderNumber: json['showOrderNumber'] as bool? ?? true,
      showCashierName: json['showCashierName'] as bool? ?? true,
      showTaxBreakdown: json['showTaxBreakdown'] as bool? ?? true,
      showServiceChargeBreakdown:
          json['showServiceChargeBreakdown'] as bool? ?? true,
      showThankYouMessage: json['showThankYouMessage'] as bool? ?? true,
        showTaxId: json['showTaxId'] as bool? ?? true,
        taxIdText: json['taxIdText'] as String? ?? '',
        showWifiDetails: json['showWifiDetails'] as bool? ?? false,
        wifiDetails: json['wifiDetails'] as String? ?? '',
        showBarcode: json['showBarcode'] as bool? ?? false,
        barcodeData: json['barcodeData'] as String? ?? '',
        showQrCode: json['showQrCode'] as bool? ?? false,
        qrData: json['qrData'] as String? ?? '',
      autoPrint: json['autoPrint'] as bool? ?? false,
      paperSize: ReceiptPaperSize.values.firstWhere(
        (e) => e.name == json['paperSize'],
        orElse: () => ReceiptPaperSize.mm80,
      ),
      paperWidth: json['paperWidth'] as int? ?? 80,
      fontSize: json['fontSize'] as int? ?? 12,
      thankYouMessage:
          json['thankYouMessage'] as String? ?? 'Thank you! Please come again.',
      termsAndConditions: json['termsAndConditions'] as String? ?? '',
      kitchenHeaderText:
          json['kitchenHeaderText'] as String? ?? 'Kitchen Order',
      kitchenFooterText: json['kitchenFooterText'] as String? ?? '',
      kitchenShowDateTime: json['kitchenShowDateTime'] as bool? ?? true,
      kitchenShowTable: json['kitchenShowTable'] as bool? ?? true,
      kitchenShowOrderNumber: json['kitchenShowOrderNumber'] as bool? ?? true,
      kitchenShowModifiers: json['kitchenShowModifiers'] as bool? ?? true,
      kitchenFontSize: json['kitchenFontSize'] as int? ?? 14,
      kitchenTemplateStyle: KitchenTemplateStyle.values.firstWhere(
        (e) => e.name == json['kitchenTemplateStyle'],
        orElse: () => KitchenTemplateStyle.standard,
      ),
    );
  }
}

enum ReceiptPaperSize { mm58, mm80, a4 }

enum KitchenTemplateStyle {
  standard, // Current default template
  compact, // Table number style template (like the image)
}

extension ReceiptPaperSizeExtension on ReceiptPaperSize {
  String get displayName {
    switch (this) {
      case ReceiptPaperSize.mm58:
        return '58mm (Small)';
      case ReceiptPaperSize.mm80:
        return '80mm (Standard)';
      case ReceiptPaperSize.a4:
        return 'A4 (Letter)';
    }
  }

  int get widthInMm {
    switch (this) {
      case ReceiptPaperSize.mm58:
        return 58;
      case ReceiptPaperSize.mm80:
        return 80;
      case ReceiptPaperSize.a4:
        return 210;
    }
  }
}
