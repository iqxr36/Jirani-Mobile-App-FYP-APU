import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/models/extracted_document_data.dart';
import 'package:jirani/services/ocr_parser_service.dart';

void main() {
  group('OcrParserService', () {
    late OcrParserService parser;

    setUp(() {
      parser = OcrParserService();
    });

    test('extracts tenancy agreement fields from labels', () {
      final result = parser.processOcrText('''
Tenant Name: Abu Khalil
Unit Number: A-18-07
Property Address: One South Residence
Landlord Name: Ahmad Tan
Agreement Date: 09/06/2026
''');

      expect(result.type, DocumentType.tenancyAgreement);
      expect(result.tenantName, 'Abu Khalil');
      expect(result.unitNumber, 'A-18-07');
      expect(result.propertyAddress, 'One South Residence');
      expect(result.landlordName, 'Ahmad Tan');
      expect(result.agreementDate, '09/06/2026');
    });

    test('extracts tenancy names from sentence-style OCR text', () {
      final result = parser.processOcrText('''
Tenant Name: The Landlord Name is Ahmad Tan. The Tenant Name is Abu Khalil. Both parties agree to follow the terms
Unit Number: A-18-07
Agreement Date: 09/06/2026
''');

      expect(result.type, DocumentType.tenancyAgreement);
      expect(result.tenantName, 'Abu Khalil');
      expect(result.landlordName, 'Ahmad Tan');
      expect(result.unitNumber, 'A-18-07');
      expect(result.agreementDate, '09/06/2026');
    });

    test('does not accept non-unit or non-date label noise', () {
      final result = parser.processOcrText('''
TENANCY AGREEMENT
Unit Number:
Tenant Name: Abu Khalil
Landlord Name: Ahmad Tan
Agreement Date: Abu Khalil
This tenancy is for Unit A-18-07 at One South Residence.
Date: 09/06/2026
''');

      expect(result.type, DocumentType.tenancyAgreement);
      expect(result.tenantName, 'Abu Khalil');
      expect(result.landlordName, 'Ahmad Tan');
      expect(result.unitNumber, 'A-18-07');
      expect(result.agreementDate, '09/06/2026');
    });

    test('extracts condo agreement fields from particulars table text', () {
      final result = parser.processOcrText('''
RESIDENTIAL TENANCY AGREEMENT
1. Agreement Particulars
Item Details
Agreement Date 5 June 2026
Landlord / Owner Ahmad bin Rahman
Tenant Nur Aisyah binti Hassan
Premises Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil
Perkasa 1, Bukit Jalil, 57000 Kuala Lumpur, Malaysia
Car Park / Access Card Car park bay B2-145, two access cards
2. Main Agreement Terms
The Tenant shall be responsible for keeping the premises clean.
The Landlord is legally required to maintain structural repairs.
''');

      expect(result.type, DocumentType.tenancyAgreement);
      expect(result.tenantName, 'Nur Aisyah binti Hassan');
      expect(result.landlordName, 'Ahmad bin Rahman');
      expect(result.unitNumber, 'A-18-07');
      expect(
        result.propertyAddress,
        'A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil, 57000 Kuala Lumpur, Malaysia',
      );
      expect(result.agreementDate, '5 June 2026');
    });

    test('extracts utility bill amount from labelled currency', () {
      final result = parser.processOcrText('''
Bill Type: Electricity
Tenant Name: Abu Khalil
Property Address: One South Residence
Amount Due: RM 185.70
Bill Date: 09/06/2026
''');

      expect(result.type, DocumentType.utilityBill);
      expect(result.billType, 'Electricity');
      expect(result.tenantName, 'Abu Khalil');
      expect(result.propertyAddress, 'One South Residence');
      expect(result.amount, 'RM 185.70');
      expect(result.billDate, '09/06/2026');
    });

    test('prefers payable amount over earlier currency amounts', () {
      final result = parser.processOcrText('''
Invoice
Previous payment RM 20.00
Current charges RM 40.00
Total Payable RM 185.70
TNB electricity account number 123456
''');

      expect(result.type, DocumentType.utilityBill);
      expect(result.amount, 'RM 185.70');
    });

    test('extracts access card fields with card number fallback', () {
      final result = parser.processOcrText('''
Property Address: One South Residence
Unit Number: A-18-07
RFID-102993
Access Card
''');

      expect(result.type, DocumentType.accessCard);
      expect(result.propertyAddress, 'One South Residence');
      expect(result.unitNumber, 'A-18-07');
      expect(result.cardNumber, 'RFID-102993');
    });

    test('falls back to other proof when document is unclear', () {
      final result = parser.processOcrText('''
Uploaded supporting document
Resident provided a note with no known labels.
''');

      expect(result.type, DocumentType.otherProof);
      expect(result.fullText, contains('Uploaded supporting document'));
    });
  });
}
