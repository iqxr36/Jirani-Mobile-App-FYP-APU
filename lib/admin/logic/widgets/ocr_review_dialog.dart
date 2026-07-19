// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : ocr_review_dialog.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';

class OcrReviewDialog extends StatefulWidget {
  const OcrReviewDialog({super.key, required this.initialData});

  final ExtractedDocumentData initialData;

  @override
  State<OcrReviewDialog> createState() => _OcrReviewDialogState();
}

class _OcrReviewDialogState extends State<OcrReviewDialog> {
  static const _documentTypes = [
    DocumentType.tenancyAgreement,
    DocumentType.utilityBill,
    DocumentType.accessCard,
    DocumentType.otherProof,
  ];

  static const _billTypes = [
    'Electricity',
    'Water',
    'Internet',
    'Maintenance',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late DocumentType _type;
  late final TextEditingController _tenantNameController;
  late final TextEditingController _landlordNameController;
  late final TextEditingController _propertyAddressController;
  late final TextEditingController _unitNumberController;
  late final TextEditingController _agreementDateController;
  late final TextEditingController _amountController;
  late final TextEditingController _billDateController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _utilityProviderController;
  late final TextEditingController _residentNameController;
  late final TextEditingController _issuerController;
  late final TextEditingController _documentDateController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _summaryController;
  late final TextEditingController _fullTextController;
  String _billType = 'Other';

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _type = data.type == DocumentType.unknown
        ? DocumentType.otherProof
        : data.type;
    _tenantNameController = TextEditingController(
      text: data.billHolderName ?? data.tenantName ?? data.residentName ?? '',
    );
    _landlordNameController = TextEditingController(
      text: data.landlordName ?? '',
    );
    _propertyAddressController = TextEditingController(
      text: data.serviceAddress ?? data.propertyAddress ?? '',
    );
    _unitNumberController = TextEditingController(text: data.unitNumber ?? '');
    _agreementDateController = TextEditingController(
      text: data.agreementDate ?? '',
    );
    _amountController = TextEditingController(
      text: data.totalAmount ?? data.amount ?? '',
    );
    _billDateController = TextEditingController(text: data.billDate ?? '');
    _accountNumberController = TextEditingController(
      text: data.accountNumber ?? '',
    );
    _dueDateController = TextEditingController(text: data.dueDate ?? '');
    _utilityProviderController = TextEditingController(
      text: data.utilityProvider ?? '',
    );
    _residentNameController = TextEditingController(
      text: data.residentName ?? data.tenantName ?? data.billHolderName ?? '',
    );
    _issuerController = TextEditingController(text: data.issuer ?? '');
    _documentDateController = TextEditingController(
      text: data.documentDate ?? '',
    );
    _cardNumberController = TextEditingController(text: data.cardNumber ?? '');
    _summaryController = TextEditingController(text: data.summary ?? '');
    _fullTextController = TextEditingController(text: data.fullText);
    final utilityType = data.utilityType ?? data.billType;
    _billType = _billTypes.contains(utilityType) ? utilityType! : 'Other';
  }

