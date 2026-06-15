import 'package:flutter/material.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF8E8E93);
const double _kMaxContentWidth = 380;

class ResidentMarketplaceView extends StatelessWidget {
  const ResidentMarketplaceView({super.key});

  static const _items = <_MarketplaceItem>[
    _MarketplaceItem(
      title: 'Milwaukee Hammer Drill Set',
      category: 'Tools',
      owner: 'Faisal Ahmed',
      price: 'RM 25',
      deposit: 'RM 50 Deposit',
      icon: Icons.hardware_rounded,
    ),
    _MarketplaceItem(
      title: '20L Grill Microwave Oven',
      category: 'Electronics',
      owner: 'Farah Islam',
      price: 'RM 35',
      deposit: 'RM 300 Deposit',
      icon: Icons.microwave_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);

    return JiraniBackground(
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideInset),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 24),
                            _PageHeader(
                              title: 'Marketplace',
                              subtitle:
                                  'Borrow useful items from trusted neighbors nearby.',
                            ),
                            SizedBox(height: 20),
                            _SearchField(hint: 'Search in marketplace...'),
                            SizedBox(height: 16),
                            _CategoryChips(
                              labels: [
                                'All Items',
                                'Tools',
                                'Electronics',
                                'Home',
                              ],
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: _items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: sideInset),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _kMaxContentWidth,
                          ),
                          child: _MarketplaceCard(item: _items[index]),
                        ),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 112)),
              ],
            ),
            Positioned(
              right: sideInset,
              bottom: JiraniResponsive.scaled(context, 24),
              child: const _AddButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 54,
          decoration: BoxDecoration(
            color: _kBrandTeal,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF59666B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: JiraniResponsive.scaled(context, 56),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 20),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: JiraniResponsive.scaled(context, 22),
            offset: Offset(0, JiraniResponsive.scaled(context, 10)),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: JiraniResponsive.scaled(context, 16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: _kBrandTeal,
            size: JiraniResponsive.scaled(context, 22),
          ),
          SizedBox(width: JiraniResponsive.scaled(context, 12)),
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF59666B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            _CategoryChip(label: labels[i], selected: i == 0),
            if (i != labels.length - 1) const SizedBox(width: 9),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: JiraniResponsive.scaled(context, 40),
      constraints: const BoxConstraints(minWidth: 56),
      padding: EdgeInsets.symmetric(
        horizontal: JiraniResponsive.scaled(context, 16),
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _kBrandTeal : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? _kBrandTeal : Colors.white.withValues(alpha: 0.88),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.12 : 0.05),
            blurRadius: selected ? 18 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1F2937),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({required this.item});

  final _MarketplaceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: JiraniResponsive.scaled(context, 266),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 22),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: JiraniResponsive.scaled(context, 24),
            offset: Offset(0, JiraniResponsive.scaled(context, 12)),
          ),
        ],
      ),
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
          SizedBox(
            height: JiraniResponsive.scaled(context, 124),
            child: Row(
              children: [
                Expanded(flex: 3, child: _ItemImage(icon: item.icon)),
                SizedBox(width: JiraniResponsive.scaled(context, 10)),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _ItemImage(icon: item.icon, compact: true),
                      ),
                      SizedBox(height: JiraniResponsive.scaled(context, 10)),
                      Expanded(
                        child: _ItemImage(icon: item.icon, compact: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: JiraniResponsive.scaled(context, 14)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
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
            item.category,
            style: const TextStyle(
              color: _kMutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: JiraniResponsive.scaled(context, 12)),
          Row(
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFCFE5E9),
                child: Icon(Icons.person, size: 20, color: _kBrandTeal),
              ),
              SizedBox(width: JiraniResponsive.scaled(context, 8)),
              Expanded(
                child: Text(
                  item.owner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: JiraniResponsive.scaled(context, 8)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.price,
                    style: const TextStyle(
                      color: _kBrandTeal,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    item.deposit,
                    style: const TextStyle(
                      color: _kMutedText,
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

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.icon, this.compact = false});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: compact ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 16),
        ),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.08)),
      ),
      child: Icon(
        icon,
        size: JiraniResponsive.scaled(context, compact ? 28 : 48),
        color: _kBrandTeal.withValues(alpha: 0.72),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _kBrandTeal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    final size = JiraniResponsive.scaled(context, 56);
    return Material(
      color: _kBrandTeal,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: JiraniResponsive.scaled(context, 30),
          ),
        ),
      ),
    );
  }
}

class _MarketplaceItem {
  const _MarketplaceItem({
    required this.title,
    required this.category,
    required this.owner,
    required this.price,
    required this.deposit,
    required this.icon,
  });

  final String title;
  final String category;
  final String owner;
  final String price;
  final String deposit;
  final IconData icon;
}
