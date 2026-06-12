import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/viewmodels/verification_viewmodel.dart';
import 'package:jirani/views/verification/verification_status_view.dart';
import 'package:jirani/widgets/common/jirani_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 357;
const int _kMaxDocumentBytes = 10 * 1024 * 1024;
const _kAllowedDocumentExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

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
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();
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
      _unitController.text = unitNumber;
    }
  }

  @override
  void dispose() {
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _kAllowedDocumentExtensions,
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
      setState(() => _documentType = selected);
    }
  }

  Future<void> _submit() async {
    final user = context.read<AuthViewModel>().currentUser;
    final communityName = user?.communityName.trim() ?? '';
    final unitNumber = _unitController.text.trim();
    final documentType = _documentType;
    final bytes = _fileBytes;
    final fileName = _fileName;

    if (communityName.isEmpty) {
      _showMessage('Select your community before submitting verification.');
      return;
    }
    if (unitNumber.isEmpty) {
      _showMessage('Enter your unit number.');
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final verificationVm = context.watch<VerificationViewModel>();
    final hasCommunity = user?.communityName.trim().isNotEmpty == true;
    final communityName = hasCommunity
        ? user!.communityName.trim()
        : 'No community selected';
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
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
                          _LineTextField(
                            controller: _unitController,
                            hintText: 'e.g. B-12-3',
                            textInputAction: TextInputAction.next,
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
                            onGalleryTap: verificationVm.isLoading
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
                        ],
                      ),
                    ),
                  ),
                  if (verificationVm.isLoading) ...[
                    LinearProgressIndicator(
                      value: verificationVm.uploadProgress == 0
                          ? null
                          : verificationVm.uploadProgress,
                      minHeight: 2,
                      color: _kBrandTeal,
                      backgroundColor: _kBrandTeal.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _SubmitButton(
                    isLoading: verificationVm.isLoading,
                    onPressed: verificationVm.isLoading ? null : _submit,
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
      height: 39,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 35, height: 39),
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

class _LineTextField extends StatelessWidget {
  const _LineTextField({
    required this.controller,
    required this.hintText,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
      ),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.30),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(9, 15, 9, 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
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
    required this.onGalleryTap,
    required this.onFilesTap,
  });

  final String? fileName;
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
                  : 'Ensure the document is clear and shows your\nname and unit number.',
              maxLines: 2,
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
      height: 34,
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
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
