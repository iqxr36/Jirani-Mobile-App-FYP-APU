import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/viewmodels/verification_viewmodel.dart';
import 'package:jirani/views/verification/verification_status_view.dart';
import 'package:jirani/shared/widgets/jirani_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;
const int _kMaxDocumentBytes = 10 * 1024 * 1024;
const _kPdfOnlyDocumentExtensions = ['pdf'];
const _kImageAndPdfDocumentExtensions = [
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'pdf',
];

class ResidencyVerificationView extends StatelessWidget {
  const ResidencyVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VerificationViewModel>(
      create: (_) => VerificationViewModel(),
      child: const _ResidencyVerificationForm(),
    );
  }
}

class _ResidencyVerificationForm extends StatefulWidget {
  const _ResidencyVerificationForm();

  @override
  State<_ResidencyVerificationForm> createState() =>
      _ResidencyVerificationFormState();
}

class _ResidencyVerificationFormState
    extends State<_ResidencyVerificationForm> {
  final _blockController = TextEditingController();
  final _floorController = TextEditingController();
  final _unitOnFloorController = TextEditingController();
  final _notesController = TextEditingController();
  final _floorFocusNode = FocusNode();
  final _unitOnFloorFocusNode = FocusNode();
  final _imagePicker = ImagePicker();

  String? _documentType;
  String? _fileName;
  String? _localFilePath;
  Uint8List? _fileBytes;

  static const _documentTypes = <_DocumentTypeOption>[
    _DocumentTypeOption(
      label: 'Utility Bill',
      value: AppConstants.documentTypeUtilityBill,
    ),
    _DocumentTypeOption(
      label: 'Tenancy Agreement',
      value: AppConstants.documentTypeTenancyAgreement,
    ),
    _DocumentTypeOption(
      label: 'Access Card',
      value: AppConstants.documentTypeAccessCard,
    ),
    _DocumentTypeOption(
      label: 'Other Proof',
      value: AppConstants.documentTypeOtherProof,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    final unitNumber = user?.unitNumber.trim() ?? '';
    if (unitNumber.isNotEmpty) {
      _populateUnitFields(unitNumber);
    }
  }

  @override
  void dispose() {
    _blockController.dispose();
    _floorController.dispose();
    _unitOnFloorController.dispose();
    _notesController.dispose();
    _floorFocusNode.dispose();
    _unitOnFloorFocusNode.dispose();
    super.dispose();
  }

  void _populateUnitFields(String unitNumber) {
    final parts = unitNumber
        .split(RegExp(r'[\s\-/]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 3) {
      _blockController.text = parts[0].toUpperCase();
      _floorController.text = parts[1];
      _unitOnFloorController.text = parts.sublist(2).join('-');
      return;
    }

    if (parts.length == 2) {
      _floorController.text = parts[0];
      _unitOnFloorController.text = parts[1];
      return;
    }

    _unitOnFloorController.text = unitNumber;
  }

  String get _formattedUnitNumber {
    final block = _blockController.text.trim().toUpperCase();
    final floor = _floorController.text.trim();
    final unit = _unitOnFloorController.text.trim();

    if (block.isEmpty || floor.isEmpty || unit.isEmpty) return '';
    return '$block-$floor-$unit';
  }

  String? _unitValidationMessage() {
    final block = _blockController.text.trim().toUpperCase();
    final floor = _floorController.text.trim();
    final unit = _unitOnFloorController.text.trim();

    if (block.isEmpty) return 'Enter your block letter.';
    if (!RegExp(r'^[A-Z]$').hasMatch(block)) {
      return 'Block must be one alphabet letter.';
    }
    if (floor.isEmpty) return 'Enter your floor number.';
    if (!RegExp(r'^[0-9]+$').hasMatch(floor)) {
      return 'Floor must contain numbers only.';
    }
    if (unit.isEmpty) return 'Enter your unit number.';
    if (!RegExp(r'^[0-9]+$').hasMatch(unit)) {
      return 'Unit must contain numbers only.';
    }

    return null;
  }

  Future<void> _pickFromGallery() async {
    final documentType = _documentType;
    if (documentType == null) {
      _showMessage('Select a document type before uploading.');
      return;
    }
    if (!_allowsImageUpload(documentType)) {
      _showMessage('This document type only accepts PDF files.');
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fileBytes = bytes;
      _fileName = picked.name;
      _localFilePath = picked.path;
    });
  }

  Future<void> _pickFromFiles() async {
    final documentType = _documentType;
    if (documentType == null) {
      _showMessage('Select a document type before uploading.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensionsFor(documentType),
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected file.')),
      );
      return;
    }

    final extension = _fileExtension(file.name);
    if (!_allowedExtensionsFor(documentType).contains(extension)) {
      _showMessage(_unsupportedFileTypeMessage(documentType));
      return;
    }

    setState(() {
      _fileBytes = bytes;
      _fileName = file.name;
      _localFilePath = file.path;
    });
  }

  Future<void> _selectDocumentType() async {
    final selected = await showJiraniModalBottomSheet<String>(
      context: context,
      title: 'Select Document Type',
      subtitle: 'Choose the document you will upload for residency review.',
      icon: Icons.description_rounded,
      child: Builder(
        builder: (modalContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in _documentTypes)
                JiraniModalOption(
                  title: option.label,
                  icon: Icons.description_outlined,
                  selected: option.value == _documentType,
                  onTap: () => Navigator.of(modalContext).pop(option.value),
                ),
            ],
          );
        },
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _documentType = selected;
        if (!_isCurrentFileAllowedFor(selected)) {
          _fileName = null;
          _localFilePath = null;
          _fileBytes = null;
        }
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final user = context.read<AuthViewModel>().currentUser;
    final communityName = user?.communityName.trim() ?? '';
    final documentType = _documentType;
    final bytes = _fileBytes;
    final fileName = _fileName;
    final unitValidationMessage = _unitValidationMessage();

    if (communityName.isEmpty) {
      _showMessage('Select your community before submitting verification.');
      return;
    }
    if (unitValidationMessage != null) {
      _showMessage(unitValidationMessage);
      return;
    }
    if (documentType == null) {
      _showMessage('Select a document type.');
      return;
    }
    if (bytes == null || fileName == null) {
      _showMessage('Upload a supporting document.');
      return;
    }
    if (bytes.lengthInBytes > _kMaxDocumentBytes) {
      _showMessage('Choose a document smaller than 10 MB.');
      return;
    }

    final unitNumber = _formattedUnitNumber;
    final verificationVm = context.read<VerificationViewModel>();
    final request = await verificationVm.submitVerificationRequest(
      documentType: documentType,
      fileBytes: bytes,
      originalFileName: fileName,
      localFilePath: _localFilePath,
      communityName: communityName,
      unitNumber: unitNumber,
      notes: _notesController.text,
    );

    if (!mounted) return;
    if (request == null) {
      _showMessage(verificationVm.errorMessage ?? 'Upload failed.');
      return;
    }

    await context.read<AuthViewModel>().refreshCurrentUser();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Residency verification submitted.')),
    );
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => const VerificationStatusView()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _documentTypeLabel(String? value) {
    for (final option in _documentTypes) {
      if (option.value == value) return option.label;
    }
    return 'Select document type';
  }

  bool _allowsImageUpload(String documentType) {
    return documentType == AppConstants.documentTypeAccessCard ||
        documentType == AppConstants.documentTypeOtherProof;
  }

  List<String> _allowedExtensionsFor(String documentType) {
    if (documentType == AppConstants.documentTypeTenancyAgreement ||
        documentType == AppConstants.documentTypeUtilityBill) {
      return _kPdfOnlyDocumentExtensions;
    }
    return _kImageAndPdfDocumentExtensions;
  }

  String _acceptedFormatsLabel(String? documentType) {
    if (documentType == null) return 'Select a document type first.';
    if (_allowsImageUpload(documentType)) {
      return 'Accepted formats: JPG, PNG, WEBP, HEIC, or PDF.';
    }
    return 'Accepted format: PDF only.';
  }

  String _unsupportedFileTypeMessage(String documentType) {
    return _allowsImageUpload(documentType)
        ? 'Only JPG, PNG, WEBP, HEIC, or PDF files are supported.'
        : 'Only PDF files are supported for this document type.';
  }

  bool _isCurrentFileAllowedFor(String documentType) {
    final fileName = _fileName;
    if (fileName == null) return true;
    return _allowedExtensionsFor(
      documentType,
    ).contains(_fileExtension(fileName));
  }

  String _fileExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    final ext = fileName.substring(dot + 1).toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final verificationVm = context.watch<VerificationViewModel>();
    final hasCommunity = user?.communityName.trim().isNotEmpty == true;
    final communityName = hasCommunity
        ? user!.communityName.trim()
        : 'No community selected';
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final documentType = _documentType;
    final allowsGalleryUpload =
        documentType != null && _allowsImageUpload(documentType);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 10 + bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(onBack: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'Please provide your residency details and upload a supporting document to complete verification.',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _FieldLabel('Community / Residence'),
                          _ReadOnlyLineField(
                            value: communityName,
                            isMuted: !hasCommunity,
                          ),
                          const SizedBox(height: 19),
                          const _FieldLabel('Unit Number'),
                          const SizedBox(height: 7),
                          _UnitNumberFields(
                            blockController: _blockController,
                            floorController: _floorController,
                            unitController: _unitOnFloorController,
                            floorFocusNode: _floorFocusNode,
                            unitFocusNode: _unitOnFloorFocusNode,
                          ),
                          const SizedBox(height: 19),
                          const _FieldLabel('Document Type'),
                          _LineSelectField(
                            value: _documentTypeLabel(_documentType),
                            isPlaceholder: _documentType == null,
                            onTap: verificationVm.isLoading
                                ? null
                                : _selectDocumentType,
                          ),
                          const SizedBox(height: 19),
                          const _FieldLabel('Upload Document'),
                          const SizedBox(height: 6),
                          _UploadPanel(
                            fileName: _fileName,
                            acceptedFormats: _acceptedFormatsLabel(
                              documentType,
                            ),
                            onGalleryTap:
                                verificationVm.isLoading || !allowsGalleryUpload
                                ? null
                                : _pickFromGallery,
                            onFilesTap: verificationVm.isLoading
                                ? null
                                : _pickFromFiles,
                          ),
                          const SizedBox(height: 8),
                          const _FieldLabel('Optional Notes'),
                          const SizedBox(height: 7),
                          _NotesField(controller: _notesController),
                          const SizedBox(height: 18),
                          if (verificationVm.isLoading) ...[
                            LinearProgressIndicator(
                              value: verificationVm.uploadProgress == 0
                                  ? null
                                  : verificationVm.uploadProgress,
                              minHeight: 2,
                              color: _kBrandTeal,
                              backgroundColor: _kBrandTeal.withValues(
                                alpha: 0.12,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          _SubmitButton(
                            isLoading: verificationVm.isLoading,
                            onPressed: verificationVm.isLoading
                                ? null
                                : _submit,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: _kBrandTeal,
                size: 34,
              ),
            ),
          ),
          const Text(
            'Residency Verification',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class _ReadOnlyLineField extends StatelessWidget {
  const _ReadOnlyLineField({required this.value, this.isMuted = false});

  final String value;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
      ),
      padding: const EdgeInsets.only(left: 9, right: 9),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isMuted ? Colors.black.withValues(alpha: 0.38) : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UnitNumberFields extends StatelessWidget {
  const _UnitNumberFields({
    required this.blockController,
    required this.floorController,
    required this.unitController,
    required this.floorFocusNode,
    required this.unitFocusNode,
  });

  final TextEditingController blockController;
  final TextEditingController floorController;
  final TextEditingController unitController;
  final FocusNode floorFocusNode;
  final FocusNode unitFocusNode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _UnitNumberSegmentField(
            controller: blockController,
            label: 'Block',
            hintText: 'B',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              LengthLimitingTextInputFormatter(1),
              _UpperCaseTextFormatter(),
            ],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => floorFocusNode.requestFocus(),
          ),
        ),
        const _UnitNumberSeparator(),
        Expanded(
          child: _UnitNumberSegmentField(
            controller: floorController,
            focusNode: floorFocusNode,
            label: 'Floor',
            hintText: '12',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => unitFocusNode.requestFocus(),
          ),
        ),
        const _UnitNumberSeparator(),
        Expanded(
          child: _UnitNumberSegmentField(
            controller: unitController,
            focusNode: unitFocusNode,
            label: 'Unit',
            hintText: '3',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }
}

class _UnitNumberSeparator extends StatelessWidget {
  const _UnitNumberSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        '-',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.45),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UnitNumberSegmentField extends StatelessWidget {
  const _UnitNumberSegmentField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.keyboardType,
    required this.inputFormatters,
    required this.textInputAction,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        onSubmitted: onSubmitted,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          counterText: '',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.60),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.28),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.16)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: _kBrandTeal, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _LineSelectField extends StatelessWidget {
  const _LineSelectField({
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  final String value;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),
          padding: const EdgeInsets.only(left: 9, right: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPlaceholder
                        ? Colors.black.withValues(alpha: 0.85)
                        : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 25),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({
    required this.fileName,
    required this.acceptedFormats,
    required this.onGalleryTap,
    required this.onFilesTap,
  });

  final String? fileName;
  final String acceptedFormats;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onFilesTap;

  @override
  Widget build(BuildContext context) {
    final selected = fileName != null && fileName!.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle_outline_rounded : Icons.upload_file,
            color: selected ? _kBrandTeal : Colors.black,
            size: 24,
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              selected
                  ? fileName!
                  : 'Ensure the document is clear and shows your\nname and unit number.\n$acceptedFormats',
              maxLines: selected ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _UploadActionButton(
                  label: selected ? 'Replace Photo' : 'Gallery',
                  icon: Icons.photo_library_outlined,
                  onPressed: onGalleryTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UploadActionButton(
                  label: selected ? 'Replace File' : 'Files',
                  icon: Icons.file_present_outlined,
                  onPressed: onFilesTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadActionButton extends StatelessWidget {
  const _UploadActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.55),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Any additional details...',
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.30),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.fromLTRB(15, 12, 15, 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.16)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: _kBrandTeal, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          isLoading ? 'Submitting...' : 'Submit Verification',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DocumentTypeOption {
  const _DocumentTypeOption({required this.label, required this.value});

  final String label;
  final String value;
}
