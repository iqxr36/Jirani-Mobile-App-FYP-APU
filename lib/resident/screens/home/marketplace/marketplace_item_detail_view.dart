part of '../resident_marketplace_view.dart';

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
                      _ItemImageGallery(item: item),
                      const SizedBox(height: 18),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      color: context.appInk,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
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
                      Row(
                        children: [
                          Expanded(
                            child: _SecondaryButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Message Owner',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Chat with the owner unlocks after approval and payment are completed.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PrimaryButton(
                              icon: Icons.calendar_month_rounded,
                              label: 'Request',
                              onTap: () => _showBorrowRequestSheet(
                                context: context,
                                item: item,
                              ),
                            ),
                          ),
                        ],
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

