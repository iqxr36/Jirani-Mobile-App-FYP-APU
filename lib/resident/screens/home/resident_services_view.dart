import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/payment_provider.dart';
import 'package:jirani/resident/providers/service_provider.dart' as services;
import 'package:jirani/resident/screens/profile/payment_methods_view.dart';
import 'package:jirani/resident/widgets/resident_transaction_widgets.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/providers/auth_provider.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum _ServiceSection { discover, bookings }

enum _MyServiceTab { listed, incoming }

const _serviceSectionOptions = [
  ResidentSectionOption(
    value: _ServiceSection.discover,
    label: 'Discover',
    icon: Icons.home_repair_service_outlined,
  ),
  ResidentSectionOption(
    value: _ServiceSection.bookings,
    label: 'Bookings',
    icon: Icons.receipt_long_rounded,
  ),
];

// Services UI feature: Firestore-backed service discovery, booking, escrow, and handshake workspace.
class ResidentServicesView extends StatefulWidget {
  const ResidentServicesView({super.key});

  @override
  State<ResidentServicesView> createState() => _ResidentServicesViewState();
}

class _ResidentServicesViewState extends State<ResidentServicesView> {
  _ServiceSection _section = _ServiceSection.discover;
  String _query = '';
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final sideInset = JiraniResponsive.scaled(context, 20);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final addButtonBottom = keyboardInset > 0
        ? keyboardInset + JiraniResponsive.scaled(context, 16)
        : bottomSafeArea + JiraniResponsive.scaled(context, 20);

