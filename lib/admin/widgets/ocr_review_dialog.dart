import 'package:flutter/material.dart';
import 'package:jirani/models/extracted_document_data.dart';

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
  late final TextEditingController _cardNumberController;
  late final TextEditingController _fullTextController;
  String _billType = 'Other';

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _type = data.type == DocumentType.unknown
        ? DocumentType.otherProof
        : data.type;
    _tenantNameController = TextEditingController(text: data.tenantName ?? '');
    _landlordNameController = TextEditingController(
      text: data.landlordName ?? '',
    );
    _propertyAddressController = TextEditingController(
      text: data.propertyAddress ?? '',
    );
    _unitNumberController = TextEditingController(text: data.unitNumber ?? '');
    _agreementDateController = TextEditingController(
      text: data.agreementDate ?? '',
    );
    _amountController = TextEditingController(text: data.amount ?? '');
    _billDateController = TextEditingController(text: data.billDate ?? '');
    _cardNumberController = TextEditingController(text: data.cardNumber ?? '');
    _fullTextController = TextEditingController(text: data.fullText);
    _billType = _billTypes.contains(data.billType) ? data.billType! : 'Other';
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
    _cardNumberController.dispose();
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
        _textField(_unitNumberController, 'Unit Number', required: true),
        _textField(
          _propertyAddressController,
          'Property Address',
          required: true,
          maxLines: 2,
        ),
        _textField(_landlordNameController, 'Landlord Name', required: true),
        _textField(_agreementDateController, 'Agreement Date', required: true),
        _textField(_fullTextController, 'Full OCR Text', maxLines: 8),
      ],
      DocumentType.utilityBill => [
        DropdownButtonFormField<String>(
          initialValue: _billType,
          decoration: const InputDecoration(labelText: 'Bill Type'),
          items: [
            for (final billType in _billTypes)
              DropdownMenuItem(value: billType, child: Text(billType)),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _billType = value);
          },
          validator: (value) =>
              _requiredMessage(value, 'Bill Type is required.'),
        ),
        _textField(_amountController, 'Amount', required: true),
        _textField(_tenantNameController, 'Tenant Name'),
        _textField(
          _propertyAddressController,
          'Property Address',
          required: true,
          maxLines: 2,
        ),
        _textField(_billDateController, 'Bill Date'),
        _textField(_fullTextController, 'Full OCR Text', maxLines: 8),
      ],
      DocumentType.accessCard => [
        _textField(
          _propertyAddressController,
          'Property Address',
          required: true,
          maxLines: 2,
        ),
        _textField(_unitNumberController, 'Unit Number', required: true),
        _textField(_cardNumberController, 'Card Number', required: true),
        _textField(_fullTextController, 'Full OCR Text', maxLines: 8),
      ],
      DocumentType.otherProof || DocumentType.unknown => [
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        minLines: maxLines > 1 ? 3 : 1,
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
                _type == DocumentType.accessCard
            ? _emptyToNull(_propertyAddressController.text)
            : null,
        unitNumber:
            _type == DocumentType.tenancyAgreement ||
                _type == DocumentType.accessCard
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
        cardNumber: _type == DocumentType.accessCard
            ? _emptyToNull(_cardNumberController.text)
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
