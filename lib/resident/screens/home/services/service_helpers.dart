part of '../resident_services_view.dart';

const int _maxCertificatePdfBytes = 10 * 1024 * 1024;

Future<void> _confirmCancelServiceRequest(
  BuildContext context, {
  required ServiceRequestModel request,
  required AppUser user,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel request?'),
      content: Text(
        'Cancel your booking for "${request.serviceTitle}"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep request'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Cancel request'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await _guard(
    context,
    () => context.read<services.ServiceProvider>().cancelServiceRequest(
      requestId: request.id,
      requesterId: user.uid,
    ),
    successMessage: 'Service request cancelled.',
  );
  if (!context.mounted) return;
  Navigator.of(context).pop();
}

Future<void> _guard(
  BuildContext context,
  Future<void> Function() action, {
  String? successMessage,
}) async {
  try {
    await action();
    if (context.mounted && successMessage != null) {
      _showSnack(context, successMessage);
    }
  } catch (error) {
    if (!context.mounted) return;
    _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
  }
}

String _transactionScreenTitle({
  required ServiceRequestModel request,
  required bool requesterView,
}) {
  if (requesterView) return 'Booking';
  if (request.status == AppConstants.serviceRequestStatusPending) {
    return 'Request Details';
  }
  return 'Transaction Tracking';
}

int _pendingServiceRequestCount(
  String serviceId,
  List<ServiceRequestModel> incoming,
) {
  return incoming
      .where(
        (request) =>
            request.serviceId == serviceId &&
            request.status == AppConstants.serviceRequestStatusPending,
      )
      .length;
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _openCertificatePreview({
  required BuildContext context,
  required String name,
  required String url,
}) async {
  final trimmedUrl = url.trim();
  final uri = Uri.tryParse(trimmedUrl);
  if (uri == null || !_isAllowedCertificateUri(uri)) {
    _showSnack(context, 'Certificate link is invalid.');
    return;
  }

  final type = _certificateType(name: name, url: trimmedUrl);
  if (type == _CertificatePreviewType.image) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _CertificateImagePreviewScreen(
          name: name,
          url: trimmedUrl,
        ),
      ),
    );
    return;
  }

  if (type != _CertificatePreviewType.pdf) {
    _showSnack(context, 'This certificate file type is not supported.');
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CertificateProgressDialog(
      message: 'Opening certificate...',
    ),
  );

  try {
    final file = await _downloadCertificatePdf(
      name: name,
      url: trimmedUrl,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _CertificatePdfPreviewScreen(
          filePath: file.path,
          name: name,
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _showSnack(context, 'Could not open this certificate.');
  }
}

Future<File> _downloadCertificatePdf({
  required String name,
  required String url,
}) async {
  final uri = Uri.parse(url);
  if (!_isAllowedCertificateUri(uri)) {
    throw Exception('Certificate link is invalid.');
  }

  final cacheDir = await getTemporaryDirectory();
  final certificatesDir = Directory(
    p.join(cacheDir.path, 'service_certificates'),
  );
  if (!await certificatesDir.exists()) {
    await certificatesDir.create(recursive: true);
  }

  final fileName = _safeCertificateFileName(name, url);
  final localFile = File(p.join(certificatesDir.path, fileName));
  if (await localFile.exists() && await localFile.length() > 0) {
    return localFile;
  }

  final client = http.Client();
  try {
    final response = await client.send(http.Request('GET', uri));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Certificate download failed.');
    }
    if (!_isPdfContentType(response.headers['content-type'])) {
      throw Exception('Certificate file type is invalid.');
    }
    final contentLength = response.contentLength;
    if (contentLength != null && contentLength > _maxCertificatePdfBytes) {
      throw Exception('Certificate file is too large.');
    }

    final bytes = BytesBuilder(copy: false);
    var received = 0;
    await for (final chunk in response.stream) {
      received += chunk.length;
      if (received > _maxCertificatePdfBytes) {
        throw Exception('Certificate file is too large.');
      }
      bytes.add(chunk);
    }
    await localFile.writeAsBytes(bytes.takeBytes(), flush: true);
    return localFile;
  } catch (_) {
    if (await localFile.exists()) {
      await localFile.delete();
    }
    rethrow;
  } finally {
    client.close();
  }
}

bool _isAllowedCertificateUri(Uri uri) {
  return uri.hasScheme &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.trim().isNotEmpty;
}

bool _isPdfContentType(String? contentType) {
  if (contentType == null) return false;
  final normalized = contentType.split(';').first.trim().toLowerCase();
  return normalized == 'application/pdf' ||
      normalized == 'application/octet-stream' ||
      normalized == 'binary/octet-stream';
}

