import 'dart:convert';

/// MyInvois e-Invoice Document Models (UBL 2.1 Compliant)

enum EInvoiceDocumentType { invoice, creditNote, debitNote, refundNote }

enum EInvoiceStatus { draft, submitted, valid, invalid, cancelled, rejected }

class EInvoiceDocument {
  final String? uuid; // Assigned by MyInvois
  final String invoiceCodeNumber; // Internal reference (e.g., INV12345)
  final EInvoiceDocumentType documentType;
  final String documentTypeVersion;
  final DateTime issueDate;
  final DateTime issueTime;
  final String currencyCode;
  final EInvoiceSupplier supplier;
  final EInvoiceCustomer customer;
  final List<EInvoiceLineItem> lineItems;
  final EInvoiceTaxTotal taxTotal;
  final EInvoiceLegalMonetaryTotal legalMonetaryTotal;
  final EInvoiceStatus status;
  final String? submissionUid;
  final String? validationUrl;
  final String? qrCodeUrl;
  final DateTime? submittedAt;
  final String? errorMessage;

  EInvoiceDocument({
    this.uuid,
    required this.invoiceCodeNumber,
    this.documentType = EInvoiceDocumentType.invoice,
    this.documentTypeVersion = '1.0',
    required this.issueDate,
    required this.issueTime,
    this.currencyCode = 'MYR',
    required this.supplier,
    required this.customer,
    required this.lineItems,
    required this.taxTotal,
    required this.legalMonetaryTotal,
    this.status = EInvoiceStatus.draft,
    this.submissionUid,
    this.validationUrl,
    this.qrCodeUrl,
    this.submittedAt,
    this.errorMessage,
  });

  String get documentTypeCode {
    switch (documentType) {
      case EInvoiceDocumentType.invoice:
        return '01';
      case EInvoiceDocumentType.creditNote:
        return '02';
      case EInvoiceDocumentType.debitNote:
        return '03';
      case EInvoiceDocumentType.refundNote:
        return '04';
    }
  }

  /// Convert to UBL 2.1 JSON format for MyInvois submission
  Map<String, dynamic> toUBLJson() {
    return {
      '_D': 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2',
      '_A':
          'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
      '_B':
          'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
      'Invoice': [
        {
          'ID': [
            {'_': invoiceCodeNumber},
          ],
          'IssueDate': [
            {'_': issueDate.toIso8601String().split('T')[0]},
          ],
          'IssueTime': [
            {
              '_':
                  '${issueTime.hour.toString().padLeft(2, '0')}:${issueTime.minute.toString().padLeft(2, '0')}:${issueTime.second.toString().padLeft(2, '0')}Z',
            },
          ],
          'InvoiceTypeCode': [
            {'_': documentTypeCode, 'listVersionID': '1.0'},
          ],
          'DocumentCurrencyCode': [
            {'_': currencyCode},
          ],
          'AccountingSupplierParty': [supplier.toUBLJson()],
          'AccountingCustomerParty': [customer.toUBLJson()],
          'TaxTotal': [taxTotal.toUBLJson()],
          'LegalMonetaryTotal': [legalMonetaryTotal.toUBLJson()],
          'InvoiceLine': lineItems.map((item) => item.toUBLJson()).toList(),
        },
      ],
    };
  }

  /// Get Base64 encoded document for submission
  String toBase64() {
    final jsonString = jsonEncode(toUBLJson());
    return base64Encode(utf8.encode(jsonString));
  }

