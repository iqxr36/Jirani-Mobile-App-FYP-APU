part of '../resident_marketplace_view.dart';

// Marketplace item detail feature: shows one listing and opens the borrow request sheet.
class MarketplaceItemDetailView extends StatelessWidget {
  const MarketplaceItemDetailView({super.key, required this.item});

  final ItemModel item;

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
                child: _InsetContent(
                  sideInset: sideInset,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _ScreenTitleBar(
                        title: 'Item Details',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 14),
                      _DetailImageGallery(item: item),
                      const SizedBox(height: 14),
                      _GlassPanel(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
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
                                const _StatusPill(label: 'Available'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_categoryLabel(item.category)} · ${_conditionLabel(item.condition)}',
                              style: TextStyle(
                                color: context.appMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Deposit is held securely and refunded in full when the item is returned in good condition.',
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
                      _GlassPanel(
                        child: Row(
                          children: [
                            Expanded(
                              child: _AmountTile(
                                label: 'Daily Fee',
                                value: item.hasUsageFee
                                    ? _money(item.feeAmount)
                                    : 'Free',
                                helper: item.hasUsageFee
                                    ? 'Hourly is derived and capped'
                                    : 'No fee',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _AmountTile(
                                label: 'Refundable Deposit',
                                value: item.hasDeposit
                                    ? _money(item.depositAmount)
                                    : 'None',
                                helper: item.hasDeposit
                                    ? 'Returned after inspection'
                                    : 'Not required',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionLabel('Lender'),
                            const SizedBox(height: 10),
                            _OwnerRow(
                              item: item,
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => PublicResidentProfileView(
                                    userId: item.ownerId,
                                    fallbackName: item.ownerName,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('Description'),
                            const SizedBox(height: 8),
                            Text(
                              item.description.trim().isEmpty
                                  ? 'No description has been added yet.'
                                  : item.description.trim(),
                              style: TextStyle(
                                color: context.appInk,
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.pickupInstructions.trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const _SectionLabel('Pickup Notes'),
                              const SizedBox(height: 8),
                              Text(
                                item.pickupInstructions.trim(),
                                style: TextStyle(
                                  color: context.appInk,
                                  fontSize: 14,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PrimaryButton(
                        icon: Icons.calendar_month_rounded,
                        label: 'Request',
                        onTap: () => _showBorrowRequestSheet(
                          context: context,
                          item: item,
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

class _DetailImageGallery extends StatefulWidget {
  const _DetailImageGallery({required this.item});

  final ItemModel item;

  @override
  State<_DetailImageGallery> createState() => _DetailImageGalleryState();
}

class _DetailImageGalleryState extends State<_DetailImageGallery> {
  late final PageController _controller;
  int _index = 0;

  List<String> get _images => widget.item.imageUrls
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
        builder: (_) => _ItemPhotoViewer(
          imageUrls: images,
          initialIndex: index,
          title: widget.item.title,
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
        child: _ImagePlaceholder(compact: false, radius: radius),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Open item photo',
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
                            placeholder: (context, _) => _ImagePlaceholder(
                              compact: false,
                              radius: radius,
                            ),
                            errorWidget: (context, _, _) => _ImagePlaceholder(
                              compact: false,
                              radius: radius,
                            ),
                          );
                        },
                      ),
                    ),
                    const Positioned(
                      right: 12,
                      top: 12,
                      child: _GalleryBadge(
                        icon: Icons.open_in_full_rounded,
                        label: 'View',
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _GalleryBadge(
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
          const SizedBox(height: 10),
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _GalleryThumb(
                  imageUrl: images[index],
                  selected: index == _index,
                  onTap: () {
                    _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                    );
                    setState(() => _index = index);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({
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
              color: selected ? _kBrandTeal : context.glassBorder(),
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, _) =>
                  _ImagePlaceholder(compact: true, radius: 11),
              errorWidget: (context, _, _) =>
                  _ImagePlaceholder(compact: true, radius: 11),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryBadge extends StatelessWidget {
  const _GalleryBadge({required this.icon, required this.label});

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

class _ItemPhotoViewer extends StatefulWidget {
  const _ItemPhotoViewer({
    required this.imageUrls,
    required this.initialIndex,
    required this.title,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String title;

  @override
  State<_ItemPhotoViewer> createState() => _ItemPhotoViewerState();
}

class _ItemPhotoViewerState extends State<_ItemPhotoViewer> {
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
                  const SizedBox(width: 10),
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
                  const SizedBox(width: 10),
                  _GalleryBadge(
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

