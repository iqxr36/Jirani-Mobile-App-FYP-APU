part of '../resident_services_view.dart';

class _MyServiceListings extends StatelessWidget {
  const _MyServiceListings({required this.user, required this.sideInset});

  final AppUser user;
  final double sideInset;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<services.ServiceProvider>();
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: provider.incomingRequestsStream(user.uid),
      builder: (context, incomingSnapshot) {
        final incoming = incomingSnapshot.data ?? const <ServiceRequestModel>[];
        return StreamBuilder<List<ServiceModel>>(
          stream: provider.myServicesStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: _ServiceInsetCard(
                  sideInset: sideInset,
                  child: ResidentStateCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load listings',
                    message: _friendlyServiceError(snapshot.error),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, _) => _ServiceInsetCard(
                  sideInset: sideInset,
                  child: const _ServiceSkeletonCard(),
                ),
              );
            }
            final listings = snapshot.data ?? const <ServiceModel>[];
            final missingCommunityIds = listings
                .where((listing) => listing.communityId.trim().isEmpty)
                .map((listing) => listing.id)
                .toList(growable: false);
            if (missingCommunityIds.isNotEmpty &&
                user.communityId.trim().isNotEmpty) {
              Future.microtask(
                () => provider.repairMissingServiceCommunityIds(
                  provider: user,
                  serviceIds: missingCommunityIds,
                ),
              );
            }
            if (listings.isEmpty) {
              return SliverToBoxAdapter(
                child: _ServiceInsetCard(
                  sideInset: sideInset,
                  child: const ResidentStateCard(
                    icon: Icons.add_business_outlined,
                    title: 'No listings yet',
                    message:
                        'Create a service to receive bookings from neighbors.',
                  ),
                ),
              );
            }
            return SliverList.separated(
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return _ServiceInsetCard(
                  sideInset: sideInset,
                  child: _MyServiceListingCard(
                    service: listing,
                    visibilityRepairNeeded: listing.communityId.trim().isEmpty,
                    pendingRequestCount:
                        _pendingServiceRequestCount(listing.id, incoming),
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
                );
              },
            );
          },
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 14),
          Divider(height: 1, color: context.residentOutline()),
          const SizedBox(height: 12),
          Row(
            children: [
              ResidentAvatar(
                name: service.providerName,
                photoUrl: service.providerPhotoUrl,
              ),
              const SizedBox(width: 10),
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
              Container(
                width: 1,
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: context.residentOutline(),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 142),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _priceLabel(service),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: residentBrandTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _priceTypeLabel(service),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
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
    this.pendingRequestCount = 0,
    required this.onEdit,
    required this.onArchive,
    required this.onUnarchive,
  });

  final ServiceModel service;
  final bool visibilityRepairNeeded;
  final int pendingRequestCount;
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
                        if (pendingRequestCount > 0)
                          ResidentStatusPill(
                            label: '$pendingRequestCount pending',
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
    final radius = JiraniResponsive.scaledRadius(context, 20);
    return SizedBox(
      height: JiraniResponsive.scaled(context, 124),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _ServiceCardImage(
              url: _serviceImageAt(service, 0),
              service: service,
              radius: radius,
            ),
          ),
          SizedBox(width: JiraniResponsive.scaled(context, 10)),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _ServiceCardImage(
                    url: _serviceImageAt(service, 1),
                    service: service,
                    radius: radius,
                    compact: true,
                  ),
                ),
                SizedBox(height: JiraniResponsive.scaled(context, 10)),
                Expanded(
                  child: _ServiceCardImage(
                    url: _serviceImageAt(service, 2),
                    service: service,
                    radius: radius,
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

class _ServiceCardImage extends StatelessWidget {
  const _ServiceCardImage({
    required this.url,
    required this.service,
    required this.radius,
    this.compact = false,
  });

  final String url;
  final ServiceModel service;
  final double radius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return _ServiceHeroFallback(
        service: service,
        compact: compact,
        radius: radius,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) => _ServiceHeroFallback(
          service: service,
          compact: compact,
          radius: radius,
        ),
        errorWidget: (context, _, _) => _ServiceHeroFallback(
          service: service,
          compact: compact,
          radius: radius,
        ),
      ),
    );
  }
}

