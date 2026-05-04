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
  XFile? _pickedFile;
  final _picker = ImagePicker();

  static const List<({String value, String label})> _types = [
    (value: AppConstants.documentTypeUtilityBill, label: 'Utility Bill'),
    (value: AppConstants.documentTypeTenancyAgreement, label: 'Tenancy Agreement'),
    (value: AppConstants.documentTypeAccessCard, label: 'Access Card'),
    (value: AppConstants.documentTypeOtherProof, label: 'Other Proof'),
  ];

  @override
  void dispose() {
    _communityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() => _pickedFile = file);
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
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
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

    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document or photo.')),
      );
      return;
    }

    final verificationVm = context.read<VerificationViewModel>();
    final authVm = context.read<AuthViewModel>();
    verificationVm.clearError();

    final path = _pickedFile!.path;
    final result = await verificationVm.submitVerificationRequest(
      documentType: _documentType,
      filePath: path,
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

  @override
  Widget build(BuildContext context) {
    final verificationVm = context.watch<VerificationViewModel>();

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
                Card(
                  child: InkWell(
                    onTap: verificationVm.isLoading ? null : _showSourceSheet,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.upload_file_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            _pickedFile == null
                                ? 'Tap to upload proof of residence'
                                : _pickedFile!.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