    return JiraniBackground(
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                ResidentInsetContent(
                  sideInset: sideInset,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ResidentPageHeader(
                          title: 'Services',
                          subtitle: user?.hasVerifiedPayoutAccount == true
                              ? 'Book help, offer skills, and verify work face to face.'
                              : 'Paid listings require a verified payout profile.',
                        ),
                        const SizedBox(height: 18),
                        ResidentSectionSwitch<_ServiceSection>(
                          selected: _section,
                          options: _serviceSectionOptions,
                          onChanged: (value) => setState(() => _section = value),
                        ),
                        if (_section == _ServiceSection.discover) ...[
                          const SizedBox(height: 16),
                          ResidentSearchField(
                            hint: 'Search services',
                            onChanged: (value) => setState(() => _query = value),
                          ),
                          const SizedBox(height: 12),
                          ResidentCategoryChips(
                            options: _serviceCategoryOptions,
                            selected: _category,
                            onSelected: (value) =>
                                setState(() => _category = value),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: user == null
                      ? const _SignedOutState()
                      : switch (_section) {
                          _ServiceSection.discover => _DiscoverServices(
                            query: _query,
                            category: _category,
                            user: user,
                          ),
                          _ServiceSection.bookings => _ServiceRequests(
                            user: user,
                            requesterView: true,
                          ),
                        },
                ),
              ],
            ),
            Positioned(
              right: sideInset,
              bottom: addButtonBottom,
              child: _ServiceAddButton(
                onTap: () => _openAddServiceFlow(context, user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddServiceFlow(BuildContext context, AppUser? user) async {
    if (user == null) {
      _showSnack(context, 'Sign in before listing a service.');
      return;
    }
    if (!user.isVerifiedResident) {
      _showSnack(context, 'Only verified residents can list services.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResidentAddNewServiceView(user: user),
      ),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const _ServiceListView(
      children: [
        ResidentStateCard(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in required',
          message: 'Sign in to browse and manage resident services.',
        ),
      ],
    );
  }
}

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
          child: Column(
            children: [
              ResidentInsetContent(
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
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: user == null
                    ? const _ServiceListView(
                        children: [
                          ResidentStateCard(
                            icon: Icons.lock_outline_rounded,
                            title: 'Sign in required',
                            message:
                                'Sign in to manage service listings and requests.',
                          ),
                        ],
                      )
                    : _tab == _MyServiceTab.listed
                        ? _MyServiceListings(user: user)
                        : _ServiceRequests(user: user, requesterView: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResidentAddNewServiceView extends StatefulWidget {
  const ResidentAddNewServiceView({super.key, required this.user, this.service});

  final AppUser user;
  final ServiceModel? service;

  @override
  State<ResidentAddNewServiceView> createState() =>
      _ResidentAddNewServiceViewState();
}

class _ResidentAddNewServiceViewState extends State<ResidentAddNewServiceView> {
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
    _applyAvailability(service.availability);
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
    return Column(
      key: const ValueKey('service-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ServiceFormSectionLabel('Service Photos'),
        const SizedBox(height: 8),
        _ServicePhotoPickerPanel(
          existingImageUrls: widget.service?.imageUrls ?? const <String>[],
          photos: _jobPhotos,
          onPickPhotos: _pickJobPhotos,
          onRemovePhoto: (index) => setState(() => _jobPhotos.removeAt(index)),
        ),
        const SizedBox(height: 20),
        const _ServiceFormSectionLabel('Service Details'),
        const SizedBox(height: 8),
        _ServiceFormGlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                textInputAction: TextInputAction.next,
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
              TextField(
                controller: _description,
                minLines: 5,
                maxLines: 7,
                decoration: context.residentInputDecoration(
                  label: 'Description',
                  hint: 'Describe your experience, scope, and what is included.',
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
          onRemove: (index) => setState(
            () => _certificates.removeAt(index),
          ),
        ),
      ],
    );
  }

  Widget _pricingStep(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser ?? widget.user;
    return Column(
      key: const ValueKey('service-pricing'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ServiceFormSectionLabel('Service Pricing'),
        const SizedBox(height: 8),
        _ServiceFormGlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: context.residentInputDecoration(
                  label: _isHourly
                      ? 'Hourly rate (RM)'
                      : 'Fixed job price (RM)',
                  hint: '0.00',
                ).copyWith(
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
                      ? 'Hourly services can be listed now. Checkout will wait for a future agreed final amount step.'
                      : 'Fixed-job services can enter escrow after you accept a request.',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              if (!_isHourly && !user.hasVerifiedPayoutAccount) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: residentBrandTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Fixed-job paid services need a verified payout account before publishing.',
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
    );
  }

  void _continueToPricing() {
    if (_title.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        !_hasValidAvailability) {
      _showSnack(context, 'Fill in the service details before continuing.');
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
              (file) => _ServiceCertificateDraft(
                name: file.name,
                path: file.path!,
              ),
            ),
      );
    });
  }

  Future<void> _publish() async {
    final provider = context.read<AuthProvider>().currentUser ?? widget.user;
    final parsedPrice = double.tryParse(_price.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      _showSnack(context, 'Enter a valid price amount.');
      return;
    }
    if (!_isHourly && !provider.hasVerifiedPayoutAccount) {
      _showSnack(
        context,
        'Verify your payout profile before publishing fixed-job services.',
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
            imagePaths: _jobPhotos.map((photo) => photo.path).toList(),
            certificatePaths:
                _certificates.map((certificate) => certificate.path).toList(),
            certificateNames:
                _certificates.map((certificate) => certificate.name).toList(),
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
          imagePaths: _jobPhotos.map((photo) => photo.path).toList(),
          certificatePaths:
              _certificates.map((certificate) => certificate.path).toList(),
          certificateNames:
              _certificates.map((certificate) => certificate.name).toList(),
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
                  children: [
                    startField,
                    const SizedBox(height: 10),
                    endField,
                  ],
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
                    ? Theme.of(context).colorScheme.error.withValues(alpha: 0.24)
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
        decoration: context.residentInputDecoration(
          label: label,
          hint: 'Choose time',
        ).copyWith(
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
                  bottom: i == existingUrls.length - 1 &&
                          certificates.isEmpty
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
              Icon(
                icon,
                color: disabled ? context.appMuted : danger,
                size: 20,
              ),
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
          const Icon(Icons.workspace_premium_outlined, color: residentBrandTeal),
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
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
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
            const Icon(Icons.workspace_premium_outlined, color: residentBrandTeal),
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
            const Icon(Icons.open_in_new_rounded, size: 18),
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
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: status,
                ),
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

class _DiscoverServices extends StatelessWidget {
  const _DiscoverServices({
    required this.query,
    required this.category,
    required this.user,
  });

  final String query;
  final String category;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<services.ServiceProvider>();
    return StreamBuilder<List<ServiceModel>>(
      stream: provider.activeServicesStream(communityId: user.communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ServiceListSkeleton();
        }
        if (snapshot.hasError) {
          return _ServiceListView(
            children: [
              ResidentStateCard(
                icon: Icons.error_outline_rounded,
                title: 'Could not load services',
                message: _friendlyServiceError(snapshot.error),
              ),
            ],
          );
        }
        final servicesList = (snapshot.data ?? const <ServiceModel>[])
            .where((service) => service.providerId != user.uid)
            .where((service) => category == 'all' || service.category == category)
            .where((service) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return service.title.toLowerCase().contains(q) ||
                  service.providerName.toLowerCase().contains(q) ||
                  service.description.toLowerCase().contains(q);
            })
            .toList();
        if (servicesList.isEmpty) {
          return const _ServiceListView(
            children: [
              ResidentStateCard(
                icon: Icons.home_repair_service_outlined,
                title: 'No services found',
                message: 'Try another search or create the first listing.',
              ),
            ],
          );
        }
        return _ServiceListView(
          children: [
            for (final service in servicesList)
              _ServiceListingCard(
                service: service,
                onTap: () => _showServiceDetail(context, user, service),
              ),
          ],
        );
      },
    );
  }
}

class _ServiceRequests extends StatelessWidget {
  const _ServiceRequests({required this.user, required this.requesterView});

  final AppUser user;
  final bool requesterView;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<services.ServiceProvider>();
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: requesterView
          ? provider.myRequestsStream(user.uid)
          : provider.incomingRequestsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ServiceListSkeleton();
        }
        final requests = snapshot.data ?? const <ServiceRequestModel>[];
        if (requests.isEmpty) {
          return _ServiceListView(
            children: [
              ResidentStateCard(
                icon: requesterView
                    ? Icons.event_available_outlined
                    : Icons.inbox_outlined,
                title: requesterView ? 'No bookings yet' : 'No incoming requests',
                message: requesterView
                    ? 'Requested services will appear here.'
                    : 'Bookings from requesters will appear here.',
              ),
            ],
          );
        }
        return _ServiceListView(
          children: [
            for (final request in requests)
              _ServiceRequestCard(
                request: request,
                user: user,
                requesterView: requesterView,
              ),
          ],
        );
      },
    );
  }
}

class _MyServiceListings extends StatelessWidget {
  const _MyServiceListings({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<services.ServiceProvider>();
    return StreamBuilder<List<ServiceModel>>(
      stream: provider.myServicesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ServiceListSkeleton();
        }
        final listings = snapshot.data ?? const <ServiceModel>[];
        final missingCommunityIds = listings
            .where((listing) => listing.communityId.trim().isEmpty)
            .map((listing) => listing.id)
            .toList(growable: false);
        if (missingCommunityIds.isNotEmpty && user.communityId.trim().isNotEmpty) {
          Future.microtask(
            () => provider.repairMissingServiceCommunityIds(
              provider: user,
              serviceIds: missingCommunityIds,
            ),
          );
        }
        if (listings.isEmpty) {
          return const _ServiceListView(
            children: [
              ResidentStateCard(
                icon: Icons.add_business_outlined,
                title: 'No listings yet',
                message: 'Create a service to receive bookings from neighbors.',
              ),
            ],
          );
        }
        return _ServiceListView(
          children: [
            for (final listing in listings)
              _MyServiceListingCard(
                service: listing,
                visibilityRepairNeeded: listing.communityId.trim().isEmpty,
                onEdit: _serviceIsArchived(listing)
                    ? null
                    : () => _openEditService(context, listing),
                onArchive: _serviceIsArchived(listing)
                    ? null
                    : () => _confirmArchive(context, listing),
                onUnarchive: _serviceIsArchived(listing)
                    ? () => _confirmUnarchive(context, listing)
                    : null,
              ),
          ],
        );
      },
    );
  }

  void _openEditService(BuildContext context, ServiceModel service) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResidentAddNewServiceView(user: user, service: service),
      ),
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    ServiceModel service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive service?'),
        content: Text(
          '${service.title} will disappear from Services Discover.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _setStatus(context, service, AppConstants.serviceStatusArchived);
  }

  Future<void> _confirmUnarchive(
    BuildContext context,
    ServiceModel service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unarchive service?'),
        content: Text(
          '${service.title} will appear in Services Discover again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unarchive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _setStatus(context, service, AppConstants.serviceStatusActive);
  }

  Future<void> _setStatus(
    BuildContext context,
    ServiceModel service,
    String status,
  ) async {
    final provider = context.read<services.ServiceProvider>();
    await provider.setServiceStatus(
      serviceId: service.id,
      providerId: user.uid,
      status: status,
    );
    if (!context.mounted) return;
    _showSnack(
      context,
      status == AppConstants.serviceStatusArchived
          ? 'Service archived.'
          : 'Service unarchived.',
    );
  }
}

class _ServiceListingCard extends StatelessWidget {
  const _ServiceListingCard({
    required this.service,
    this.onTap,
  });

  final ServiceModel service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ResidentGlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ServiceVisualStrip(service: service),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const ResidentStatusPill(label: 'Available'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _categoryLabel(service.category),
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            service.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ResidentAvatar(
                name: service.providerName,
                photoUrl: service.providerPhotoUrl,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      service.availability.trim().isEmpty
                          ? 'Availability by request'
                          : service.availability,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _priceLabel(service),
                    style: const TextStyle(
                      color: residentBrandTeal,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _priceTypeLabel(service),
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyServiceListingCard extends StatelessWidget {
  const _MyServiceListingCard({
    required this.service,
    required this.visibilityRepairNeeded,
    required this.onEdit,
    required this.onArchive,
    required this.onUnarchive,
  });

  final ServiceModel service;
  final bool visibilityRepairNeeded;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  @override
  Widget build(BuildContext context) {
    final archived = _serviceIsArchived(service);
    return ResidentGlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MyServiceThumb(service: service),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _categoryLabel(service.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ResidentStatusPill(
                          label: _serviceStatusLabel(service.status),
                        ),
                        if (service.certificateUrls.isNotEmpty)
                          ResidentStatusPill(
                            label:
                                '${service.certificateUrls.length} credential${service.certificateUrls.length == 1 ? '' : 's'}',
                          ),
                        if (visibilityRepairNeeded)
                          const ResidentStatusPill(label: 'Repairing visibility'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MyServiceInfoPanel(service: service),
          if (archived) ...[
            const SizedBox(height: 10),
            Text(
              'Archived services are hidden from Services Discover.',
              style: TextStyle(
                color: context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          if (visibilityRepairNeeded) ...[
            const SizedBox(height: 10),
            Text(
              'This listing is being linked to your community so neighbors can discover it.',
              style: TextStyle(
                color: context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ServiceFormSecondaryButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: archived
                    ? _ServiceFormSecondaryButton(
                        label: 'Unarchive',
                        icon: Icons.unarchive_outlined,
                        onTap: onUnarchive,
                      )
                    : _ServiceDangerButton(
                        label: 'Archive',
                        icon: Icons.archive_outlined,
                        onTap: onArchive,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyServiceThumb extends StatelessWidget {
  const _MyServiceThumb({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final imageUrl = service.imageUrls.isEmpty ? '' : service.imageUrls.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 82,
        height: 82,
        color: residentBrandTeal.withValues(alpha: 0.10),
        child: imageUrl.isEmpty
            ? Icon(_categoryIcon(service.category), color: residentBrandTeal)
            : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}

class _MyServiceInfoPanel extends StatelessWidget {
  const _MyServiceInfoPanel({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MyServiceInfoColumn(
              label: 'Availability',
              value: service.availability.trim().isEmpty
                  ? 'By request'
                  : service.availability,
            ),
          ),
          const SizedBox(width: 12),
          _MyServiceInfoColumn(
            label: _priceTypeLabel(service),
            value: _priceLabel(service),
            alignEnd: true,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _MyServiceInfoColumn extends StatelessWidget {
  const _MyServiceInfoColumn({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color: emphasized ? residentBrandTeal : context.appInk,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.appMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ServiceVisualStrip extends StatelessWidget {
  const _ServiceVisualStrip({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final photos = service.imageUrls;
    return SizedBox(
      height: JiraniResponsive.scaled(context, 124),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: photos.isEmpty
                ? _ServiceVisualTile(
                    icon: _categoryIcon(service.category),
                    label: _categoryLabel(service.category),
                  )
                : _ServiceNetworkImageTile(
                    imageUrl: photos.first,
                    label: _categoryLabel(service.category),
                  ),
          ),
          SizedBox(width: JiraniResponsive.scaled(context, 10)),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: photos.length > 1
                      ? _ServiceNetworkImageTile(
                          imageUrl: photos[1],
                          label: 'Work',
                          compact: true,
                        )
                      : _ServiceVisualTile(
                          icon: Icons.schedule_rounded,
                          label: _priceTypeLabel(service),
                          compact: true,
                        ),
                ),
                SizedBox(height: JiraniResponsive.scaled(context, 10)),
                Expanded(
                  child: service.certificateUrls.isNotEmpty
                      ? const _ServiceVisualTile(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Certs',
                          compact: true,
                        )
                      : const _ServiceVisualTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Profile',
                          compact: true,
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

class _ServiceNetworkImageTile extends StatelessWidget {
  const _ServiceNetworkImageTile({
    required this.imageUrl,
    required this.label,
    this.compact = false,
  });

  final String imageUrl;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(JiraniResponsive.scaledRadius(context, 18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: residentBrandTeal.withValues(alpha: 0.10),
            ),
            errorWidget: (context, url, error) => _ServiceVisualTile(
              icon: Icons.image_not_supported_outlined,
              label: label,
              compact: compact,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.42),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceVisualTile extends StatelessWidget {
  const _ServiceVisualTile({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = JiraniResponsive.scaledRadius(context, 18);
    return Container(
      decoration: BoxDecoration(
        color: residentBrandTeal.withValues(alpha: compact ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: residentBrandTeal.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: JiraniResponsive.scaled(context, compact ? 26 : 48),
            color: residentBrandTeal.withValues(alpha: 0.72),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: residentBrandTeal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceRequestCard extends StatelessWidget {
  const _ServiceRequestCard({
    required this.request,
    required this.user,
    required this.requesterView,
  });

  final ServiceRequestModel request;
  final AppUser user;
  final bool requesterView;

  @override
  Widget build(BuildContext context) {
    final personName =
        requesterView ? request.providerName : request.requesterName;
    final personRole = requesterView ? 'Service provider' : 'Requester';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidentGlassPanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ResidentIconTile(icon: Icons.handshake_outlined, size: 70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.serviceTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${DateFormat('MMM d').format(request.preferredDate)} - ${request.preferredTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ResidentStatusPill(
                          label: _requestStatusLabel(request.status),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            request.amount == null
                                ? 'Free'
                                : _money(request.amount!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: residentBrandTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ResidentProgressPanel(steps: _requestProgressSteps(request)),
        const SizedBox(height: 12),
        _ServiceLedgerPanel(request: request, requesterView: requesterView),
        const SizedBox(height: 12),
        ResidentPersonRow(name: personName, subtitle: personRole),
        const SizedBox(height: 12),
        _ServiceActionPanel(
          request: request,
          user: user,
          requesterView: requesterView,
        ),
      ],
    );
  }
}

class _ServiceLedgerPanel extends StatelessWidget {
  const _ServiceLedgerPanel({
    required this.request,
    required this.requesterView,
  });

  final ServiceRequestModel request;
  final bool requesterView;

  @override
  Widget build(BuildContext context) {
    final total = request.amount ?? 0;
    final payout = request.providerPayoutAmount > 0
        ? request.providerPayoutAmount
        : total;
    return ResidentGlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ResidentIconTile(
                icon: requesterView
                    ? Icons.savings_outlined
                    : Icons.account_balance_wallet_outlined,
                size: 34,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  requesterView ? 'Escrow Payment' : 'Provider Payout',
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ResidentStatusPill(
                label: requesterView
                    ? _paymentStatusLabel(request)
                    : _payoutStatusLabel(request),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResidentSummaryRow(
            label: requesterView ? 'Amount held' : 'Service amount',
            value: request.amount == null ? 'Free' : _money(total),
          ),
          const SizedBox(height: 8),
          ResidentSummaryRow(
            label: 'Platform fee',
            value: _money(request.platformFeeAmount),
          ),
          const Divider(height: 24),
          ResidentSummaryRow(
            label: requesterView ? 'Total paid' : 'Expected payout',
            value: request.amount == null ? 'Free' : _money(payout),
            emphasized: true,
          ),
          const SizedBox(height: 8),
          Text(
            _ledgerMessage(request, requesterView),
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceActionPanel extends StatelessWidget {
  const _ServiceActionPanel({
    required this.request,
    required this.user,
    required this.requesterView,
  });

  final ServiceRequestModel request;
  final AppUser user;
  final bool requesterView;

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.read<services.ServiceProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final busy =
        context.watch<services.ServiceProvider>().isLoading ||
        paymentProvider.isLoading;

    if (!requesterView &&
        request.status == AppConstants.serviceRequestStatusPending) {
      return ResidentGlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelLabel('Request Review'),
            const SizedBox(height: 12),
            ResidentTrackingStepCard(
              icon: Icons.fact_check_outlined,
              title: 'Accept or reject booking',
              message:
                  'Accepting a paid fixed service asks the requester to complete Xendit checkout before work can begin.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ResidentPrimaryButton(
                    icon: Icons.check_rounded,
                    label: busy ? 'Working...' : 'Accept',
                    onTap: busy
                        ? null
                        : () => _guard(
                              context,
                              () => serviceProvider.acceptServiceRequest(
                                requestId: request.id,
                                providerId: user.uid,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ResidentSecondaryButton(
                    icon: Icons.close_rounded,
                    label: 'Reject',
                    onTap: busy
                        ? null
                        : () => _guard(
                              context,
                              () => serviceProvider.rejectServiceRequest(
                                requestId: request.id,
                                providerId: user.uid,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (requesterView &&
        request.status ==
            AppConstants.serviceRequestStatusAcceptedAwaitingPayment) {
      return _CheckoutPanel(
        request: request,
        busy: busy,
        onPayment: () => _payForService(context, request),
      );
    }

    if (!requesterView &&
        request.status == AppConstants.serviceRequestStatusPaidHeld) {
      return ResidentGlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelLabel('Proof of Arrival'),
            const SizedBox(height: 12),
            ResidentTrackingStepCard(
              icon: Icons.pin_rounded,
              title: 'Show arrival code',
              message:
                  'Generate this when you are physically with the requester. The requester enters it to start the job timer.',
              action: ResidentPrimaryButton(
                icon: Icons.pin_rounded,
                label: busy ? 'Generating...' : 'Generate Arrival Code',
                onTap: busy
                    ? null
                    : () => _showGeneratedCode(
                          context,
                          () => serviceProvider.generateArrivalCode(
                            requestId: request.id,
                            providerId: user.uid,
                          ),
                          'Arrival Code',
                        ),
              ),
            ),
          ],
        ),
      );
    }

    if (requesterView &&
        request.status == AppConstants.serviceRequestStatusPaidHeld) {
      return ResidentGlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelLabel('Confirm Arrival'),
            const SizedBox(height: 12),
            ResidentTrackingStepCard(
              icon: Icons.handshake_rounded,
              title: 'Enter provider arrival code',
              message:
                  'Only enter the code after the provider has arrived in person and is ready to begin.',
              action: ResidentPrimaryButton(
                icon: Icons.pin_rounded,
                label: 'Enter Arrival Code',
                onTap: busy
                    ? null
                    : () => _showCodeInput(
                          context,
                          title: 'Arrival Code',
                          submit: (code) => serviceProvider.submitArrivalCode(
                            requestId: request.id,
                            requesterId: user.uid,
                            code: code,
                          ),
                        ),
              ),
            ),
          ],
        ),
      );
    }

    if (requesterView &&
        request.status == AppConstants.serviceRequestStatusInProgress) {
      return ResidentGlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelLabel('Work Completion'),
            const SizedBox(height: 12),
            ResidentTrackingStepCard(
              icon: Icons.task_alt_rounded,
              title: 'Approve completed work',
              message:
                  'Inspect the work. Generate the completion code only when you are satisfied.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ResidentPrimaryButton(
                    icon: Icons.verified_rounded,
                    label: 'Generate Completion Code',
                    onTap: busy
                        ? null
                        : () => _showGeneratedCode(
                              context,
                              () => serviceProvider.generateCompletionCode(
                                requestId: request.id,
                                requesterId: user.uid,
                              ),
                              'Completion Code',
                            ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ResidentDangerButton(
                    icon: Icons.gavel_rounded,
                    label: 'Dispute',
                    onTap: busy
                        ? null
                        : () => _showDisputeDialog(
                              context,
                              request.id,
                              user.uid,
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (!requesterView &&
        request.status == AppConstants.serviceRequestStatusInProgress) {
      return ResidentGlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelLabel('Proof of Work'),
            const SizedBox(height: 12),
            ResidentTrackingStepCard(
              icon: Icons.pin_rounded,
              title: 'Enter completion code',
              message:
                  'After the requester approves the work, enter their 4-digit completion code to release payout.',
              action: ResidentPrimaryButton(
                icon: Icons.verified_rounded,
                label: 'Enter Completion Code',
                onTap: busy
                    ? null
                    : () => _showCodeInput(
                          context,
                          title: 'Completion Code',
                          submit: (code) =>
                              serviceProvider.submitCompletionCode(
                            requestId: request.id,
                            providerId: user.uid,
                            code: code,
                          ),
                        ),
              ),
            ),
          ],
        ),
      );
    }

    if (!requesterView &&
        request.status == AppConstants.serviceRequestStatusAccepted &&
        !request.isPaidService) {
      return ResidentGlassPanel(
        child: ResidentTrackingStepCard(
          icon: Icons.task_alt_rounded,
          title: 'Complete free service',
          message:
              'This request does not require escrow. Mark it complete once the work is done.',
          action: ResidentPrimaryButton(
            icon: Icons.check_rounded,
            label: busy ? 'Completing...' : 'Complete Free Service',
            onTap: busy
                ? null
                : () => _guard(
                      context,
                      () => serviceProvider.completeServiceRequest(
                        requestId: request.id,
                        providerId: user.uid,
                      ),
                    ),
          ),
        ),
      );
    }

    if (request.status == AppConstants.serviceRequestStatusDisputed) {
      return _DisputedPanel(request: request);
    }

    if (request.status ==
            AppConstants.serviceRequestStatusCompletedPayoutPending ||
        request.status == AppConstants.serviceRequestStatusCompletedPayoutSent ||
        request.status == AppConstants.serviceRequestStatusCompleted) {
      return _CompletedPanel(request: request, requesterView: requesterView);
    }

    return ResidentGlassPanel(
      child: ResidentTrackingStepCard(
        icon: Icons.info_outline_rounded,
        title: _requestStatusLabel(request.status),
        message: _statusHelp(request),
      ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({
    required this.request,
    required this.busy,
    required this.onPayment,
  });

  final ServiceRequestModel request;
  final bool busy;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    final amount = request.amount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidentGlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PanelLabel('Transaction Summary'),
              const SizedBox(height: 12),
              ResidentSummaryRow(label: 'Service', value: request.serviceTitle),
              const SizedBox(height: 8),
              ResidentSummaryRow(
                label: 'Date',
                value: DateFormat('MMM d, yyyy').format(request.preferredDate),
              ),
              const SizedBox(height: 8),
              ResidentSummaryRow(label: 'Time', value: request.preferredTime),
              const Divider(height: 28),
              ResidentSummaryRow(
                label: 'Total Due',
                value: _money(amount),
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ResidentGlassPanel(
          child: ResidentTrackingStepCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Secure Xendit checkout',
            message:
                'Xendit will open a secure checkout page with Malaysian payment options. Your payment is held until completion is verified.',
            action: ResidentPrimaryButton(
              icon: Icons.lock_rounded,
              label: busy ? 'Opening checkout...' : 'Pay with Xendit',
              onTap: busy ? null : onPayment,
            ),
          ),
        ),
      ],
    );
  }
}

class _DisputedPanel extends StatelessWidget {
  const _DisputedPanel({required this.request});

  final ServiceRequestModel request;

  @override
  Widget build(BuildContext context) {
    final reason = request.disputeReason.trim();
    return ResidentGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelLabel('Admin Review'),
          const SizedBox(height: 12),
          ResidentTrackingStepCard(
            icon: Icons.gavel_rounded,
            title: 'Escrow Frozen',
            message:
                'This service is paused while admin reviews the dispute. Funds remain held until admin decides payout or refund.',
            child: Column(
              children: [
                ResidentSummaryRow(
                  label: 'Reason',
                  value: reason.isEmpty ? 'Waiting for admin review' : reason,
                ),
                const SizedBox(height: 8),
                const ResidentSummaryRow(
                  label: 'Admin note',
                  value: 'The final resolution will appear here.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedPanel extends StatelessWidget {
  const _CompletedPanel({
    required this.request,
    required this.requesterView,
  });

  final ServiceRequestModel request;
  final bool requesterView;

  @override
  Widget build(BuildContext context) {
    final isPayoutSent =
        request.status == AppConstants.serviceRequestStatusCompletedPayoutSent ||
        request.status == AppConstants.serviceRequestStatusCompleted;
    return ResidentGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            isPayoutSent ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            color: isPayoutSent ? residentBrandTeal : residentWarmAccent,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            isPayoutSent ? 'Service Complete' : 'Payout Processing',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            requesterView
                ? 'Completion was verified face to face.'
                : isPayoutSent
                    ? 'The service payout has been sent.'
                    : 'Completion is verified and payout is being processed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          ResidentTrackingStepCard(
            icon: Icons.rate_review_rounded,
            title: requesterView ? 'Rate the Provider' : 'Review Ready',
            message: requesterView
                ? 'Service reviews will use the same Marketplace rating style once service review submission is enabled.'
                : 'The requester can review the completed service from their booking history.',
            child: requesterView
                ? Center(
                    child: RatingBarIndicator(
                      rating: 5,
                      itemSize: 34,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star_rounded,
                        color: residentWarmAccent,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: context.appMuted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _ServiceListView extends StatelessWidget {
  const _ServiceListView({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: children.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: residentMaxContentWidth),
            child: children[index],
          ),
        );
      },
    );
  }
}

class _ServiceListSkeleton extends StatelessWidget {
  const _ServiceListSkeleton();

  @override
  Widget build(BuildContext context) {
    return _ServiceListView(
      children: [
        for (var i = 0; i < 3; i++)
          ResidentGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 124,
                  decoration: BoxDecoration(
                    color: residentBrandTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 18,
                  width: 180,
                  decoration: BoxDecoration(
                    color: context.skeletonBar,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: context.skeletonBar,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<void> _showServiceDetail(
  BuildContext context,
  AppUser user,
  ServiceModel service,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ServiceVisualStrip(service: service),
            const SizedBox(height: 16),
            Text(
              service.title,
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(service.description),
            const SizedBox(height: 14),
            ResidentPersonRow(
              name: service.providerName,
              subtitle: service.availability.trim().isEmpty
                  ? 'Availability by request'
                  : service.availability,
              photoUrl: service.providerPhotoUrl,
            ),
            const SizedBox(height: 14),
            ResidentGlassPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ResidentSummaryRow(
                    label: 'Price',
                    value: _priceLabel(service),
                    emphasized: true,
                  ),
                  const SizedBox(height: 8),
                  ResidentSummaryRow(
                    label: 'Category',
                    value: _categoryLabel(service.category),
                  ),
                  const SizedBox(height: 8),
                  ResidentSummaryRow(
                    label: 'Pricing mode',
                    value: _priceTypeLabel(service),
                  ),
                ],
              ),
            ),
            if (service.certificateUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              ResidentGlassPanel(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PanelTitle(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Self-provided certificates',
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < service.certificateUrls.length; i += 1)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == service.certificateUrls.length - 1 ? 0 : 8,
                        ),
                        child: _CertificateLinkTile(
                          name: i < service.certificateNames.length
                              ? service.certificateNames[i]
                              : 'Certificate ${i + 1}',
                          url: service.certificateUrls[i],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ResidentPrimaryButton(
              icon: Icons.receipt_long_rounded,
              label: 'Request Service',
              onTap: () {
                Navigator.pop(sheetContext);
                _showRequestSheet(context, user, service);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showRequestSheet(
  BuildContext context,
  AppUser user,
  ServiceModel service,
) async {
  final message = TextEditingController();
  final time = TextEditingController();
  var date = DateTime.now().add(const Duration(days: 1));
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Request ${service.title}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: message,
                  decoration: context.residentInputDecoration(
                    label: 'Message',
                    hint: 'Share what you need help with',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: time,
                  decoration: context.residentInputDecoration(
                    label: 'Preferred time',
                    hint: 'e.g. 4:00 PM',
                  ),
                ),
                const SizedBox(height: 10),
                ResidentSecondaryButton(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat('MMM d, yyyy').format(date),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      initialDate: date,
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                ),
                const SizedBox(height: 18),
                ResidentPrimaryButton(
                  icon: Icons.send_rounded,
                  label: 'Submit Request',
                  onTap: () => _guard(context, () async {
                    await context
                        .read<services.ServiceProvider>()
                        .createServiceRequest(
                          service: service,
                          requester: user,
                          message: message.text,
                          preferredDate: date,
                          preferredTime: time.text,
                        );
                    if (context.mounted) Navigator.pop(context);
                  }),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _showGeneratedCode(
  BuildContext context,
  Future<String?> Function() generator,
  String title,
) async {
  final code = await generator();
  if (!context.mounted || code == null || code.isEmpty) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ResidentCodeDisplay(label: title, code: code),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

Future<void> _showCodeInput(
  BuildContext context, {
  required String title,
  required Future<void> Function(String code) submit,
}) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        maxLength: 4,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        decoration: context.residentInputDecoration(
          label: '4-digit code',
          hint: '0000',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _guard(dialogContext, () async {
            await submit(controller.text.trim());
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

Future<void> _showDisputeDialog(
  BuildContext context,
  String requestId,
  String requesterId,
) async {
  final reason = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Raise Dispute'),
      content: TextField(
        controller: reason,
        minLines: 3,
        maxLines: 5,
        decoration: context.residentInputDecoration(
          label: 'What went wrong?',
          hint: 'Describe the issue for admin review',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _guard(dialogContext, () async {
            await dialogContext
                .read<services.ServiceProvider>()
                .disputeServiceRequest(
                  requestId: requestId,
                  requesterId: requesterId,
                  reason: reason.text,
                );
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

Future<void> _payForService(
  BuildContext context,
  ServiceRequestModel request,
) async {
  final paymentProvider = context.read<PaymentProvider>();
  final result = await paymentProvider.createXenditServicePayment(
    request: request,
    successRedirectUrl:
        'https://final-year-project-faisal.web.app/xendit-payment-success',
    failureRedirectUrl:
        'https://final-year-project-faisal.web.app/xendit-payment-failed',
  );
  if (!context.mounted) return;
  if (result == null || result.checkoutUrl.isEmpty) {
    _showSnack(
      context,
      paymentProvider.errorMessage ?? 'Could not open Xendit checkout.',
    );
    return;
  }
  final opened = await launchUrl(
    Uri.parse(result.checkoutUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!context.mounted) return;
  if (!opened) {
    _showSnack(context, 'Could not open Xendit checkout.');
    return;
  }
  _showSnack(context, "Payment opened. We'll confirm with Xendit shortly.");
  await paymentProvider.waitForPaymentConfirmation(result.paymentId);
}

Future<void> _guard(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    if (context.mounted) _showSnack(context, 'Done.');
  } catch (error) {
    if (!context.mounted) return;
    _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _friendlyServiceError(Object? error) {
  final raw = error?.toString() ?? 'Unknown error.';
  if (raw.contains('failed-precondition') || raw.contains('index')) {
    return 'Firestore needs the Services community/status index. Deploy indexes and try again.';
  }
  if (raw.contains('permission-denied')) {
    return 'Firestore rules denied this Services query. Check the service community visibility rules.';
  }
  return raw.replaceFirst('Exception: ', '');
}

List<ResidentProgressStep> _requestProgressSteps(ServiceRequestModel request) {
  final status = request.status;
  return [
    ResidentProgressStep(
      label: 'Accept',
      icon: Icons.verified_rounded,
      done: status != AppConstants.serviceRequestStatusPending &&
          status != AppConstants.serviceRequestStatusRejected &&
          status != AppConstants.serviceRequestStatusCancelled,
    ),
    ResidentProgressStep(
      label: 'Payment',
      icon: Icons.payments_rounded,
      done: !request.isPaidService ||
          status == AppConstants.serviceRequestStatusPaidHeld ||
          _isAfterServicePayment(status),
    ),
    ResidentProgressStep(
      label: 'Arrival',
      icon: Icons.handshake_rounded,
      done: request.arrivalVerifiedAt != null ||
          status == AppConstants.serviceRequestStatusInProgress ||
          _isAfterServiceArrival(status),
    ),
    ResidentProgressStep(
      label: 'Complete',
      icon: Icons.task_alt_rounded,
      done: request.completedAt != null ||
          status == AppConstants.serviceRequestStatusCompleted ||
          status == AppConstants.serviceRequestStatusCompletedPayoutPending ||
          status == AppConstants.serviceRequestStatusCompletedPayoutSent,
    ),
  ];
}

bool _isAfterServicePayment(String status) {
  return status == AppConstants.serviceRequestStatusInProgress ||
      status == AppConstants.serviceRequestStatusCompletedPayoutPending ||
      status == AppConstants.serviceRequestStatusCompletedPayoutSent ||
      status == AppConstants.serviceRequestStatusDisputed ||
      status == AppConstants.serviceRequestStatusRefunded ||
      status == AppConstants.serviceRequestStatusCompleted;
}

bool _isAfterServiceArrival(String status) {
  return status == AppConstants.serviceRequestStatusCompletedPayoutPending ||
      status == AppConstants.serviceRequestStatusCompletedPayoutSent ||
      status == AppConstants.serviceRequestStatusDisputed ||
      status == AppConstants.serviceRequestStatusRefunded ||
      status == AppConstants.serviceRequestStatusCompleted;
}

String _priceLabel(ServiceModel service) {
  if (service.pricingMode == AppConstants.servicePricingModeHourly) {
    return '${_money(service.hourlyRate ?? service.priceAmount ?? 0)} / hour';
  }
  if (service.pricingMode == AppConstants.servicePricingModeFixedJob) {
    return _money(service.fixedJobPrice ?? service.priceAmount ?? 0);
  }
  switch (service.priceType) {
    case AppConstants.servicePriceTypeFree:
      return 'Free';
    case AppConstants.servicePriceTypeNegotiable:
      return service.priceAmount == null
          ? 'Negotiable'
          : '${_money(service.priceAmount!)} negotiable';
    default:
      return _money(service.priceAmount ?? 0);
  }
}

String _priceTypeLabel(ServiceModel service) {
  if (service.pricingMode == AppConstants.servicePricingModeHourly) {
    return 'Hourly rate';
  }
  if (service.pricingMode == AppConstants.servicePricingModeFixedJob) {
    return 'Fixed job';
  }
  return switch (service.priceType) {
    AppConstants.servicePriceTypeFree => 'No payment',
    AppConstants.servicePriceTypeNegotiable => 'Negotiable',
    _ => 'Service fee',
  };
}

String _money(double value) => 'RM ${value.toStringAsFixed(2)}';

String _serviceStatusLabel(String status) {
  return status.isEmpty ? 'Unknown' : status[0].toUpperCase() + status.substring(1);
}

bool _serviceIsArchived(ServiceModel service) {
  return service.status == AppConstants.serviceStatusArchived;
}

String _requestStatusLabel(String status) {
  return switch (status) {
    AppConstants.serviceRequestStatusAcceptedAwaitingPayment =>
      'Awaiting Payment',
    AppConstants.serviceRequestStatusPaidHeld => 'Paid',
    AppConstants.serviceRequestStatusInProgress => 'In Progress',
    AppConstants.serviceRequestStatusCompletedPayoutPending => 'Payout Pending',
    AppConstants.serviceRequestStatusCompletedPayoutSent => 'Completed',
    AppConstants.serviceRequestStatusPaymentFailed => 'Payment Failed',
    _ => _serviceStatusLabel(status),
  };
}

String _paymentStatusLabel(ServiceRequestModel request) {
  if (!request.isPaidService) return 'No Payment';
  if (request.paymentStatus.trim().isNotEmpty) {
    return _serviceStatusLabel(request.paymentStatus);
  }
  return switch (request.status) {
    AppConstants.serviceRequestStatusAcceptedAwaitingPayment => 'Unpaid',
    AppConstants.serviceRequestStatusPaidHeld => 'Held',
    AppConstants.serviceRequestStatusPaymentFailed => 'Failed',
    AppConstants.serviceRequestStatusRefunded => 'Refunded',
    _ => 'Pending',
  };
}

String _payoutStatusLabel(ServiceRequestModel request) {
  if (!request.isPaidService) return 'No Payout';
  if (request.payoutStatus.trim().isNotEmpty) {
    return _serviceStatusLabel(request.payoutStatus);
  }
  return 'Pending';
}

String _ledgerMessage(ServiceRequestModel request, bool requesterView) {
  if (!request.isPaidService) {
    return 'This is a free service request, so no escrow payment is required.';
  }
  if (request.status == AppConstants.serviceRequestStatusDisputed) {
    return 'Escrow is frozen while admin reviews the dispute.';
  }
  if (request.status == AppConstants.serviceRequestStatusCompletedPayoutSent) {
    return requesterView
        ? 'Work was verified and provider payout was sent.'
        : 'Payout was sent after completion code verification.';
  }
  return requesterView
      ? 'Payment is held until arrival and completion are verified face to face.'
      : 'Payout is released only after the requester gives the completion code.';
}

String _statusHelp(ServiceRequestModel request) {
  return switch (request.status) {
    AppConstants.serviceRequestStatusPending => 'Waiting for provider response.',
    AppConstants.serviceRequestStatusAcceptedAwaitingPayment =>
      'Waiting for requester payment.',
    AppConstants.serviceRequestStatusPaidHeld =>
      'Payment is held until arrival is verified.',
    AppConstants.serviceRequestStatusCompletedPayoutPending =>
      'Completion verified. Payout is processing.',
    AppConstants.serviceRequestStatusCompletedPayoutSent =>
      'Completed and payout sent.',
    AppConstants.serviceRequestStatusDisputed =>
      'Dispute is frozen for admin review.',
    AppConstants.serviceRequestStatusRefunded => 'Payment was refunded.',
    AppConstants.serviceRequestStatusPaymentFailed =>
      'Payment failed. The requester can try again.',
    _ => 'No action available for this state.',
  };
}

IconData _categoryIcon(String category) {
  return switch (category) {
    AppConstants.serviceCategoryHomeCleaningUpkeep =>
      Icons.cleaning_services_outlined,
    AppConstants.serviceCategoryRepairsMaintenance => Icons.build_outlined,
    AppConstants.serviceCategoryAssemblyLabor => Icons.handyman_outlined,
    AppConstants.serviceCategoryTutoringEducation => Icons.school_outlined,
    AppConstants.serviceCategoryAssistanceErrands => Icons.volunteer_activism_outlined,
    AppConstants.serviceCategoryItTechSetup => Icons.router_outlined,
    AppConstants.serviceCategoryHomeCookingMealPrep => Icons.restaurant_outlined,
    AppConstants.serviceCategoryCreativeDigitalTasks =>
      Icons.design_services_outlined,
    _ => Icons.home_repair_service_outlined,
  };
}

int _timeMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

String _serviceAmountText(double amount) {
  return amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}

TimeOfDay? _parseServiceTime(String? hour, String? minute, String? period) {
  final parsedHour = int.tryParse(hour ?? '');
  final parsedMinute = int.tryParse(minute ?? '');
  if (parsedHour == null || parsedMinute == null || period == null) {
    return null;
  }
  var resolvedHour = parsedHour % 12;
  if (period.toLowerCase() == 'pm') resolvedHour += 12;
  return TimeOfDay(hour: resolvedHour, minute: parsedMinute);
}

bool _sameDays(Set<int> left, Set<int> right) {
  if (left.length != right.length) return false;
  return left.every(right.contains);
}

String _availabilityDaySummary(Set<int> days) {
  if (_sameDays(days, _everydayDays)) return 'Everyday';
  if (_sameDays(days, _weekdayDays)) return 'Mon-Fri';
  if (_sameDays(days, _weekendDays)) return 'Sat-Sun';
  final sorted = days.toList()..sort();
  return sorted.map(_dayShortLabel).join(', ');
}

String _dayShortLabel(int day) {
  return switch (day) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => 'Day',
  };
}

String _categoryLabel(String category) => _serviceCategories[category] ?? 'Other';

const _availabilityDays = [
  _AvailabilityDay(DateTime.monday, 'Mon'),
  _AvailabilityDay(DateTime.tuesday, 'Tue'),
  _AvailabilityDay(DateTime.wednesday, 'Wed'),
  _AvailabilityDay(DateTime.thursday, 'Thu'),
  _AvailabilityDay(DateTime.friday, 'Fri'),
  _AvailabilityDay(DateTime.saturday, 'Sat'),
  _AvailabilityDay(DateTime.sunday, 'Sun'),
];

const _weekdayDays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
};

const _weekendDays = {
  DateTime.saturday,
  DateTime.sunday,
};

const _everydayDays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
};

class _AvailabilityDay {
  const _AvailabilityDay(this.value, this.label);

  final int value;
  final String label;
}

const _serviceCategories = <String, String>{
  AppConstants.serviceCategoryHomeCleaningUpkeep: 'Home Cleaning & Upkeep',
  AppConstants.serviceCategoryRepairsMaintenance: 'Repairs & Maintenance',
  AppConstants.serviceCategoryAssemblyLabor: 'Assembly & Labor',
  AppConstants.serviceCategoryTutoringEducation: 'Tutoring & Education',
  AppConstants.serviceCategoryAssistanceErrands: 'Assistance & Errands',
  AppConstants.serviceCategoryItTechSetup: 'IT & Tech Setup',
  AppConstants.serviceCategoryHomeCookingMealPrep: 'Home Cooking & Meal Prep',
  AppConstants.serviceCategoryCreativeDigitalTasks: 'Creative & Digital Tasks',
};

const _serviceCategoryOptions = [
  ResidentCategoryOption('All Services', 'all'),
  ResidentCategoryOption(
    'Home Cleaning',
    AppConstants.serviceCategoryHomeCleaningUpkeep,
  ),
  ResidentCategoryOption(
    'Repairs',
    AppConstants.serviceCategoryRepairsMaintenance,
  ),
  ResidentCategoryOption(
    'Labor',
    AppConstants.serviceCategoryAssemblyLabor,
  ),
  ResidentCategoryOption(
    'Tutoring',
    AppConstants.serviceCategoryTutoringEducation,
  ),
  ResidentCategoryOption(
    'Errands',
    AppConstants.serviceCategoryAssistanceErrands,
  ),
  ResidentCategoryOption(
    'Tech',
    AppConstants.serviceCategoryItTechSetup,
  ),
  ResidentCategoryOption(
    'Cooking',
    AppConstants.serviceCategoryHomeCookingMealPrep,
  ),
  ResidentCategoryOption(
    'Creative',
    AppConstants.serviceCategoryCreativeDigitalTasks,
  ),
];