  EInvoiceDocument copyWith({
    String? uuid,
    String? invoiceCodeNumber,
    EInvoiceDocumentType? documentType,
    String? documentTypeVersion,
    DateTime? issueDate,
    DateTime? issueTime,
    String? currencyCode,
    EInvoiceSupplier? supplier,
    EInvoiceCustomer? customer,
    List<EInvoiceLineItem>? lineItems,
    EInvoiceTaxTotal? taxTotal,
    EInvoiceLegalMonetaryTotal? legalMonetaryTotal,
    EInvoiceStatus? status,
    String? submissionUid,
    String? validationUrl,
    String? qrCodeUrl,
    DateTime? submittedAt,
    String? errorMessage,
  }) {
    return EInvoiceDocument(
      uuid: uuid ?? this.uuid,
      invoiceCodeNumber: invoiceCodeNumber ?? this.invoiceCodeNumber,
      documentType: documentType ?? this.documentType,
      documentTypeVersion: documentTypeVersion ?? this.documentTypeVersion,
      issueDate: issueDate ?? this.issueDate,
      issueTime: issueTime ?? this.issueTime,
      currencyCode: currencyCode ?? this.currencyCode,
      supplier: supplier ?? this.supplier,
      customer: customer ?? this.customer,
      lineItems: lineItems ?? this.lineItems,
      taxTotal: taxTotal ?? this.taxTotal,
      legalMonetaryTotal: legalMonetaryTotal ?? this.legalMonetaryTotal,
      status: status ?? this.status,
      submissionUid: submissionUid ?? this.submissionUid,
      validationUrl: validationUrl ?? this.validationUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class EInvoiceSupplier {
  final String tin;
  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String countryCode;
  final String? phone;
  final String? email;

  EInvoiceSupplier({
    required this.tin,
    required this.name,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.countryCode = 'MYS',
    this.phone,
    this.email,
  });

  Map<String, dynamic> toUBLJson() {
    return {
      'Party': [
        {
          'IndustryClassificationCode': [
            {'_': '46510', 'name': 'Wholesale of computer hardware'},
          ],
          'PartyIdentification': [
            {
              'ID': [
                {'_': tin, 'schemeID': 'TIN'},
              ],
            },
          ],
          'PostalAddress': [
            {
              'AddressLine': [
                {
                  'Line': [
                    {'_': addressLine1},
                  ],
                },
                if (addressLine2 != null)
                  {
                    'Line': [
                      {'_': addressLine2},
                    ],
                  },
              ],
              'CityName': [
                {'_': city},
              ],
              'PostalZone': [
                {'_': postalCode},
              ],
              'CountrySubentityCode': [
                {'_': state},
              ],
              'Country': [
                {
                  'IdentificationCode': [
                    {
                      '_': countryCode,
                      'listID': 'ISO3166-1',
                      'listAgencyID': '6',
                    },
                  ],
                },
              ],
            },
          ],
          'PartyLegalEntity': [
            {
              'RegistrationName': [
                {'_': name},
              ],
            },
          ],
          if (phone != null)
            'Contact': [
              {
                'Telephone': [
                  {'_': phone},
                ],
                if (email != null)
                  'ElectronicMail': [
                    {'_': email},
                  ],
              },
            ],
        },
      ],
    };
  }
}

class EInvoiceCustomer {
  final String? tin;
  final String name;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? postalCode;
  final String countryCode;
  final String? phone;
  final String? email;
  final String? idType; // BRN, NRIC, PASSPORT, ARMY
  final String? idValue;

  EInvoiceCustomer({
    this.tin,
    required this.name,
    this.addressLine1,
    this.city,
    this.state,
    this.postalCode,
    this.countryCode = 'MYS',
    this.phone,
    this.email,
    this.idType,
    this.idValue,
  });

  Map<String, dynamic> toUBLJson() {
    return {
      'Party': [
        {
          if (tin != null)
            'PartyIdentification': [
              {
                'ID': [
                  {'_': tin, 'schemeID': 'TIN'},
                ],
              },
            ],
          if (idType != null && idValue != null)
            'PartyIdentification': [
              {
                'ID': [
                  {'_': idValue, 'schemeID': idType},
                ],
              },
            ],
          if (addressLine1 != null)
            'PostalAddress': [
              {
                'AddressLine': [
                  {
                    'Line': [
                      {'_': addressLine1},
                    ],
                  },
                ],
                if (city != null)
                  'CityName': [
                    {'_': city},
                  ],
                if (postalCode != null)
                  'PostalZone': [
                    {'_': postalCode},
                  ],
                if (state != null)
                  'CountrySubentityCode': [
                    {'_': state},
                  ],
                'Country': [
                  {
                    'IdentificationCode': [
                      {
                        '_': countryCode,
                        'listID': 'ISO3166-1',
                        'listAgencyID': '6',
                      },
                    ],
                  },
                ],
              },
            ],
          'PartyLegalEntity': [
            {
              'RegistrationName': [
                {'_': name},
              ],
            },
          ],
          if (phone != null || email != null)
            'Contact': [
              {
                if (phone != null)
                  'Telephone': [
                    {'_': phone},
                  ],
                if (email != null)
                  'ElectronicMail': [
                    {'_': email},
                  ],
              },
            ],
        },
      ],
    };
  }
}

class EInvoiceLineItem {
  final int lineNumber;
  final String itemName;
  final String? itemDescription;
  final double quantity;
  final String unitCode; // C62 = unit, H87 = piece, etc.
  final double unitPrice;
  final double lineExtensionAmount;
  final EInvoiceLineTax? taxTotal;
  final String? classificationCode;

  EInvoiceLineItem({
    required this.lineNumber,
    required this.itemName,
    this.itemDescription,
    required this.quantity,
    this.unitCode = 'C62',
    required this.unitPrice,
    required this.lineExtensionAmount,
    this.taxTotal,
    this.classificationCode,
  });

  Map<String, dynamic> toUBLJson() {
    return {
      'ID': [
        {'_': lineNumber.toString()},
      ],
      'InvoicedQuantity': [
        {'_': quantity.toStringAsFixed(2), 'unitCode': unitCode},
      ],
      'LineExtensionAmount': [
        {'_': lineExtensionAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
      if (taxTotal != null) 'TaxTotal': [taxTotal!.toUBLJson()],
      'Item': [
        {
          'Description': [
            {'_': itemDescription ?? itemName},
          ],
          if (classificationCode != null)
            'CommodityClassification': [
              {
                'ItemClassificationCode': [
                  {'_': classificationCode, 'listID': 'CLASS'},
                ],
              },
            ],
        },
      ],
      'Price': [
        {
          'PriceAmount': [
            {'_': unitPrice.toStringAsFixed(2), 'currencyID': 'MYR'},
          ],
        },
      ],
    };
  }
}

class EInvoiceLineTax {
  final double taxAmount;
  final String taxCategoryCode; // E = Exempt, S = Standard rated, etc.
  final double? taxPercent;

  EInvoiceLineTax({
    required this.taxAmount,
    required this.taxCategoryCode,
    this.taxPercent,
  });

  Map<String, dynamic> toUBLJson() {
    return {
      'TaxAmount': [
        {'_': taxAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
      'TaxSubtotal': [
        {
          'TaxableAmount': [
            {'_': '0.00', 'currencyID': 'MYR'},
          ],
          'TaxAmount': [
            {'_': taxAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
          ],
          'TaxCategory': [
            {
              'ID': [
                {'_': taxCategoryCode},
              ],
              if (taxPercent != null)
                'Percent': [
                  {'_': taxPercent!.toStringAsFixed(2)},
                ],
              'TaxScheme': [
                {
                  'ID': [
                    {
                      '_': 'OTH',
                      'schemeID': 'UN/ECE 5153',
                      'schemeAgencyID': '6',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    };
  }
}

class EInvoiceTaxTotal {
  final double totalTaxAmount;
  final List<EInvoiceTaxSubtotal> subtotals;

  EInvoiceTaxTotal({required this.totalTaxAmount, required this.subtotals});

  Map<String, dynamic> toUBLJson() {
    return {
      'TaxAmount': [
        {'_': totalTaxAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
      'TaxSubtotal': subtotals.map((s) => s.toUBLJson()).toList(),
    };
  }
}

class EInvoiceTaxSubtotal {
  final double taxableAmount;
  final double taxAmount;
  final String taxCategoryCode;
  final double? taxPercent;

  EInvoiceTaxSubtotal({
    required this.taxableAmount,
    required this.taxAmount,
    required this.taxCategoryCode,
    this.taxPercent,
  });

  Map<String, dynamic> toUBLJson() {
    return {
      'TaxableAmount': [
        {'_': taxableAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
      'TaxAmount': [
        {'_': taxAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
      'TaxCategory': [
        {
          'ID': [
            {'_': taxCategoryCode},
          ],
          if (taxPercent != null)
            'Percent': [
              {'_': taxPercent!.toStringAsFixed(2)},
            ],
          'TaxScheme': [
            {
              'ID': [
                {'_': 'OTH', 'schemeID': 'UN/ECE 5153', 'schemeAgencyID': '6'},
              ],
            },
          ],
        },
      ],
    };
  }
}

class EInvoiceLegalMonetaryTotal {
  final double lineExtensionAmount;
  final double taxExclusiveAmount;
  final double taxInclusiveAmount;
  final double payableAmount;

  EInvoiceLegalMonetaryTotal({
    required this.lineExtensionAmount,
    required this.taxExclusiveAmount,
    required this.taxInclusiveAmount,
    required this.payableAmount,
  });

  Map<String, dynamic> toUBLJson() {
    return {
      'LineExtensionAmount': [
        {'_': lineExtensionAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
      'TaxExclusiveAmount': [
        {'_': taxExclusiveAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
      'TaxInclusiveAmount': [
        {'_': taxInclusiveAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
      'PayableAmount': [
        {'_': payableAmount.toStringAsFixed(2), 'currencyID': 'MYR'},
      ],
    };
  }
}
