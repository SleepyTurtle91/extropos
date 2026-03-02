/// LHDN Configuration Model
/// Stores MyInvois API credentials and business information for e-invoice operations
class LhdnConfig {
  final String businessName;
  final String tin;
  final String regNo;
  final String clientId;
  final String clientSecret;

  LhdnConfig({
    this.businessName = '',
    this.tin = '',
    this.regNo = '',
    this.clientId = '',
    this.clientSecret = '',
  });

  factory LhdnConfig.fromJson(Map<String, dynamic> json) {
    return LhdnConfig(
      businessName: json['businessName'] ?? '',
      tin: json['tin'] ?? '',
      regNo: json['regNo'] ?? '',
      clientId: json['clientId'] ?? '',
      clientSecret: json['clientSecret'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'tin': tin,
      'regNo': regNo,
      'clientId': clientId,
      'clientSecret': clientSecret,
    };
  }

  bool get isComplete =>
      businessName.isNotEmpty &&
      tin.isNotEmpty &&
      regNo.isNotEmpty &&
      clientId.isNotEmpty &&
      clientSecret.isNotEmpty;
}
