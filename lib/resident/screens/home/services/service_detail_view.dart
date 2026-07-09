part of '../resident_services_view.dart';

class ServiceDetailView extends StatelessWidget {
  const ServiceDetailView({
    super.key,
    required this.user,
    required this.service,
  });

  final AppUser user;
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ResidentInsetContent(
                  sideInset: sideInset,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      ResidentScreenTitleBar(
                        title: 'Service Details',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 14),
                      _ServiceDetailGallery(service: service),
                      const SizedBox(height: 14),
                      ResidentGlassPanel(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    service.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.appInk,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      height: 1.16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const ResidentStatusPill(label: 'Available'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _categoryLabel(service.category),
                              style: TextStyle(
                                color: context.appMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              service.availability.trim().isEmpty
                                  ? 'Availability is confirmed after request.'
                                  : service.availability.trim(),
                              style: TextStyle(
                                color: context.appMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ResidentGlassPanel(
                        child: Column(
                          children: [
                            ResidentSummaryRow(
                              label: 'Price',
                              value: _priceLabel(service),
                              emphasized: true,
                            ),
                            const SizedBox(height: 8),
                            ResidentSummaryRow(
                              label: 'Pricing mode',
                              value: _priceTypeLabel(service),
                            ),
                            const SizedBox(height: 8),
                            ResidentSummaryRow(
                              label: 'Category',
                              value: _categoryLabel(service.category),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ResidentGlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _PanelLabel('Provider'),
                            const SizedBox(height: 10),
                            ResidentPersonRow(
                              name: service.providerName,
                              subtitle: service.availability.trim().isEmpty
                                  ? 'Availability by request'
                                  : service.availability.trim(),
                              photoUrl: service.providerPhotoUrl,
                              onTap: service.providerId.trim().isEmpty
                                  ? null
                                  : () => Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              PublicResidentProfileView(
                                            userId: service.providerId,
                                            fallbackName:
                                                service.providerName,
                                          ),
                                        ),
                                      ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: residentBrandTeal,
                                  backgroundColor: residentBrandTeal
                                      .withValues(alpha: 0.10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                onPressed: service.providerId.trim().isEmpty
                                    ? null
                                    : () => Navigator.of(context).push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                PublicResidentProfileView(
                                              userId: service.providerId,
                                              fallbackName:
                                                  service.providerName,
                                            ),
                                          ),
                                        ),
                                icon: const Icon(
                                  Icons.person_search_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'View Profile',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ResidentGlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PanelLabel('Description'),
                            const SizedBox(height: 8),
                            Text(
                              service.description.trim().isEmpty
                                  ? 'No description has been added yet.'
                                  : service.description.trim(),
                              style: TextStyle(
                                color: context.appInk,
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (service.certificateUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ResidentGlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _PanelTitle(
                                icon: Icons.workspace_premium_outlined,
                                title: 'Self-provided certificates',
                              ),
                              const SizedBox(height: 10),
                              for (
                                var i = 0;
                                i < service.certificateUrls.length;
                                i += 1
                              )
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        i == service.certificateUrls.length - 1
                                            ? 0
                                            : 8,
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
                      const SizedBox(height: 18),
                      ResidentPrimaryButton(
                        icon: Icons.receipt_long_rounded,
                        label: 'Request Service',
                        onTap: () => _showRequestSheet(
                          context,
                          user,
                          service,
                        ),
                      ),
                      const SizedBox(height: 34),
                    ],
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

class _ServiceDetailGallery extends StatefulWidget {
  const _ServiceDetailGallery({required this.service});

  final ServiceModel service;

  @override
  State<_ServiceDetailGallery> createState() => _ServiceDetailGalleryState();
}

class _ServiceDetailGalleryState extends State<_ServiceDetailGallery> {
  late final PageController _controller;
  int _index = 0;

  List<String> get _images => widget.service.imageUrls
      .where((url) => url.trim().isNotEmpty)
      .map((url) => url.trim())
      .toList();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int index) {
    final images = _images;
    if (images.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ServicePhotoViewer(
          imageUrls: images,
          initialIndex: index,
          title: widget.service.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final radius = JiraniResponsive.scaledRadius(context, 22);
    final height = JiraniResponsive.scaled(context, 250);

    if (images.isEmpty) {
      return SizedBox(
        height: height,
        child: _ServiceDetailPlaceholder(
          icon: _categoryIcon(widget.service.category),
          label: _categoryLabel(widget.service.category),
          radius: radius,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Open service photo',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openViewer(_index),
              child: SizedBox(
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: context.softSurface(),
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: images.length,
                        onPageChanged: (value) =>
                            setState(() => _index = value),
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.contain,
                            placeholder: (context, _) => _ServiceDetailPlaceholder(
                              icon: _categoryIcon(widget.service.category),
                              label: _categoryLabel(widget.service.category),
                              radius: radius,
                            ),
                            errorWidget: (context, _, _) =>
                                _ServiceDetailPlaceholder(
                              icon: Icons.image_not_supported_outlined,
                              label: 'Photo unavailable',
                              radius: radius,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: _ServiceGalleryBadge(
                        icon: Icons.open_in_full_rounded,
                        label: 'View',
                      ),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: _ServiceGalleryBadge(
                        icon: Icons.photo_library_outlined,
                        label: '${_index + 1}/${images.length}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) => _ServiceDetailPhotoThumb(
                imageUrl: images[index],
                selected: index == _index,
                onTap: () {
                  _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  );
                  setState(() => _index = index);
                },
              ),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemCount: images.length,
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceDetailPlaceholder extends StatelessWidget {
  const _ServiceDetailPlaceholder({
    required this.icon,
    required this.label,
    required this.radius,
  });

  final IconData icon;
  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: residentBrandTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.glassBorder()),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: residentBrandTeal, size: 46),
          const SizedBox(height: 10),
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
      ),
    );
  }
}

class _ServiceGalleryBadge extends StatelessWidget {
  const _ServiceGalleryBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceDetailPhotoThumb extends StatelessWidget {
  const _ServiceDetailPhotoThumb({
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 64,
          padding: EdgeInsets.all(selected ? 2 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? residentBrandTeal : context.glassBorder(),
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, _) => ColoredBox(
                color: residentBrandTeal.withValues(alpha: 0.10),
              ),
              errorWidget: (context, _, _) => const Icon(
                Icons.image_not_supported_outlined,
                color: residentBrandTeal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicePhotoViewer extends StatefulWidget {
  const _ServicePhotoViewer({
    required this.imageUrls,
    required this.initialIndex,
    required this.title,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String title;

  @override
  State<_ServicePhotoViewer> createState() => _ServicePhotoViewerState();
}

class _ServicePhotoViewerState extends State<_ServicePhotoViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrls[index],
                      fit: BoxFit.contain,
                      placeholder: (context, _) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 8,
              child: Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.58),
                      foregroundColor: Colors.white,
                    ),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ServiceGalleryBadge(
                    icon: Icons.photo_library_outlined,
                    label: '${_index + 1}/${widget.imageUrls.length}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
