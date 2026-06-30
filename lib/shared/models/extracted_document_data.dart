/// Verification OCR feature: supported document categories extracted from residency proof uploads.
enum DocumentType {
  tenancyAgreement,
  utilityBill,
  accessCard,
  otherProof,
  unknown,
}

/// Verification OCR model: normalized text fields extracted from tenancy agreements, utility bills, access cards, or other proofs.
class ExtractedDocumentData {
  const ExtractedDocumentData({
    required this.type,
    this.tenantName,
    this.landlordName,
    this.propertyAddress,
    this.unitNumber,
    this.agreementDate,
    this.billType,
    this.amount,
    this.billDate,
    this.accountNumber,
    this.billHolderName,
    this.dueDate,
    this.serviceAddress,
    this.totalAmount,
    this.utilityProvider,
    this.utilityType,
    this.residentName,
    this.issuer,
    this.documentDate,
    this.cardNumber,
    this.summary,
    required this.fullText,
  });

  final DocumentType type;
  final String? tenantName;
  final String? landlordName;
  final String? propertyAddress;
  final String? unitNumber;
  final String? agreementDate;
  final String? billType;
  final String? amount;
  final String? billDate;
  final String? accountNumber;
  final String? billHolderName;
  final String? dueDate;
  final String? serviceAddress;
  final String? totalAmount;
  final String? utilityProvider;
  final String? utilityType;
  final String? residentName;
  final String? issuer;
  final String? documentDate;
  final String? cardNumber;
  final String? summary;
  final String fullText;

  /// Verification OCR model: serializes all extracted document data for storage/debugging.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'tenantName': tenantName,
      'landlordName': landlordName,
      'propertyAddress': propertyAddress,
      'unitNumber': unitNumber,
      'agreementDate': agreementDate,
      'billType': billType,
      'amount': amount,
      'billDate': billDate,
      'accountNumber': accountNumber,
      'billHolderName': billHolderName,
      'dueDate': dueDate,
      'serviceAddress': serviceAddress,
      'totalAmount': totalAmount,
      'utilityProvider': utilityProvider,
      'utilityType': utilityType,
      'residentName': residentName,
      'issuer': issuer,
      'documentDate': documentDate,
      'cardNumber': cardNumber,
      'summary': summary,
      'fullText': fullText,
    };
  }

  /// Verification OCR model: returns only relevant extracted fields for admin review and auto-verification checks.
  Map<String, String> toFieldMap({bool includeFullText = false}) {
    final fields = <String, String>{};

    void add(String key, String? value) {
      final cleanValue = value?.trim();
      if (cleanValue == null || cleanValue.isEmpty) return;
      fields[key] = cleanValue;
    }

    add('type', type.name);
    if (type == DocumentType.utilityBill) {
      add('accountNumber', accountNumber);
      add('billDate', billDate);
      add('billHolderName', billHolderName ?? tenantName);
      add('dueDate', dueDate);
      add('serviceAddress', serviceAddress ?? propertyAddress);
      add('totalAmount', totalAmount ?? amount);
      add('utilityProvider', utilityProvider);
      add('utilityType', utilityType ?? billType);
    } else if (type == DocumentType.accessCard ||
        type == DocumentType.otherProof) {
      add('residentName', residentName ?? tenantName);
      add('unitNumber', unitNumber);
      add('propertyAddress', propertyAddress);
      add('issuer', issuer);
      add('documentDate', documentDate);
      add('cardNumber', cardNumber);
      add('summary', summary);
    } else {
      add('tenantName', tenantName);
      add('landlordName', landlordName);
      add('propertyAddress', propertyAddress);
      add('unitNumber', unitNumber);
      add('agreementDate', agreementDate);
      add('billType', billType);
      add('amount', amount);
      add('billDate', billDate);
      add('cardNumber', cardNumber);
    }
    final fullTextOnlyDocument =
        type == DocumentType.accessCard || type == DocumentType.otherProof;
    if (includeFullText || fullTextOnlyDocument) add('fullText', fullText);

    return fields;
  }

  /// Verification OCR model: creates an updated extraction result while preserving unchanged fields.
  ExtractedDocumentData copyWith({
    DocumentType? type,
    String? tenantName,
    String? landlordName,
    String? propertyAddress,
    String? unitNumber,
    String? agreementDate,
    String? billType,
    String? amount,
    String? billDate,
    String? accountNumber,
    String? billHolderName,
    String? dueDate,
    String? serviceAddress,
    String? totalAmount,
    String? utilityProvider,
    String? utilityType,
    String? residentName,
    String? issuer,
    String? documentDate,
    String? cardNumber,
    String? summary,
    String? fullText,
  }) {
    return ExtractedDocumentData(
      type: type ?? this.type,
      tenantName: tenantName ?? this.tenantName,
      landlordName: landlordName ?? this.landlordName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      unitNumber: unitNumber ?? this.unitNumber,
      agreementDate: agreementDate ?? this.agreementDate,
      billType: billType ?? this.billType,
      amount: amount ?? this.amount,
      billDate: billDate ?? this.billDate,
      accountNumber: accountNumber ?? this.accountNumber,
      billHolderName: billHolderName ?? this.billHolderName,
      dueDate: dueDate ?? this.dueDate,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      totalAmount: totalAmount ?? this.totalAmount,
      utilityProvider: utilityProvider ?? this.utilityProvider,
      utilityType: utilityType ?? this.utilityType,
      residentName: residentName ?? this.residentName,
      issuer: issuer ?? this.issuer,
      documentDate: documentDate ?? this.documentDate,
      cardNumber: cardNumber ?? this.cardNumber,
      summary: summary ?? this.summary,
      fullText: fullText ?? this.fullText,
    );
  }
}

/// Verification OCR UI: converts document type enum values into labels shown to admins/residents.
extension DocumentTypeLabels on DocumentType {
  String get label {
    return switch (this) {
      DocumentType.tenancyAgreement => 'Tenancy Agreement',
      DocumentType.utilityBill => 'Utility Bill',
      DocumentType.accessCard => 'Access Card',
      DocumentType.otherProof => 'Other Proof',
      DocumentType.unknown => 'Unknown',
    };
  }
}

/// Verification OCR feature: parses user/backend document type strings into the supported enum.
DocumentType documentTypeFromValue(String value) {
  final normalized = value.trim();
  for (final type in DocumentType.values) {
    if (type.name == normalized) return type;
  }

  final lower = normalized.toLowerCase();
  return switch (lower) {
    'tenancyagreement' || 'tenancy_agreement' => DocumentType.tenancyAgreement,
    'tenancy agreement' => DocumentType.tenancyAgreement,
    'utilitybill' || 'utility_bill' => DocumentType.utilityBill,
    'utility bill' => DocumentType.utilityBill,
    'access card' => DocumentType.accessCard,
    'other proof' => DocumentType.otherProof,
    _ => DocumentType.unknown,
  };
}
