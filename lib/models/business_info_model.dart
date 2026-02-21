import 'dart:convert';

import 'package:extropos/models/business_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessInfo with ChangeNotifier {
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String? registrationNumber;
  final String? taxNumber;
  final double taxRate;
  final bool isTaxEnabled;
  final double serviceChargeRate;
  final bool isServiceChargeEnabled;
  final String currency;
  final String currencySymbol;
  final bool isHappyHourEnabled;
  final String? happyHourStart; // 'HH:mm'
  final String? happyHourEnd; // 'HH:mm'
  final double happyHourDiscountPercent; // 0.0 - 1.0
  final String? logo;
  final String? website;
  final BusinessHours businessHours;
  final BusinessMode selectedBusinessMode;

  // MyInvois e-Invoice fields
  final String? sstRegistrationNumber; // SST Registration Number (e.g., "000123456789")
  final String? businessRegistrationNumber; // Business Registration Number
  final String? businessEmail;
  final String? businessPhone;
  final String? businessAddress;
  final bool isMyInvoisEnabled;
  final bool useMyInvoisSandbox;
  final bool? myInvoisLastTestSuccess;
  final int? myInvoisLastTestedAt; // epoch ms
  final int myInvoisProductionGuardHours;

  // SMTP Email Settings
  final String? smtpHost;
  final int? smtpPort;
  final String? smtpUsername;
  final String? smtpPassword;
  final bool? smtpUseSsl;

  // Receipt formatting settings
  final int receiptHeaderFontSize;
  final bool receiptHeaderBold;
  final bool receiptHeaderCentered;

  // Static instance for global access
  static BusinessInfo _instance = BusinessInfo._default();
  static SharedPreferences? _prefs;
  static const Object _unset = Object();

  static BusinessInfo get instance => _instance;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final loadedInfo = await _loadFromPrefs();
    if (loadedInfo != null) {
      _instance = loadedInfo;
      debugPrint(
        'BusinessInfo: Loaded from prefs - headerCentered: ${_instance.receiptHeaderCentered}, headerBold: ${_instance.receiptHeaderBold}, fontSize: ${_instance.receiptHeaderFontSize}',
      );
    } else {
      _instance = BusinessInfo._default();
      debugPrint(
        'BusinessInfo: Using defaults - headerCentered: ${_instance.receiptHeaderCentered}, headerBold: ${_instance.receiptHeaderBold}, fontSize: ${_instance.receiptHeaderFontSize}',
      );
    }
  }

  static Future<void> updateInstance(BusinessInfo newInfo) async {
    _instance = newInfo;
    await _saveToPrefs(newInfo);
    _instance.notifyListeners(); // Notify all listeners of the change
    debugPrint(
      'BusinessInfo: Saved to prefs - headerCentered: ${newInfo.receiptHeaderCentered}, headerBold: ${newInfo.receiptHeaderBold}, fontSize: ${newInfo.receiptHeaderFontSize}',
    );
  }

  BusinessInfo({
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'Malaysia',
    this.registrationNumber,
    this.taxNumber,
    this.taxRate = 0.10, // 10% default
    this.isTaxEnabled = true,
    this.serviceChargeRate = 0.05, // 5% default
    this.isServiceChargeEnabled = false,
    this.currency = 'MYR',
    this.currencySymbol = 'RM',
    this.logo,
    this.website,
    BusinessHours? businessHours,
    this.smtpHost,
    this.smtpPort,
    this.smtpUsername,
    this.smtpPassword,
    this.smtpUseSsl,
    this.receiptHeaderFontSize = 2,
    this.receiptHeaderBold = true,
    this.receiptHeaderCentered = true,
    this.selectedBusinessMode = BusinessMode.retail,
    this.isHappyHourEnabled = false,
    this.happyHourStart,
    this.happyHourEnd,
    this.happyHourDiscountPercent = 0.0,
    // MyInvois fields
    this.sstRegistrationNumber,
    this.businessRegistrationNumber,
    this.businessEmail,
    this.businessPhone,
    this.businessAddress,
    this.isMyInvoisEnabled = false,
    this.useMyInvoisSandbox = true,
    this.myInvoisLastTestSuccess,
    this.myInvoisLastTestedAt,
    this.myInvoisProductionGuardHours = 24,
  }) : businessHours = businessHours ?? BusinessHours.defaultHours();

  factory BusinessInfo._default() {
    return BusinessInfo(
      businessName: 'My Business',
      ownerName: 'Owner Name',
      email: 'owner@example.com',
      phone: '+60123456789',
      address: '123 Main Street',
      city: 'Kuala Lumpur',
      state: 'Wilayah Persekutuan',
      postcode: '50000',
    );
  }

  BusinessInfo copyWith({
    String? businessName,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? postcode,
    String? country,
    String? registrationNumber,
    String? taxNumber,
    double? taxRate,
    bool? isTaxEnabled,
    double? serviceChargeRate,
    bool? isServiceChargeEnabled,
    String? currency,
    String? currencySymbol,
    String? logo,
    String? website,
    BusinessHours? businessHours,
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    bool? smtpUseSsl,
    int? receiptHeaderFontSize,
    bool? receiptHeaderBold,
    bool? receiptHeaderCentered,
    BusinessMode? selectedBusinessMode,
    bool? isHappyHourEnabled,
    String? happyHourStart,
    String? happyHourEnd,
    double? happyHourDiscountPercent,
    // MyInvois fields
    Object? sstRegistrationNumber = _unset,
    Object? businessRegistrationNumber = _unset,
    Object? businessEmail = _unset,
    Object? businessPhone = _unset,
    Object? businessAddress = _unset,
    bool? isMyInvoisEnabled,
    bool? useMyInvoisSandbox,
    Object? myInvoisLastTestSuccess = _unset,
    Object? myInvoisLastTestedAt = _unset,
    int? myInvoisProductionGuardHours,
  }) {
    return BusinessInfo(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      taxNumber: taxNumber ?? this.taxNumber,
      taxRate: taxRate ?? this.taxRate,
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      isServiceChargeEnabled:
          isServiceChargeEnabled ?? this.isServiceChargeEnabled,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      logo: logo ?? this.logo,
      website: website ?? this.website,
      businessHours: businessHours ?? this.businessHours,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpUseSsl: smtpUseSsl ?? this.smtpUseSsl,
      receiptHeaderFontSize:
          receiptHeaderFontSize ?? this.receiptHeaderFontSize,
      receiptHeaderBold: receiptHeaderBold ?? this.receiptHeaderBold,
      receiptHeaderCentered:
          receiptHeaderCentered ?? this.receiptHeaderCentered,
      selectedBusinessMode: selectedBusinessMode ?? this.selectedBusinessMode,
      isHappyHourEnabled: isHappyHourEnabled ?? this.isHappyHourEnabled,
      happyHourStart: happyHourStart ?? this.happyHourStart,
      happyHourEnd: happyHourEnd ?? this.happyHourEnd,
      happyHourDiscountPercent:
          happyHourDiscountPercent ?? this.happyHourDiscountPercent,
      // MyInvois fields
        sstRegistrationNumber: identical(sstRegistrationNumber, _unset)
          ? this.sstRegistrationNumber
          : sstRegistrationNumber as String?,
        businessRegistrationNumber: identical(businessRegistrationNumber, _unset)
          ? this.businessRegistrationNumber
          : businessRegistrationNumber as String?,
        businessEmail: identical(businessEmail, _unset)
          ? this.businessEmail
          : businessEmail as String?,
        businessPhone: identical(businessPhone, _unset)
          ? this.businessPhone
          : businessPhone as String?,
        businessAddress: identical(businessAddress, _unset)
          ? this.businessAddress
          : businessAddress as String?,
      isMyInvoisEnabled: isMyInvoisEnabled ?? this.isMyInvoisEnabled,
      useMyInvoisSandbox: useMyInvoisSandbox ?? this.useMyInvoisSandbox,
        myInvoisLastTestSuccess: identical(myInvoisLastTestSuccess, _unset)
          ? this.myInvoisLastTestSuccess
          : myInvoisLastTestSuccess as bool?,
        myInvoisLastTestedAt: identical(myInvoisLastTestedAt, _unset)
          ? this.myInvoisLastTestedAt
            : myInvoisLastTestedAt as int?,
          myInvoisProductionGuardHours:
            myInvoisProductionGuardHours ?? this.myInvoisProductionGuardHours,
    );
  }

  /// Enable tax globally and persist to the shared instance.
  void enableTax() {
    BusinessInfo.updateInstance(copyWith(isTaxEnabled: true));
  }

  /// Disable tax globally and persist to the shared instance.
  void disableTax() {
    BusinessInfo.updateInstance(copyWith(isTaxEnabled: false));
  }

  /// Toggle tax enabled state and persist.
  void toggleTax() {
    BusinessInfo.updateInstance(copyWith(isTaxEnabled: !isTaxEnabled));
  }

  /// Enable service charge globally and persist to the shared instance.
  void enableServiceCharge() {
    BusinessInfo.updateInstance(copyWith(isServiceChargeEnabled: true));
  }

  /// Disable service charge globally and persist to the shared instance.
  void disableServiceCharge() {
    BusinessInfo.updateInstance(copyWith(isServiceChargeEnabled: false));
  }

  /// Toggle service charge enabled state and persist.
  void toggleServiceCharge() {
    BusinessInfo.updateInstance(
      copyWith(isServiceChargeEnabled: !isServiceChargeEnabled),
    );
  }

  String get fullAddress {
    return '$address, $city, $state $postcode, $country';
  }

  String get taxRatePercentage {
    return '${(taxRate * 100).toStringAsFixed(0)}%';
  }

  String get serviceChargeRatePercentage {
    return '${(serviceChargeRate * 100).toStringAsFixed(0)}%';
  }

  /// Is it currently happy hour based on the schedule in settings
  bool isInHappyHourNow() {
    if (!isHappyHourEnabled) return false;
    if (happyHourStart == null || happyHourEnd == null) return false;
    try {
      final now = DateTime.now();
      final partsStart = happyHourStart!.split(':');
      final partsEnd = happyHourEnd!.split(':');
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(partsStart[0]),
        int.parse(partsStart[1]),
      );
      final end = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(partsEnd[0]),
        int.parse(partsEnd[1]),
      );
      if (end.isBefore(start)) {
        // Crosses midnight: treat as start..23:59 and 00:00..end
        if (now.isAfter(start) || now.isBefore(end)) return true;
        return false;
      }
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  /// Opening time for today (string, e.g. '09:00')
  String get openingTimeToday {
    return businessHours.getHoursForDay(DateTime.now().weekday).openTime;
  }

  /// Closing time for today (string, e.g. '22:00')
  String get closingTimeToday {
    return businessHours.getHoursForDay(DateTime.now().weekday).closeTime;
  }

  static Future<BusinessInfo?> _loadFromPrefs() async {
    if (_prefs == null) return null;

    try {
      // Try to load business hours JSON if present
      BusinessHours hours = BusinessHours.defaultHours();
      final bh = _prefs!.getString('business_hours');
      if (bh != null && bh.isNotEmpty) {
        try {
          hours = BusinessHours.fromJson(
            jsonDecode(bh) as Map<String, dynamic>,
          );
        } catch (_) {
          // ignore and fallback to defaults
          hours = BusinessHours.defaultHours();
        }
      }

      return BusinessInfo(
        businessName: _prefs!.getString('business_name') ?? 'My Business',
        ownerName: _prefs!.getString('owner_name') ?? 'Owner Name',
        email: _prefs!.getString('email') ?? 'owner@example.com',
        phone: _prefs!.getString('phone') ?? '+60123456789',
        address: _prefs!.getString('address') ?? '123 Main Street',
        city: _prefs!.getString('city') ?? 'Kuala Lumpur',
        state: _prefs!.getString('state') ?? 'Wilayah Persekutuan',
        postcode: _prefs!.getString('postcode') ?? '50000',
        country: _prefs!.getString('country') ?? 'Malaysia',
        registrationNumber: _prefs!.getString('registration_number'),
        taxNumber: _prefs!.getString('tax_number'),
        taxRate: _prefs!.getDouble('tax_rate') ?? 0.10,
        isTaxEnabled: _prefs!.getBool('is_tax_enabled') ?? true,
        serviceChargeRate: _prefs!.getDouble('service_charge_rate') ?? 0.05,
        isServiceChargeEnabled:
            _prefs!.getBool('is_service_charge_enabled') ?? false,
        currency: _prefs!.getString('currency') ?? 'MYR',
        currencySymbol: _prefs!.getString('currency_symbol') ?? 'RM',
        logo: _prefs!.getString('logo'),
        website: _prefs!.getString('website'),
        businessHours: hours,
        receiptHeaderFontSize: _prefs!.getInt('receipt_header_font_size') ?? 2,
        receiptHeaderBold: _prefs!.getBool('receipt_header_bold') ?? true,
        receiptHeaderCentered:
            _prefs!.getBool('receipt_header_centered') ?? true,
        selectedBusinessMode:
            BusinessMode.values[_prefs!.getInt('selected_business_mode') ?? 0],
        isHappyHourEnabled: _prefs!.getBool('is_happy_hour_enabled') ?? false,
        happyHourStart: _prefs!.getString('happy_hour_start'),
        happyHourEnd: _prefs!.getString('happy_hour_end'),
        happyHourDiscountPercent:
            _prefs!.getDouble('happy_hour_discount_percent') ?? 0.0,
        // MyInvois persisted fields
        sstRegistrationNumber: _prefs!.getString('myinvois_sst'),
        businessRegistrationNumber: _prefs!.getString('myinvois_brn'),
        businessEmail: _prefs!.getString('myinvois_email'),
        businessPhone: _prefs!.getString('myinvois_phone'),
        businessAddress: _prefs!.getString('myinvois_address'),
        isMyInvoisEnabled: _prefs!.getBool('myinvois_enabled') ?? false,
        useMyInvoisSandbox: _prefs!.getBool('myinvois_use_sandbox') ?? true,
        myInvoisLastTestSuccess:
            _prefs!.getBool('myinvois_last_test_success'),
        myInvoisLastTestedAt: _prefs!.getInt('myinvois_last_tested_at'),
        myInvoisProductionGuardHours:
            _prefs!.getInt('myinvois_guard_hours') ?? 24,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> _saveToPrefs(BusinessInfo info) async {
    if (_prefs == null) return;

    await _prefs!.setString('business_name', info.businessName);
    await _prefs!.setString('owner_name', info.ownerName);
    await _prefs!.setString('email', info.email);
    await _prefs!.setString('phone', info.phone);
    await _prefs!.setString('address', info.address);
    await _prefs!.setString('city', info.city);
    await _prefs!.setString('state', info.state);
    await _prefs!.setString('postcode', info.postcode);
    await _prefs!.setString('country', info.country);
    if (info.registrationNumber != null) {
      await _prefs!.setString('registration_number', info.registrationNumber!);
    }
    if (info.taxNumber != null) {
      await _prefs!.setString('tax_number', info.taxNumber!);
    }
    await _prefs!.setDouble('tax_rate', info.taxRate);
    await _prefs!.setBool('is_tax_enabled', info.isTaxEnabled);
    await _prefs!.setDouble('service_charge_rate', info.serviceChargeRate);
    await _prefs!.setBool(
      'is_service_charge_enabled',
      info.isServiceChargeEnabled,
    );
    await _prefs!.setString('currency', info.currency);
    await _prefs!.setString('currency_symbol', info.currencySymbol);
    if (info.logo != null) {
      await _prefs!.setString('logo', info.logo!);
    }
    if (info.website != null) {
      await _prefs!.setString('website', info.website!);
    }
    // Persist business hours as JSON
    try {
      await _prefs!.setString(
        'business_hours',
        jsonEncode(info.businessHours.toJson()),
      );
    } catch (_) {
      // ignore JSON/prefs errors
    }
    await _prefs!.setInt(
      'receipt_header_font_size',
      info.receiptHeaderFontSize,
    );
    await _prefs!.setBool('receipt_header_bold', info.receiptHeaderBold);
    await _prefs!.setBool(
      'receipt_header_centered',
      info.receiptHeaderCentered,
    );
    await _prefs!.setInt(
      'selected_business_mode',
      info.selectedBusinessMode.index,
    );
    await _prefs!.setBool('is_happy_hour_enabled', info.isHappyHourEnabled);
    if (info.happyHourStart != null)
      await _prefs!.setString('happy_hour_start', info.happyHourStart!);
    if (info.happyHourEnd != null)
      await _prefs!.setString('happy_hour_end', info.happyHourEnd!);
    await _prefs!.setDouble(
      'happy_hour_discount_percent',
      info.happyHourDiscountPercent,
    );
    // MyInvois persisted fields
    await _prefs!.setBool('myinvois_enabled', info.isMyInvoisEnabled);
    await _prefs!.setBool('myinvois_use_sandbox', info.useMyInvoisSandbox);
    if (info.sstRegistrationNumber != null) {
      await _prefs!.setString('myinvois_sst', info.sstRegistrationNumber!);
    }
    if (info.businessRegistrationNumber != null) {
      await _prefs!
          .setString('myinvois_brn', info.businessRegistrationNumber!);
    }
    if (info.businessEmail != null) {
      await _prefs!.setString('myinvois_email', info.businessEmail!);
    }
    if (info.businessPhone != null) {
      await _prefs!.setString('myinvois_phone', info.businessPhone!);
    }
    if (info.businessAddress != null) {
      await _prefs!.setString('myinvois_address', info.businessAddress!);
    }
    if (info.myInvoisLastTestSuccess != null) {
      await _prefs!.setBool(
        'myinvois_last_test_success',
        info.myInvoisLastTestSuccess!,
      );
    }
    if (info.myInvoisLastTestedAt != null) {
      await _prefs!
          .setInt('myinvois_last_tested_at', info.myInvoisLastTestedAt!);
    }
    await _prefs!.setInt(
      'myinvois_guard_hours',
      info.myInvoisProductionGuardHours,
    );
  }
}

class BusinessHours {
  TimeRange monday;
  TimeRange tuesday;
  TimeRange wednesday;
  TimeRange thursday;
  TimeRange friday;
  TimeRange saturday;
  TimeRange sunday;

  BusinessHours({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory BusinessHours.defaultHours() {
    final weekdayHours = TimeRange(
      isOpen: true,
      openTime: '09:00',
      closeTime: '22:00',
    );
    final weekendHours = TimeRange(
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    );

    return BusinessHours(
      monday: weekdayHours,
      tuesday: weekdayHours,
      wednesday: weekdayHours,
      thursday: weekdayHours,
      friday: weekdayHours,
      saturday: weekendHours,
      sunday: weekendHours,
    );
  }

  /// Convert to JSON-serializable map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'monday': monday.toJson(),
      'tuesday': tuesday.toJson(),
      'wednesday': wednesday.toJson(),
      'thursday': thursday.toJson(),
      'friday': friday.toJson(),
      'saturday': saturday.toJson(),
      'sunday': sunday.toJson(),
    };
  }

  /// Restore BusinessHours from a JSON map.
  factory BusinessHours.fromJson(Map<String, dynamic> map) {
    return BusinessHours(
      monday: TimeRange.fromJson(
        Map<String, dynamic>.from(map['monday'] ?? {}),
      ),
      tuesday: TimeRange.fromJson(
        Map<String, dynamic>.from(map['tuesday'] ?? {}),
      ),
      wednesday: TimeRange.fromJson(
        Map<String, dynamic>.from(map['wednesday'] ?? {}),
      ),
      thursday: TimeRange.fromJson(
        Map<String, dynamic>.from(map['thursday'] ?? {}),
      ),
      friday: TimeRange.fromJson(
        Map<String, dynamic>.from(map['friday'] ?? {}),
      ),
      saturday: TimeRange.fromJson(
        Map<String, dynamic>.from(map['saturday'] ?? {}),
      ),
      sunday: TimeRange.fromJson(
        Map<String, dynamic>.from(map['sunday'] ?? {}),
      ),
    );
  }

  TimeRange getHoursForDay(int dayOfWeek) {
    switch (dayOfWeek) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        return monday;
    }
  }

  bool isOpenToday() {
    final today = DateTime.now().weekday;
    return getHoursForDay(today).isOpen;
  }
}

class TimeRange {
  bool isOpen;
  String openTime;
  String closeTime;

  TimeRange({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  String get displayText {
    if (!isOpen) return 'Closed';
    return '$openTime - $closeTime';
  }

  TimeRange copyWith({bool? isOpen, String? openTime, String? closeTime}) {
    return TimeRange(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  /// Convert to JSON serializable map
  Map<String, dynamic> toJson() {
    return {'isOpen': isOpen, 'openTime': openTime, 'closeTime': closeTime};
  }

  /// Restore from JSON map
  factory TimeRange.fromJson(Map<String, dynamic> map) {
    return TimeRange(
      isOpen: map['isOpen'] is bool
          ? map['isOpen'] as bool
          : (map['isOpen'] == 'true'),
      openTime: map['openTime']?.toString() ?? '09:00',
      closeTime: map['closeTime']?.toString() ?? '22:00',
    );
  }
}
