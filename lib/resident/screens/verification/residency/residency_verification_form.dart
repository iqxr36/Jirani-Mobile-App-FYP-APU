part of '../residency_verification_view.dart';

// Residency verification UI feature: document upload form for proving community residency.
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

// Residency verification UI feature: stateful form for community, unit, proof document, and notes.
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

  // Residency verification UI feature: splits stored unit number into editable building/floor/unit fields.
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

  // Residency verification UI feature: combines unit fields into the stored unit number format.
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

  // Residency verification UI feature: picks an image proof from gallery for allowed document types.
  Future<void> _pickFromGallery() async {
    final documentType = _documentType;
    if (documentType == null) {
      _showMessage('Select a document type before uploading.');
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

  // Residency verification UI feature: picks an image/PDF proof from the file picker.
  Future<void> _pickFromFiles() async {
    final documentType = _documentType;
    if (documentType == null) {
      _showMessage('Select a document type before uploading.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensionsFor(),
      withData: true,
    );
    if (!mounted) return;

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
    if (!_allowedExtensionsFor().contains(extension)) {
      _showMessage(_unsupportedFileTypeMessage());
      return;
    }

    setState(() {
      _fileBytes = bytes;
      _fileName = file.name;
      _localFilePath = file.path;
    });
  }

  // Residency verification UI feature: opens the proof document type selector.
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
        if (!_isCurrentFileAllowedFor()) {
          _fileName = null;
          _localFilePath = null;
          _fileBytes = null;
        }
      });
    }
  }

  // Residency verification UI feature: validates fields, uploads proof, and submits the verification request.
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
      _showMessage('Choose a document smaller than 25 MB.');
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

  // Residency verification UI feature: converts document type value to user-facing label.
  String _documentTypeLabel(String? value) {
    for (final option in _documentTypes) {
      if (option.value == value) return option.label;
    }
    return 'Select document type';
  }

  // Residency verification UI feature: checks whether the selected proof type can be captured from gallery.
  bool _allowsImageUpload() {
    return true;
  }

  // Residency verification UI feature: returns accepted file extensions for the selected proof type.
  List<String> _allowedExtensionsFor() {
    return _kImageAndPdfDocumentExtensions;
  }

  // Residency verification UI feature: formats accepted file extensions for helper text.
  String _acceptedFormatsLabel(String? documentType) {
    if (documentType == null) return 'Select a document type first.';
    return 'Accepted formats: JPG, PNG, WEBP, HEIC, HEIF, or PDF.';
  }

  // Residency verification UI feature: builds the upload error message for unsupported proof files.
  String _unsupportedFileTypeMessage() {
    return 'Only JPG, PNG, WEBP, HEIC, HEIF, or PDF files are supported.';
  }

  // Residency verification UI feature: verifies the selected proof file still matches the selected document type.
  bool _isCurrentFileAllowedFor() {
    final fileName = _fileName;
    if (fileName == null) return true;
    return _allowedExtensionsFor().contains(_fileExtension(fileName));
  }

  // Residency verification UI feature: extracts a lowercase file extension from the picked proof filename.
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
        documentType != null && _allowsImageUpload();

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
                          Text(
                            'Please provide your residency details and upload a supporting document to complete verification.',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: context.appInk,
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
