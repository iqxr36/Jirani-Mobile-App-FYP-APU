// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_services_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

library;

import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/payment_provider.dart';
import 'package:jirani/resident/providers/review_provider.dart';
import 'package:jirani/resident/providers/service_provider.dart' as services;
import 'package:jirani/resident/screens/profile/payment_methods_view.dart';
import 'package:jirani/resident/screens/profile/public_resident_profile_view.dart';
import 'package:jirani/resident/widgets/resident_transaction_widgets.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/providers/auth_provider.dart';
import 'package:jirani/shared/utils/display_labels.dart';
import 'package:jirani/shared/utils/service_availability.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

part 'services/resident_services_browse.dart';
part 'services/service_detail_view.dart';
part 'services/service_transaction_view.dart';
part 'services/service_request_sheet.dart';
part 'services/service_list_widgets.dart';
part 'services/service_helpers.dart';

enum _MyServiceTab { listed, incoming }

class ResidentMyServicesView extends StatefulWidget {
  const ResidentMyServicesView({super.key});

  @override
  State<ResidentMyServicesView> createState() => _ResidentMyServicesViewState();
}

class _ResidentMyServicesViewState extends State<ResidentMyServicesView> {
  _MyServiceTab _tab = _MyServiceTab.listed;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final sideInset = JiraniResponsive.scaled(context, 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: ResidentInsetContent(
                  sideInset: sideInset,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      ResidentScreenTitleBar(
                        title: 'My Services',
                        onBack: () => Navigator.of(context).pop(),
                        trailing: ResidentCircleIconButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Create service',
                          onTap: user == null
                              ? () => _showSnack(
                                  context,
                                  'Sign in before listing a service.',
                                )
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ResidentAddNewServiceView(user: user),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MyServicesSummary(user: user),
                      const SizedBox(height: 14),
                      _MyServicesTabs(
                        selected: _tab,
                        onChanged: (tab) => setState(() => _tab = tab),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              if (user == null)
                SliverToBoxAdapter(
                  child: _ServiceInsetCard(
                    sideInset: sideInset,
                    child: const ResidentStateCard(
                      icon: Icons.lock_outline_rounded,
                      title: 'Sign in required',
                      message:
                          'Sign in to manage service listings and requests.',
                    ),
                  ),
                )
              else if (_tab == _MyServiceTab.listed)
                _MyServiceListings(user: user, sideInset: sideInset)
              else
                _ServiceRequestsSliver(
                  user: user,
                  requesterView: false,
                  sideInset: sideInset,
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class ResidentAddNewServiceView extends StatefulWidget {
  const ResidentAddNewServiceView({
    super.key,
    required this.user,
    this.service,
  });

  final AppUser user;
  final ServiceModel? service;

  @override
  State<ResidentAddNewServiceView> createState() =>
      _ResidentAddNewServiceViewState();
}

class _ResidentAddNewServiceViewState extends State<ResidentAddNewServiceView> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _pricingFormKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _picker = ImagePicker();
  final _jobPhotos = <XFile>[];
  final _certificates = <_ServiceCertificateDraft>[];
  final _availableDays = <int>{1, 2, 3, 4, 5};
  var _category = AppConstants.serviceCategoryHomeCleaningUpkeep;
  var _pricingMode = AppConstants.servicePricingModeHourly;
  var _startTime = const TimeOfDay(hour: 9, minute: 0);
  var _endTime = const TimeOfDay(hour: 17, minute: 0);
  var _step = 0;
  var _submitting = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    if (service == null) return;
    _title.text = service.title;
    _description.text = service.description;
    _category = service.category.isEmpty
        ? AppConstants.serviceCategoryHomeCleaningUpkeep
        : service.category;
    _pricingMode = service.pricingMode.isEmpty
        ? AppConstants.servicePricingModeHourly
        : service.pricingMode;
    final amount =
        service.pricingMode == AppConstants.servicePricingModeFixedJob
        ? service.fixedJobPrice ?? service.priceAmount
        : service.hourlyRate ?? service.priceAmount;
    if (amount != null) _price.text = _serviceAmountText(amount);
    if (service.availableWeekdays.isNotEmpty &&
        service.availabilityEndMinutes > service.availabilityStartMinutes) {
      _availableDays
        ..clear()
        ..addAll(service.availableWeekdays);
      _startTime = TimeOfDay(
        hour: service.availabilityStartMinutes ~/ 60,
        minute: service.availabilityStartMinutes % 60,
      );
      _endTime = TimeOfDay(
        hour: service.availabilityEndMinutes ~/ 60,
        minute: service.availabilityEndMinutes % 60,
      );
    } else {
      _applyAvailability(service.availability);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  bool get _isHourly => _pricingMode == AppConstants.servicePricingModeHourly;

  bool get _hasValidAvailability {
    return _availableDays.isNotEmpty &&
        _timeMinutes(_endTime) > _timeMinutes(_startTime);
  }

  String _availabilityText(BuildContext context) {
    final days = _availableDays.toList()..sort();
    final dayText = days.map(_dayShortLabel).join(', ');
    final localizations = MaterialLocalizations.of(context);
    return '$dayText, ${localizations.formatTimeOfDay(_startTime)} - '
        '${localizations.formatTimeOfDay(_endTime)}';
  }

  void _applyAvailability(String value) {
    final lower = value.toLowerCase();
    final days = <int>{};
    for (final day in _availabilityDays) {
      if (lower.contains(day.label.toLowerCase())) {
        days.add(day.value);
      }
    }
    if (days.isNotEmpty) {
      _availableDays
        ..clear()
        ..addAll(days);
    }
    final timeMatch = RegExp(
      r'(\d{1,2}):(\d{2})\s*([ap]m)\s*-\s*(\d{1,2}):(\d{2})\s*([ap]m)',
      caseSensitive: false,
    ).firstMatch(value);
    if (timeMatch == null) return;
    final start = _parseServiceTime(
      timeMatch.group(1),
      timeMatch.group(2),
      timeMatch.group(3),
    );
    final end = _parseServiceTime(
      timeMatch.group(4),
      timeMatch.group(5),
      timeMatch.group(6),
    );
    if (start != null) _startTime = start;
    if (end != null) _endTime = end;
  }

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);
    final title = _step == 0
        ? (_isEditing ? 'Edit Service' : 'Add New Service')
        : 'Service Pricing';
    const titleSize = 20.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: residentMaxContentWidth,
                    ),
                    child: Row(
                      children: [
                        _ServiceFormIconButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: _step == 0 ? 'Back' : 'Service details',
                          onTap: _submitting
                              ? null
                              : () {
                                  if (_step == 0) {
                                    Navigator.pop(context);
                                  } else {
                                    setState(() => _step = 0);
                                  }
                                },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: residentBrandTeal,
                              fontSize: titleSize,
                              fontWeight: _step == 0
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 56),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(sideInset, 10, sideInset, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: residentMaxContentWidth,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _step == 0
                            ? _detailsStep(context)
                            : _pricingStep(context),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: residentMaxContentWidth,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ServiceFormSecondaryButton(
                              icon: Icons.close_rounded,
                              label: 'Cancel',
                              onTap: _submitting
                                  ? null
                                  : () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ServiceFormPrimaryButton(
                              icon: _step == 0
                                  ? Icons.arrow_forward_rounded
                                  : Icons.publish_rounded,
                              label: _step == 0
                                  ? 'Next'
                                  : _submitting
                                  ? 'Publishing...'
                                  : _isEditing
                                  ? 'Save'
                                  : 'Publish',
                              onTap: _submitting
                                  ? null
                                  : () {
                                      if (_step == 0) {
                                        _continueToPricing();
                                      } else {
                                        _publish();
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailsStep(BuildContext context) {
    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ServiceFormSectionLabel('Service Photos'),
          const SizedBox(height: 8),
          _ServicePhotoPickerPanel(
            existingImageUrls: widget.service?.imageUrls ?? const <String>[],
            photos: _jobPhotos,
            onPickPhotos: _pickJobPhotos,
            onRemovePhoto: (index) =>
                setState(() => _jobPhotos.removeAt(index)),
          ),
          const SizedBox(height: 20),
          const _ServiceFormSectionLabel('Service Details'),
          const SizedBox(height: 8),
          _ServiceFormGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: Validators.validateServiceTitle,
                  decoration: context.residentInputDecoration(
                    label: 'Service Name',
                    hint: 'e.g. Weekend math tutoring',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: context.residentInputDecoration(
                          label: 'Category',
                          hint: 'Select category',
                        ),
                        items: _serviceCategories.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _category = value ?? _category;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _pricingMode,
                        isExpanded: true,
                        decoration: context.residentInputDecoration(
                          label: 'Pricing',
                          hint: 'Select pricing',
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: AppConstants.servicePricingModeHourly,
                            child: Text(
                              'Hourly',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: AppConstants.servicePricingModeFixedJob,
                            child: Text(
                              'Fixed Job',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _pricingMode = value ?? _pricingMode;
                          _price.clear();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  minLines: 5,
                  maxLines: 7,
                  maxLength: AppConstants.maxListingDescriptionLength,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: Validators.validateServiceDescription,
                  decoration: context.residentInputDecoration(
                    label: 'Description',
                    hint:
                        'Describe your experience, scope, and what is included.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _ServiceFormSectionLabel('Availability'),
          const SizedBox(height: 8),
          _AvailabilityPicker(
            selectedDays: _availableDays,
            startTime: _startTime,
            endTime: _endTime,
            onToggleDay: _toggleAvailableDay,
            onSetDays: _setAvailableDays,
            onPickStart: _pickStartTime,
            onPickEnd: _pickEndTime,
          ),
          const SizedBox(height: 20),
          const _ServiceFormSectionLabel('Certificates'),
          const SizedBox(height: 8),
          _CertificatePickerSection(
            existingNames: widget.service?.certificateNames ?? const <String>[],
            existingUrls: widget.service?.certificateUrls ?? const <String>[],
            certificates: _certificates,
            onAdd: _pickCertificates,
            onRemove: (index) => setState(() => _certificates.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _pricingStep(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser ?? widget.user;
    return Form(
      key: _pricingFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ServiceFormSectionLabel('Service Pricing'),
          const SizedBox(height: 8),
          _ServiceFormGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => Validators.validatePositiveAmount(
                    value,
                    fieldName: _isHourly ? 'Hourly rate' : 'Fixed job price',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: context
                      .residentInputDecoration(
                        label: _isHourly
                            ? 'Hourly rate (RM)'
                            : 'Fixed job price (RM)',
                        hint: '0.00',
                      )
                      .copyWith(
                        prefixIcon: Container(
                          width: 44,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.10),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(14),
                            ),
                          ),
                          child: Text(
                            'RM',
                            style: TextStyle(
                              color: context.appInk,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: residentBrandTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isHourly
                        ? 'Hourly services are paid based on the duration selected by the requester.'
                        : 'Payment is collected after you accept a request.',
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
                if (!user.hasVerifiedPayoutAccount) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: residentBrandTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Paid services need a verified payout account before publishing.',
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ServiceFormSecondaryButton(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Open Payments',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PaymentMethodsView(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _continueToPricing() {
    if (!(_detailsFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_hasValidAvailability) {
      _showSnack(context, 'Select valid availability before continuing.');
      return;
    }
    setState(() => _step = 1);
  }

  void _toggleAvailableDay(int day) {
    setState(() {
      if (_availableDays.contains(day)) {
        _availableDays.remove(day);
      } else {
        _availableDays.add(day);
      }
    });
  }

  void _setAvailableDays(Set<int> days) {
    setState(() {
      _availableDays
        ..clear()
        ..addAll(days);
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked == null) return;
    setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked == null) return;
    setState(() => _endTime = picked);
  }

  Future<void> _pickJobPhotos() async {
    final picked = await _picker.pickMultiImage(imageQuality: 82);
    if (picked.isEmpty) return;
    setState(() {
      final existingCount = widget.service?.imageUrls.length ?? 0;
      final remaining = 6 - existingCount - _jobPhotos.length;
      if (remaining <= 0) return;
      _jobPhotos.addAll(picked.take(remaining));
    });
  }

  Future<void> _pickCertificates() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    );
    if (result == null) return;
    setState(() {
      final existingCount = widget.service?.certificateUrls.length ?? 0;
      final remaining = 5 - existingCount - _certificates.length;
      if (remaining <= 0) return;
      _certificates.addAll(
        result.files
            .where((file) => file.path != null)
            .take(remaining)
            .map(
              (file) =>
                  _ServiceCertificateDraft(name: file.name, path: file.path!),
            ),
      );
    });
  }

  Future<void> _publish() async {
    if (!(_pricingFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final provider = context.read<AuthProvider>().currentUser ?? widget.user;
    final parsedPrice = double.tryParse(_price.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      _showSnack(context, 'Enter a valid price amount.');
      return;
    }
    if (!provider.hasVerifiedPayoutAccount) {
      _showSnack(
        context,
        'Verify your payout profile before publishing paid services.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final serviceProvider = context.read<services.ServiceProvider>();
      final service = widget.service;
      if (service == null) {
        await serviceProvider.createService(
          provider: provider,
          title: _title.text,
          description: _description.text,
          category: _category,
          priceType: AppConstants.servicePriceTypeFixed,
          priceAmount: parsedPrice,
          pricingMode: _pricingMode,
          hourlyRate: _isHourly ? parsedPrice : null,
          fixedJobPrice: _isHourly ? null : parsedPrice,
          availability: _availabilityText(context),
          availableWeekdays: _availableDays,
          availabilityStartTime: _startTime,
          availabilityEndTime: _endTime,
          imagePaths: _jobPhotos.map((photo) => photo.path).toList(),
          certificatePaths: _certificates
              .map((certificate) => certificate.path)
              .toList(),
          certificateNames: _certificates
              .map((certificate) => certificate.name)
              .toList(),
        );
      } else {
        await serviceProvider.updateService(
          provider: provider,
          service: service,
          title: _title.text,
          description: _description.text,
          category: _category,
          priceType: AppConstants.servicePriceTypeFixed,
          priceAmount: parsedPrice,
          pricingMode: _pricingMode,
          hourlyRate: _isHourly ? parsedPrice : null,
          fixedJobPrice: _isHourly ? null : parsedPrice,
          availability: _availabilityText(context),
          availableWeekdays: _availableDays,
          availabilityStartTime: _startTime,
          availabilityEndTime: _endTime,
          imagePaths: _jobPhotos.map((photo) => photo.path).toList(),
          certificatePaths: _certificates
              .map((certificate) => certificate.path)
              .toList(),
          certificateNames: _certificates
              .map((certificate) => certificate.name)
              .toList(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ServiceCertificateDraft {
  const _ServiceCertificateDraft({required this.name, required this.path});

  final String name;
  final String path;
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: residentBrandTeal, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.appInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceAddButton extends StatelessWidget {
  const _ServiceAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = JiraniResponsive.scaled(context, 56);
    return Material(
      color: residentBrandTeal,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onPrimary,
            size: JiraniResponsive.scaled(context, 30),
          ),
        ),
      ),
    );
  }
}

class _ServiceFormIconButton extends StatelessWidget {
  const _ServiceFormIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: residentBrandTeal, size: 30),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityPicker extends StatelessWidget {
  const _AvailabilityPicker({
    required this.selectedDays,
    required this.startTime,
    required this.endTime,
    required this.onToggleDay,
    required this.onSetDays,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final Set<int> selectedDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<int> onToggleDay;
  final ValueChanged<Set<int>> onSetDays;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final invalidTime = _timeMinutes(endTime) <= _timeMinutes(startTime);
    final summary = selectedDays.isEmpty
        ? 'Choose available days'
        : 'Available ${_availabilityDaySummary(selectedDays)}, '
              '${localizations.formatTimeOfDay(startTime)} - '
              '${localizations.formatTimeOfDay(endTime)}';

    return _ServiceFormGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: residentBrandTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: residentBrandTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Set when residents can request this service.',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AvailabilityPresetChip(
                label: 'Everyday',
                selected: _sameDays(selectedDays, _everydayDays),
                onTap: () => onSetDays(_everydayDays),
              ),
              _AvailabilityPresetChip(
                label: 'Weekdays',
                selected: _sameDays(selectedDays, _weekdayDays),
                onTap: () => onSetDays(_weekdayDays),
              ),
              _AvailabilityPresetChip(
                label: 'Weekends',
                selected: _sameDays(selectedDays, _weekendDays),
                onTap: () => onSetDays(_weekendDays),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final day in _availabilityDays)
                _DayChoiceChip(
                  label: day.label,
                  selected: selectedDays.contains(day.value),
                  onTap: () => onToggleDay(day.value),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackTimes = constraints.maxWidth < 330;
              final startField = _TimeChoiceField(
                label: 'Start Time',
                value: localizations.formatTimeOfDay(startTime),
                onTap: onPickStart,
                hasError: invalidTime,
              );
              final endField = _TimeChoiceField(
                label: 'End Time',
                value: localizations.formatTimeOfDay(endTime),
                onTap: onPickEnd,
                hasError: invalidTime,
              );
              if (stackTimes) {
                return Column(
                  children: [startField, const SizedBox(height: 10), endField],
                );
              }
              return Row(
                children: [
                  Expanded(child: startField),
                  const SizedBox(width: 10),
                  Expanded(child: endField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: invalidTime || selectedDays.isEmpty
                  ? Theme.of(context).colorScheme.error.withValues(alpha: 0.08)
                  : residentBrandTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: invalidTime || selectedDays.isEmpty
                    ? Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.24)
                    : residentBrandTeal.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  invalidTime || selectedDays.isEmpty
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: invalidTime || selectedDays.isEmpty
                      ? Theme.of(context).colorScheme.error
                      : residentBrandTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDays.isEmpty
                        ? 'Choose at least one available day.'
                        : invalidTime
                        ? 'End time must be after start time.'
                        : summary,
                    style: TextStyle(
                      color: invalidTime || selectedDays.isEmpty
                          ? Theme.of(context).colorScheme.error
                          : context.appInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPresetChip extends StatelessWidget {
  const _AvailabilityPresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? residentBrandTeal.withValues(alpha: 0.12)
          : context.softSurface(),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? residentBrandTeal : context.residentOutline(),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? residentBrandTeal : context.appInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChoiceChip extends StatelessWidget {
  const _DayChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? residentBrandTeal
          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minWidth: 46, minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? residentBrandTeal : context.residentOutline(),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : context.appInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeChoiceField extends StatelessWidget {
  const _TimeChoiceField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.hasError,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: context
            .residentInputDecoration(label: label, hint: 'Choose time')
            .copyWith(
              errorText: hasError ? '' : null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.schedule_rounded,
              color: residentBrandTeal,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceFormSectionLabel extends StatelessWidget {
  const _ServiceFormSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.appInk,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ServiceFormGlassPanel extends StatelessWidget {
  const _ServiceFormGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 22),
        ),
        border: Border.all(color: context.glassBorder()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkUi ? 0.24 : 0.09,
            ),
            blurRadius: JiraniResponsive.scaled(context, 24),
            offset: Offset(0, JiraniResponsive.scaled(context, 12)),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _ServicePhotoPickerPanel extends StatelessWidget {
  const _ServicePhotoPickerPanel({
    required this.existingImageUrls,
    required this.photos,
    required this.onPickPhotos,
    required this.onRemovePhoto,
  });

  final List<String> existingImageUrls;
  final List<XFile> photos;
  final VoidCallback onPickPhotos;
  final ValueChanged<int> onRemovePhoto;

  int get _photoCount => existingImageUrls.length + photos.length;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final isDark = context.isDarkUi;

    return InkWell(
      onTap: onPickPhotos,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 212),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.glassFill(lightAlpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _photoCount == 0
                ? (isDark
                      ? Theme.of(context).colorScheme.outlineVariant
                      : Colors.black.withValues(alpha: 0.30))
                : residentBrandTeal.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _photoCount == 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _ServiceCameraBadge(),
                  const SizedBox(height: 12),
                  Text(
                    'Upload your Service (Up to 6)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to choose your photos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _ServiceCameraBadge(size: 42),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$_photoCount of 6 photos selected',
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _photoCount >= 6 ? null : onPickPhotos,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 102,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photoCount,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index < existingImageUrls.length) {
                          return _ServicePhotoThumb(
                            url: existingImageUrls[index],
                          );
                        }
                        final localIndex = index - existingImageUrls.length;
                        return _ServicePhotoThumb(
                          path: photos[localIndex].path,
                          onRemove: () => onRemovePhoto(localIndex),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ServiceCameraBadge extends StatelessWidget {
  const _ServiceCameraBadge({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.avatarPlaceholder,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(
        Icons.photo_camera_rounded,
        color: scheme.onPrimaryContainer,
        size: size * 0.58,
      ),
    );
  }
}

class _ServicePhotoThumb extends StatelessWidget {
  const _ServicePhotoThumb({this.path, this.url, this.onRemove});

  final String? path;
  final String? url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 102,
            height: 102,
            color: residentBrandTeal.withValues(alpha: 0.08),
            child: path != null
                ? Image.file(File(path!), fit: BoxFit.cover)
                : url != null && url!.isNotEmpty
                ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
                : const Icon(
                    Icons.home_repair_service_outlined,
                    color: residentBrandTeal,
                  ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: 6,
            top: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.56),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CertificatePickerSection extends StatelessWidget {
  const _CertificatePickerSection({
    required this.existingNames,
    required this.existingUrls,
    required this.certificates,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> existingNames;
  final List<String> existingUrls;
  final List<_ServiceCertificateDraft> certificates;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  int get _certificateCount => existingUrls.length + certificates.length;

  @override
  Widget build(BuildContext context) {
    return _ServiceFormGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: residentBrandTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: residentBrandTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add licenses, course certificates, or work credentials residents can review.',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_certificateCount == 0)
            _CertificateUploadCard(onTap: onAdd)
          else ...[
            for (var i = 0; i < existingUrls.length; i += 1)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == existingUrls.length - 1 && certificates.isEmpty
                      ? 0
                      : 8,
                ),
                child: _CertificateLinkTile(
                  name: i < existingNames.length
                      ? existingNames[i]
                      : 'Certificate ${i + 1}',
                  url: existingUrls[i],
                ),
              ),
            for (var i = 0; i < certificates.length; i += 1)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == certificates.length - 1 ? 0 : 8,
                ),
                child: _CertificateDraftTile(
                  certificate: certificates[i],
                  onRemove: () => onRemove(i),
                ),
              ),
            const SizedBox(height: 10),
            _ServiceFormSecondaryButton(
              icon: Icons.upload_file_outlined,
              label: _certificateCount >= 5 ? 'Limit Reached' : 'Add More',
              onTap: _certificateCount >= 5 ? null : onAdd,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Self-provided credentials are displayed to residents but not admin-verified in V1.',
            style: TextStyle(
              color: context.appMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateUploadCard extends StatelessWidget {
  const _CertificateUploadCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.softSurface(),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.residentOutline()),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: residentBrandTeal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: residentBrandTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add certificates',
                    style: TextStyle(
                      color: context.appInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF, JPG, PNG, WEBP, HEIC. Up to 5 files.',
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.add_rounded, color: residentBrandTeal),
          ],
        ),
      ),
    );
  }
}

class _ServiceFormPrimaryButton extends StatelessWidget {
  const _ServiceFormPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: disabled
          ? scheme.onSurface.withValues(alpha: 0.38)
          : residentBrandTeal,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.onPrimary, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceFormSecondaryButton extends StatelessWidget {
  const _ServiceFormSecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.softSurface(),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.residentOutline()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: residentBrandTeal, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDangerButton extends StatelessWidget {
  const _ServiceDangerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final danger = Theme.of(context).colorScheme.error;
    return Material(
      color: disabled
          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.16)
          : danger.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: disabled
                  ? context.residentOutline()
                  : danger.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: disabled ? context.appMuted : danger, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? context.appMuted : danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateDraftTile extends StatelessWidget {
  const _CertificateDraftTile({
    required this.certificate,
    required this.onRemove,
  });

  final _ServiceCertificateDraft certificate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            color: residentBrandTeal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              certificate.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appInk,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove certificate',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _CertificateLinkTile extends StatelessWidget {
  const _CertificateLinkTile({required this.name, required this.url});

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          _openCertificatePreview(context: context, name: name, url: url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.softSurface(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.residentOutline()),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: residentBrandTeal,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name.trim().isEmpty ? 'Certificate' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.visibility_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CertificateImagePreviewScreen extends StatelessWidget {
  const _CertificateImagePreviewScreen({required this.name, required this.url});

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    final title = _certificateTitle(name);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, _) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 52,
            ),
          ),
        ),
      ),
    );
  }
}

class _CertificatePdfPreviewScreen extends StatefulWidget {
  const _CertificatePdfPreviewScreen({
    required this.filePath,
    required this.name,
  });

  final String filePath;
  final String name;

  @override
  State<_CertificatePdfPreviewScreen> createState() =>
      _CertificatePdfPreviewScreenState();
}

class _CertificatePdfPreviewScreenState
    extends State<_CertificatePdfPreviewScreen> {
  late final PdfControllerPinch _pdfController;
  int _currentPage = 1;
  int? _pagesCount;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagesCount = _pagesCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: residentBrandTeal,
        foregroundColor: Colors.white,
        title: Text(
          _certificateTitle(widget.name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (pagesCount != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_currentPage / $pagesCount',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: PdfViewPinch(
        controller: _pdfController,
        onDocumentLoaded: (document) {
          setState(() => _pagesCount = document.pagesCount);
        },
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        onDocumentError: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open this certificate.')),
          );
        },
      ),
    );
  }
}

class _CertificateProgressDialog extends StatelessWidget {
  const _CertificateProgressDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyServicesSummary extends StatelessWidget {
  const _MyServicesSummary({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return ResidentGlassPanel(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provider Dashboard',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.hasVerifiedPayoutAccount == true
                    ? 'Manage service listings and incoming bookings.'
                    : 'Verify payout profile before publishing paid services.',
                style: TextStyle(
                  color: context.appMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          );
          final status = ResidentStatusPill(
            label: user?.hasVerifiedPayoutAccount == true
                ? 'Payout Ready'
                : 'Setup Needed',
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResidentIconTile(
                icon: Icons.home_repair_service_outlined,
                size: compact ? 42 : 46,
              ),
              const SizedBox(width: 12),
              Expanded(child: details),
              const SizedBox(width: 10),
              if (!compact) status,
              if (compact)
                Padding(padding: const EdgeInsets.only(top: 2), child: status),
            ],
          );
        },
      ),
    );
  }
}

class _MyServicesTabs extends StatelessWidget {
  const _MyServicesTabs({required this.selected, required this.onChanged});

  final _MyServiceTab selected;
  final ValueChanged<_MyServiceTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return ResidentGlassPanel(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _MyServiceTabButton(
              label: 'My Listed Services',
              selected: selected == _MyServiceTab.listed,
              onTap: () => onChanged(_MyServiceTab.listed),
            ),
          ),
          Expanded(
            child: _MyServiceTabButton(
              label: 'Incoming Requests',
              selected: selected == _MyServiceTab.incoming,
              onTap: () => onChanged(_MyServiceTab.incoming),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyServiceTabButton extends StatelessWidget {
  const _MyServiceTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? residentBrandTeal.withValues(alpha: 0.14)
          : context.softSurface(),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: residentBrandTeal) : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? residentBrandTeal : context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