class _ServiceHeroFallback extends StatelessWidget {
  const _ServiceHeroFallback({
    required this.service,
    required this.compact,
    required this.radius,
  });

  final ServiceModel service;
  final bool compact;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: residentBrandTeal.withValues(alpha: compact ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: residentBrandTeal.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(service.category),
          size: JiraniResponsive.scaled(context, compact ? 28 : 50),
          color: residentBrandTeal.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

String _serviceImageAt(ServiceModel service, int index) {
  final images = service.imageUrls
      .where((url) => url.trim().isNotEmpty)
      .map((url) => url.trim())
      .toList(growable: false);
  return index < images.length ? images[index] : '';
}

class _ServiceRequestSummaryListCard extends StatelessWidget {
  const _ServiceRequestSummaryListCard({
    required this.request,
    required this.user,
    required this.requesterView,
    required this.onOpen,
    required this.onViewProfile,
  });

  final ServiceRequestModel request;
  final AppUser user;
  final bool requesterView;
  final VoidCallback onOpen;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.read<services.ServiceProvider>();
    final busy = context.watch<services.ServiceProvider>().isLoading;
    final personName = requesterView ? request.providerName : request.requesterName;
    final personRole = requesterView ? 'Service provider' : 'Requester';
    final canQuickAction =
        !requesterView &&
        request.status == AppConstants.serviceRequestStatusPending;

    return ResidentGlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResidentAvatar(name: personName, photoUrl: ''),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                personName.trim().isEmpty ? 'Resident' : personName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.appInk,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                personRole,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.appMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ResidentStatusPill(
                              label: _requestStatusLabel(request.status),
                            ),
                            const SizedBox(height: 8),
                            _ServiceTinyTextButton(
                              label: 'Profile',
                              icon: Icons.person_search_rounded,
                              onTap: onViewProfile,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ServiceRequestThumb(
                          serviceId: request.serviceId,
                          serviceTitle: request.serviceTitle,
                          size: 68,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.serviceTitle,
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
                                _requestScheduleLabel(request),
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
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _requestAmountLabel(request),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: residentBrandTeal,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (request.isHourlyService)
                                    Text(
                                      '${request.durationHours} h booked',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.appMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canQuickAction) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ResidentDangerButton(
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
                              successMessage: 'Booking rejected.',
                            ),
                  ),
                ),
                const SizedBox(width: 10),
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
                              successMessage: 'Booking accepted.',
                            ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceTinyTextButton extends StatelessWidget {
  const _ServiceTinyTextButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: residentBrandTeal.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: residentBrandTeal, size: 15),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: residentBrandTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRequestThumb extends StatelessWidget {
  const _ServiceRequestThumb({
    required this.serviceId,
    required this.serviceTitle,
    this.size = 68,
  });

  final String serviceId;
  final String serviceTitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceModel?>(
      future: context.read<services.ServiceProvider>().getService(serviceId),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data?.imageUrls
            .where((url) => url.trim().isNotEmpty)
            .map((url) => url.trim())
            .firstOrNull;
        if (imageUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: size,
              height: size,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, _) => ResidentIconTile(
                  icon: Icons.handshake_outlined,
                  size: size,
                ),
                errorWidget: (context, _, _) => ResidentIconTile(
                  icon: Icons.handshake_outlined,
                  size: size,
                ),
              ),
            ),
          );
        }
        return ResidentIconTile(
          icon: Icons.handshake_outlined,
          size: size,
        );
      },
    );
  }
}

class _ServiceSkeletonCard extends StatelessWidget {
  const _ServiceSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return ResidentGlassPanel(
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
    );
  }
}
