enum DocumentType {
  tenancyAgreement,
  utilityBill,
  accessCard,
  otherProof,
  unknown,
}

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
    this.cardNumber,
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
  final String? cardNumber;
  final String fullText;

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
      'cardNumber': cardNumber,
      'fullText': fullText,
    };
  }

  Map<String, String> toFieldMap({bool includeFullText = false}) {
    final fields = <String, String>{};

    void add(String key, String? value) {
      final cleanValue = value?.trim();
      if (cleanValue == null || cleanValue.isEmpty) return;
      fields[key] = cleanValue;
    }

    add('type', type.name);
    add('tenantName', tenantName);
    add('landlordName', landlordName);
    add('propertyAddress', propertyAddress);
    add('unitNumber', unitNumber);
    add('agreementDate', agreementDate);
    add('billType', billType);
    add('amount', amount);
    add('billDate', billDate);
    add('cardNumber', cardNumber);
    if (includeFullText) add('fullText', fullText);

    return fields;
  }

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
    String? cardNumber,
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
      cardNumber: cardNumber ?? this.cardNumber,
      fullText: fullText ?? this.fullText,
    );
  }
}

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

DocumentType documentTypeFromValue(String value) {
  final normalized = value.trim();
  for (final type in DocumentType.values) {
    if (type.name == normalized) return type;
  }

  final lower = normalized.toLowerCase();
  return switch (lower) {
    'tenancy agreement' => DocumentType.tenancyAgreement,
    'utility bill' => DocumentType.utilityBill,
    'access card' => DocumentType.accessCard,
    'other proof' => DocumentType.otherProof,
    _ => DocumentType.unknown,
  };
}
