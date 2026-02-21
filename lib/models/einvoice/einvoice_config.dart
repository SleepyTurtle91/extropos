/// MyInvois e-Invoice Configuration Model
class EInvoiceConfig {
  final String clientId;
  final String clientSecret;
  final String tin; // Tax Identification Number
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String identityServiceUrl;
  final String apiServiceUrl;
  final bool isProduction;
  final bool isEnabled;

  const EInvoiceConfig({
    required this.clientId,
    required this.clientSecret,
    required this.tin,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    required this.businessEmail,
    this.identityServiceUrl = 'https://preprod-api.myinvois.hasil.gov.my',
    this.apiServiceUrl = 'https://preprod-api.myinvois.hasil.gov.my',
    this.isProduction = false,
    this.isEnabled = false,
  });

  factory EInvoiceConfig.sandbox() {
    return const EInvoiceConfig(
      clientId: '',
      clientSecret: '',
      tin: '',
      businessName: '',
      businessAddress: '',
      businessPhone: '',
      businessEmail: '',
      identityServiceUrl: 'https://preprod-api.myinvois.hasil.gov.my',
      apiServiceUrl: 'https://preprod-api.myinvois.hasil.gov.my',
      isProduction: false,
      isEnabled: false,
    );
  }

  factory EInvoiceConfig.production() {
    return const EInvoiceConfig(
      clientId: '',
      clientSecret: '',
      tin: '',
      businessName: '',
      businessAddress: '',
      businessPhone: '',
      businessEmail: '',
      identityServiceUrl: 'https://api.myinvois.hasil.gov.my',
      apiServiceUrl: 'https://api.myinvois.hasil.gov.my',
      isProduction: true,
      isEnabled: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'clientSecret': clientSecret,
      'tin': tin,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'identityServiceUrl': identityServiceUrl,
      'apiServiceUrl': apiServiceUrl,
      'isProduction': isProduction,
      'isEnabled': isEnabled,
    };
  }

  factory EInvoiceConfig.fromJson(Map<String, dynamic> json) {
    return EInvoiceConfig(
      clientId: json['clientId'] ?? '',
      clientSecret: json['clientSecret'] ?? '',
      tin: json['tin'] ?? '',
      businessName: json['businessName'] ?? '',
      businessAddress: json['businessAddress'] ?? '',
      businessPhone: json['businessPhone'] ?? '',
      businessEmail: json['businessEmail'] ?? '',
      identityServiceUrl:
          json['identityServiceUrl'] ??
          'https://preprod-api.myinvois.hasil.gov.my',
      apiServiceUrl:
          json['apiServiceUrl'] ?? 'https://preprod-api.myinvois.hasil.gov.my',
      isProduction: json['isProduction'] ?? false,
      isEnabled: json['isEnabled'] ?? false,
    );
  }

  EInvoiceConfig copyWith({
    String? clientId,
    String? clientSecret,
    String? tin,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? identityServiceUrl,
    String? apiServiceUrl,
    bool? isProduction,
    bool? isEnabled,
  }) {
    return EInvoiceConfig(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      tin: tin ?? this.tin,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      identityServiceUrl: identityServiceUrl ?? this.identityServiceUrl,
      apiServiceUrl: apiServiceUrl ?? this.apiServiceUrl,
      isProduction: isProduction ?? this.isProduction,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  bool get isConfigured {
    return clientId.isNotEmpty &&
        clientSecret.isNotEmpty &&
        tin.isNotEmpty &&
        businessName.isNotEmpty;
  }
}