  @override
  void dispose() {
    _tenantNameController.dispose();
    _landlordNameController.dispose();
    _propertyAddressController.dispose();
    _unitNumberController.dispose();
    _agreementDateController.dispose();
    _amountController.dispose();
    _billDateController.dispose();
    _accountNumberController.dispose();
    _dueDateController.dispose();
    _utilityProviderController.dispose();
    _residentNameController.dispose();
    _issuerController.dispose();
    _documentDateController.dispose();
    _cardNumberController.dispose();
    _summaryController.dispose();
    _fullTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review OCR details'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<DocumentType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Document Type'),
                  items: [
                    for (final type in _documentTypes)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 14),
                ..._fieldsForType(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Confirm'),
        ),
      ],
    );
  }

  List<Widget> _fieldsForType() {
    return switch (_type) {
      DocumentType.tenancyAgreement => [
        _textField(_tenantNameController, 'Tenant Name', required: true),
        _textField(_landlordNameController, 'Landlord Name', required: true),
        _textField(_unitNumberController, 'Unit Number', required: true),
        _textField(_agreementDateController, 'Agreement Date', required: true),
        _textField(
          _propertyAddressController,
          'Property Address',
          required: true,
          maxLines: 2,
        ),
        _textField(_fullTextController, 'Full OCR Text', maxLines: 8),
      ],
      DocumentType.utilityBill => [
        _textField(_accountNumberController, 'Account Number'),
        DropdownButtonFormField<String>(
          initialValue: _billType,
          decoration: const InputDecoration(labelText: 'Utility Type'),
          items: [
            for (final billType in _billTypes)
              DropdownMenuItem(value: billType, child: Text(billType)),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _billType = value);
          },
          validator: (value) =>
              _requiredMessage(value, 'Utility Type is required.'),
        ),
        _textField(_utilityProviderController, 'Utility Provider'),
        _textField(_amountController, 'Total Amount', required: true),
        _textField(_tenantNameController, 'Bill Holder Name'),
        _textField(
          _propertyAddressController,
          'Service Address',
          required: true,
          maxLines: 2,
        ),
        _textField(_billDateController, 'Bill Date'),
        _textField(_dueDateController, 'Due Date'),
        _textField(_fullTextController, 'Full OCR Text', maxLines: 8),
      ],
      DocumentType.accessCard => [
        _textField(_residentNameController, 'Resident Name'),
        _textField(_unitNumberController, 'Unit Number'),
        _textField(
          _propertyAddressController,
          'Property Address',
          maxLines: 2,
        ),
        _textField(_issuerController, 'Issuer'),
        _textField(_documentDateController, 'Document Date'),
        _textField(_cardNumberController, 'Card Number'),
        _textField(_summaryController, 'Summary', maxLines: 3),
        _textField(
          _fullTextController,
          'Full OCR Text',
          required: true,
          maxLines: 8,
        ),
      ],
      DocumentType.otherProof || DocumentType.unknown => [
        _textField(_residentNameController, 'Resident Name'),
        _textField(_unitNumberController, 'Unit Number'),
        _textField(
          _propertyAddressController,
          'Property Address',
          maxLines: 2,
        ),
        _textField(_issuerController, 'Issuer'),
        _textField(_documentDateController, 'Document Date'),
        _textField(_cardNumberController, 'Card Number'),
        _textField(_summaryController, 'Summary', maxLines: 3),
        _textField(
          _fullTextController,
          'Full OCR Text',
          required: true,
          maxLines: 8,
        ),
      ],
    };
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    final minLines = maxLines > 1 ? (maxLines < 3 ? maxLines : 3) : 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => _requiredMessage(value, '$label is required.')
            : null,
      ),
    );
  }

  String? _requiredMessage(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      ExtractedDocumentData(
        type: _type,
        tenantName:
            _type == DocumentType.tenancyAgreement ||
                _type == DocumentType.utilityBill
            ? _emptyToNull(_tenantNameController.text)
            : null,
        landlordName: _type == DocumentType.tenancyAgreement
            ? _emptyToNull(_landlordNameController.text)
            : null,
        propertyAddress:
            _type == DocumentType.tenancyAgreement ||
                _type == DocumentType.utilityBill ||
                _type == DocumentType.accessCard ||
                _type == DocumentType.otherProof
            ? _emptyToNull(_propertyAddressController.text)
            : null,
        unitNumber:
            _type == DocumentType.tenancyAgreement ||
                _type == DocumentType.accessCard ||
                _type == DocumentType.otherProof
            ? _emptyToNull(_unitNumberController.text)
            : null,
        agreementDate: _type == DocumentType.tenancyAgreement
            ? _emptyToNull(_agreementDateController.text)
            : null,
        billType: _type == DocumentType.utilityBill ? _billType : null,
        amount: _type == DocumentType.utilityBill
            ? _emptyToNull(_amountController.text)
            : null,
        billDate: _type == DocumentType.utilityBill
            ? _emptyToNull(_billDateController.text)
            : null,
        accountNumber: _type == DocumentType.utilityBill
            ? _emptyToNull(_accountNumberController.text)
            : null,
        billHolderName: _type == DocumentType.utilityBill
            ? _emptyToNull(_tenantNameController.text)
            : null,
        dueDate: _type == DocumentType.utilityBill
            ? _emptyToNull(_dueDateController.text)
            : null,
        serviceAddress: _type == DocumentType.utilityBill
            ? _emptyToNull(_propertyAddressController.text)
            : null,
        totalAmount: _type == DocumentType.utilityBill
            ? _emptyToNull(_amountController.text)
            : null,
        utilityProvider: _type == DocumentType.utilityBill
            ? _emptyToNull(_utilityProviderController.text)
            : null,
        utilityType: _type == DocumentType.utilityBill ? _billType : null,
        residentName:
            _type == DocumentType.accessCard || _type == DocumentType.otherProof
            ? _emptyToNull(_residentNameController.text)
            : null,
        issuer:
            _type == DocumentType.accessCard || _type == DocumentType.otherProof
            ? _emptyToNull(_issuerController.text)
            : null,
        documentDate:
            _type == DocumentType.accessCard || _type == DocumentType.otherProof
            ? _emptyToNull(_documentDateController.text)
            : null,
        cardNumber:
            _type == DocumentType.accessCard || _type == DocumentType.otherProof
            ? _emptyToNull(_cardNumberController.text)
            : null,
        summary:
            _type == DocumentType.accessCard || _type == DocumentType.otherProof
            ? _emptyToNull(_summaryController.text)
            : null,
        fullText: _fullTextController.text.trim(),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