String _safeCertificateFileName(String name, String url) {
  final candidate = name.trim().isNotEmpty ? name.trim() : Uri.parse(url).path;
  final base = p.basename(candidate).trim().isEmpty
      ? 'certificate.pdf'
      : p.basename(candidate);
  final withExtension = p.extension(base).toLowerCase() == '.pdf'
      ? base
      : '$base.pdf';
  return withExtension.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
}

_CertificatePreviewType _certificateType({
  required String name,
  required String url,
}) {
  final nameExtension = p.extension(name.trim()).toLowerCase();
  final urlExtension = p.extension(Uri.tryParse(url)?.path ?? '').toLowerCase();
  final extension = nameExtension.isNotEmpty ? nameExtension : urlExtension;
  return switch (extension) {
    '.pdf' => _CertificatePreviewType.pdf,
    '.jpg' ||
    '.jpeg' ||
    '.png' ||
    '.webp' ||
    '.heic' ||
    '.heif' => _CertificatePreviewType.image,
    _ => _CertificatePreviewType.unsupported,
  };
}

String _certificateTitle(String name) {
  return name.trim().isEmpty ? 'Certificate' : name.trim();
}

enum _CertificatePreviewType { image, pdf, unsupported }

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

bool _isHourlyService(ServiceModel service) =>
    service.pricingMode == AppConstants.servicePricingModeHourly;

double _serviceBasePrice(ServiceModel service) =>
    service.fixedJobPrice ?? service.hourlyRate ?? service.priceAmount ?? 0;

String _money(double value) => 'RM ${value.toStringAsFixed(2)}';

String _requestAmountLabel(ServiceRequestModel request) {
  final amount = request.amount;
  if (amount == null || amount <= 0) return 'Free';
  if (request.isHourlyService) {
    return '${_money(amount)} · ${request.durationHours} h';
  }
  return _money(amount);
}

String _requestScheduleLabel(ServiceRequestModel request) {
  return '${DateFormat('MMM d').format(request.preferredDate)} - ${request.preferredTime}';
}

String _serviceStatusLabel(String status) => serviceListingStatusLabel(status);

bool _serviceIsArchived(ServiceModel service) {
  return service.status == AppConstants.serviceStatusArchived;
}

String _requestStatusLabel(String status) => serviceRequestStatusLabel(status);

String _paymentStatusLabel(ServiceRequestModel request) {
  if (!request.isPaidService) return 'No Payment';
  if (request.paymentStatus.trim().isNotEmpty) {
    return paymentStatusLabel(request.paymentStatus);
  }
  return switch (request.status) {
    AppConstants.serviceRequestStatusAcceptedAwaitingPayment => 'Unpaid',
    AppConstants.serviceRequestStatusPaidHeld => 'Paid',
    AppConstants.serviceRequestStatusPaymentFailed => 'Failed',
    AppConstants.serviceRequestStatusRefunded => 'Refunded',
    _ => 'Pending',
  };
}

String _payoutStatusLabel(ServiceRequestModel request) {
  if (!request.isPaidService) return 'No Payout';
  if (request.settlementMode == AppConstants.settlementModeSimulated &&
      request.payoutStatus == AppConstants.servicePayoutStatusSent) {
    return 'Test payout recorded';
  }
  if (request.payoutStatus.trim().isNotEmpty) {
    return servicePayoutStatusLabel(request.payoutStatus);
  }
  return 'Pending';
}

String _ledgerMessage(ServiceRequestModel request, bool requesterView) {
  if (!request.isPaidService) {
    return 'This is a free service request, so no payment is required.';
  }
  if (request.status == AppConstants.serviceRequestStatusDisputed) {
    return 'Held payment is paused while admin reviews the dispute.';
  }
  if (request.status == AppConstants.serviceRequestStatusCompletedPayoutSent) {
    if (request.settlementMode == AppConstants.settlementModeSimulated) {
      return requesterView
          ? 'Work was verified and the test payout was recorded for the provider.'
          : 'Test payout recorded after completion code verification.';
    }
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

const _serviceDisputeTypeOptions = AppConstants.serviceDisputeTypeLabels;

List<MapEntry<String, String>> get serviceDisputeTypeOptions {
  return _serviceDisputeTypeOptions.entries.toList();
}

String serviceDisputeSummary(ServiceRequestModel request) {
  final typeLabel = request.disputeType.trim().isEmpty
      ? ''
      : serviceDisputeTypeLabel(request.disputeType);
  final details = request.disputeReason.trim();
  if (typeLabel.isEmpty) {
    return details.isEmpty ? 'Waiting for admin review' : details;
  }
  return details.isEmpty ? typeLabel : '$typeLabel — $details';
}

bool serviceDisputeDetailsRequired(String disputeType) {
  return disputeType == AppConstants.serviceDisputeTypeOther;
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

String _categoryLabel(String category) => serviceCategoryLabel(category);

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
