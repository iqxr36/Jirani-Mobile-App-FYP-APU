import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/viewmodels/verification_viewmodel.dart';
import 'package:fyp_flutter_application/views/verification/verification_pending_view.dart';
import 'package:fyp_flutter_application/widgets/custom_button.dart';
import 'package:fyp_flutter_application/widgets/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class UploadVerificationDocumentView extends StatefulWidget {
  const UploadVerificationDocumentView({super.key});

  @override
  State<UploadVerificationDocumentView> createState() => _UploadVerificationDocumentViewState();
}

class _UploadVerificationDocumentViewState extends State<UploadVerificationDocumentView> {
  final _formKey = GlobalKey<FormState>();
  final _communityController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();

  String _documentType = AppConstants.documentTypeUtilityBill;
  final _imagePicker = ImagePicker();

  Uint8List? _fileBytes;
  String? _fileDisplayName;
  /// Normalized extension without dot: jpg, png, heic, pdf, …
  String? _fileExtension;
  /// Used on IO for Storage [putFile]; unused on web (blob paths are not real files).
  String? _localFilePath;

  static const List<({String value, String label})> _types = [
    (value: AppConstants.documentTypeUtilityBill, label: 'Utility Bill'),
    (value: AppConstants.documentTypeTenancyAgreement, label: 'Tenancy Agreement'),
    (value: AppConstants.documentTypeAccessCard, label: 'Access Card'),
    (value: AppConstants.documentTypeOtherProof, label: 'Other Proof'),
  ];

  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'pdf',
  };

  /// Browser / Flutter Web can decode these for [Image.memory]; never HEIC/PDF/unknown.
  static bool _canPreviewAsRasterImage(String? ext) {
    if (ext == null) return false;
    return ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp';
  }

  static String? _normalizeExtension(String fileName) {
    final base = fileName.split(RegExp(r'[/\\]')).last;
    final dot = base.lastIndexOf('.');
    if (dot == -1 || dot >= base.length - 1) return null;
    return base.substring(dot + 1).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _typeLabel(String? ext) {
    if (ext == null || ext.isEmpty) return 'Unknown';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'JPEG image';
      case 'png':
        return 'PNG image';
      case 'webp':
        return 'WebP image';
      case 'heic':
        return 'HEIC image';
      case 'pdf':
        return 'PDF document';
      default:
        return ext.toUpperCase();
    }
  }

  @override
  void dispose() {
    _communityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearFile() {
    setState(() {
      _fileBytes = null;
      _fileDisplayName = null;
      _fileExtension = null;
      _localFilePath = null;
    });
  }

  bool _rejectIfUnsupported(String? ext) {
    if (ext == null || ext.isEmpty || !_allowedExtensions.contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only JPG, PNG, WEBP, HEIC, or PDF files are supported.'),
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return;

    final ext = _normalizeExtension(xFile.name);
    if (_rejectIfUnsupported(ext)) return;

    final bytes = await xFile.readAsBytes();
    if (!mounted) return;

    setState(() {
      _fileBytes = bytes;
      _fileDisplayName = xFile.name.isNotEmpty ? xFile.name : 'image.jpg';
      _fileExtension = ext;
      _localFilePath = xFile.path.isNotEmpty ? xFile.path : null;
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final f = result.files.single;
    final ext = _normalizeExtension(f.name.isNotEmpty ? f.name : 'file.pdf');
    if (_rejectIfUnsupported(ext)) return;

    var bytes = f.bytes;
    bytes ??= f.path != null ? await _tryReadBytesFromPath(f.path!) : null;

    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the PDF. Try again or pick a smaller file.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _fileBytes = bytes;
      _fileDisplayName = f.name.isNotEmpty ? f.name : 'document.pdf';
      _fileExtension = ext;
      _localFilePath = f.path;
    });
  }

  Future<Uint8List?> _tryReadBytesFromPath(String path) async {
    try {
      final x = XFile(path);
      return await x.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> _showSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Choose PDF / document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fileBytes == null || _fileBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document or photo.')),
      );
      return;
    }

    final verificationVm = context.read<VerificationViewModel>();
    final authVm = context.read<AuthViewModel>();
    verificationVm.clearError();

    final originalName = _fileDisplayName ?? 'upload.jpg';

    final result = await verificationVm.submitVerificationRequest(
      documentType: _documentType,
      fileBytes: _fileBytes!,
      originalFileName: originalName,
      localFilePath: _localFilePath,
      communityName: _communityController.text.trim(),
      unitNumber: _unitController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (result != null) {
      await authVm.refreshCurrentUser();
      await verificationVm.loadCurrentRequest();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const VerificationPendingView()),
        (route) => route.isFirst,
      );
    }
  }

  Widget _buildFilePreviewOrIcon(BuildContext context) {
    final ext = _fileExtension;
    final scheme = Theme.of(context).colorScheme;

    if (_canPreviewAsRasterImage(ext) && _fileBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _fileBytes!,
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.image_not_supported_outlined, color: scheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Preview unavailable for this image.'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    if (ext == 'pdf') {
      return Icon(Icons.picture_as_pdf, size: 64, color: scheme.primary);
    }

    if (ext == 'heic') {
      return Icon(Icons.image_outlined, size: 64, color: scheme.primary);
    }

    return Icon(Icons.insert_drive_file_outlined, size: 56, color: scheme.outline);
  }

  Widget _buildSelectedFileCard(BuildContext context, bool loading) {
    final scheme = Theme.of(context).colorScheme;
    final ext = _fileExtension;
    final name = _fileDisplayName ?? 'file';
    final sizeStr = _fileBytes != null ? _formatBytes(_fileBytes!.length) : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _buildFilePreviewOrIcon(context)),
            if (ext == 'heic' && kIsWeb) ...[
              const SizedBox(height: 12),
              Text(
                'HEIC preview is not supported in browser, but the file can still be submitted.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text('Type: ${_typeLabel(ext)}'),
                      Text('Size: $sizeStr'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: loading ? null : () => _showSourceSheet(),
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  label: const Text('Change file'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: loading ? null : _clearFile,
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verificationVm = context.watch<VerificationViewModel>();
    final hasFile = _fileBytes != null && _fileBytes!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload proof')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _documentType,
                  decoration: const InputDecoration(
                    labelText: 'Document type',
                    border: OutlineInputBorder(),
                  ),
                  items: _types
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.value,
                          child: Text(e.label),
                        ),
                      )
                      .toList(),
                  onChanged: verificationVm.isLoading
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _documentType = v);
                        },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _communityController,
                  labelText: 'Community / building name',
                  validator: (v) => Validators.validateRequiredField(v, fieldName: 'Community name'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _unitController,
                  labelText: 'Unit number',
                  validator: (v) => Validators.validateRequiredField(v, fieldName: 'Unit number'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _notesController,
                  labelText: 'Notes (optional)',
                ),
                const SizedBox(height: 20),
                Text('Document or photo', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (!hasFile)
                  Card(
                    child: InkWell(
                      onTap: verificationVm.isLoading ? null : _showSourceSheet,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.upload_file_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to add photo, image, or PDF',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _buildSelectedFileCard(context, verificationVm.isLoading),
                if (verificationVm.uploadProgress > 0 && verificationVm.uploadProgress < 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(value: verificationVm.uploadProgress),
                  ),
                if (verificationVm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(verificationVm.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Submit for Verification',
                  isLoading: verificationVm.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
