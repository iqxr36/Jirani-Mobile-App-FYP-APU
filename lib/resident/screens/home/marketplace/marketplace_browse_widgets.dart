part of '../resident_marketplace_view.dart';

class _BorrowRequestCard extends StatelessWidget {
  const _BorrowRequestCard({required this.request, required this.onTap});

  final BorrowRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final total = MarketplaceBorrowFlow.totalDue(
      usageFee: request.usageFeeAmount,
      deposit: request.depositAmount,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: _GlassPanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _RequestThumb(imageUrl: request.itemImageUrl, size: 70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_compactDateFormat.format(request.requestedStartDate)} - ${_compactDateFormat.format(request.expectedReturnDate)}',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(label: _statusLabel(request)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _money(total),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kBrandTeal,
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
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({required this.item, required this.onTap});

  final ItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 22),
        ),
        child: _GlassPanel(
          padding: JiraniResponsive.scaledEdgeInsets(
            context,
            left: 14,
            top: 14,
            right: 14,
            bottom: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardImageStrip(item: item),
              SizedBox(height: JiraniResponsive.scaled(context, 14)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        height: 1.15,
                      ),
                    ),
                  ),
                  SizedBox(width: JiraniResponsive.scaled(context, 8)),
                  const _StatusPill(label: 'Available'),
                ],
              ),
              SizedBox(height: JiraniResponsive.scaled(context, 4)),
              Text(
                _categoryLabel(item.category),
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: JiraniResponsive.scaled(context, 12)),
              Row(
                children: [
                  _Avatar(photoUrl: item.ownerPhotoUrl, name: item.ownerName),
                  SizedBox(width: JiraniResponsive.scaled(context, 8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.ownerVerified ? 'Verified resident' : 'Resident',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: JiraniResponsive.scaled(context, 8)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.hasUsageFee
                            ? '${_money(item.feeAmount)} / day'
                            : 'Free',
                        style: const TextStyle(
                          color: _kBrandTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.hasDeposit
                            ? '${_money(item.depositAmount)} Deposit'
                            : 'No deposit',
                        style: TextStyle(
                          color: muted,
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
        ),
      ),
    );
  }
}

class _CardImageStrip extends StatelessWidget {
  const _CardImageStrip({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: JiraniResponsive.scaled(context, 124),
      child: Row(
        children: [
          Expanded(flex: 3, child: _ItemImage(url: _imageAt(item, 0))),
          SizedBox(width: JiraniResponsive.scaled(context, 10)),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _ItemImage(url: _imageAt(item, 1), compact: true),
                ),
                SizedBox(height: JiraniResponsive.scaled(context, 10)),
                Expanded(
                  child: _ItemImage(url: _imageAt(item, 2), compact: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.url, this.compact = false});

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = JiraniResponsive.scaledRadius(context, 18);
    if (url.trim().isEmpty) {
      return _ImagePlaceholder(compact: compact, radius: radius);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) =>
            _ImagePlaceholder(compact: compact, radius: radius),
        errorWidget: (context, _, _) =>
            _ImagePlaceholder(compact: compact, radius: radius),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.compact, required this.radius});

  final bool compact;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: compact ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.08)),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        size: JiraniResponsive.scaled(context, compact ? 28 : 50),
        color: _kBrandTeal.withValues(alpha: 0.72),
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({required this.item, required this.onTap});

  final ItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final profileRepository = PublicProfileRepository();

    return StreamBuilder<PublicResidentProfile?>(
      stream: profileRepository.watchProfile(item.ownerId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final ownerName = profile != null && profile.fullName.trim().isNotEmpty
            ? profile.fullName
            : item.ownerName;
        final verified = profile?.isVerifiedResident ?? item.ownerVerified;
        final reputationScore = profile != null
            ? (profile.communityTrustScore > 0
                ? profile.communityTrustScore
                : profile.reputationScore)
            : item.ownerReputationScore;
        final photoReference =
            profile != null && profile.profileImageUrl.trim().isNotEmpty
            ? profile.profileImageUrl
            : item.ownerPhotoUrl;
        final ratingLabel = reputationScore > 0
            ? reputationScore.toStringAsFixed(1)
            : '-';

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.softSurface(),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.residentOutline()),
              ),
              child: Row(
                children: [
                  _Avatar(
                    photoUrl: photoReference,
                    name: ownerName,
                    radius: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${verified ? 'Verified resident' : 'Resident'} - $ratingLabel rating',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: muted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name, this.radius = 17});

  final String photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ResolvedProfileAvatar(
      photoReference: photoUrl,
      name: name,
      radius: radius,
      initialsColor: _kBrandTeal,
      placeholderColor: context.avatarPlaceholder,
    );
  }
}

