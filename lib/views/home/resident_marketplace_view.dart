import 'package:flutter/material.dart';
import 'package:jirani/widgets/common/jirani_background.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF8E8E93);
const double _kMaxContentWidth = 334;

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
    return JiraniBackground(
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kMaxContentWidth,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 64),
                          _SearchField(hint: 'Search in marketplace...'),
                          SizedBox(height: 20),
                          _CategoryChips(
                            labels: [
                              'All Items',
                              'Tools',
                              'Electronics',
                              'Home',
                            ],
                          ),
                          SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: _items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: _MarketplaceCard(item: _items[index]),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 106)),
              ],
            ),
            const Positioned(right: 26, bottom: 18, child: _AddButton()),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 59,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.black, size: 22),
          const SizedBox(width: 18),
          Text(
            hint,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
      height: 27,
      constraints: const BoxConstraints(minWidth: 39),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _kBrandTeal : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? _kBrandTeal : Colors.black.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
      height: 212,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _ItemImage(icon: item.icon)),
                const SizedBox(width: 8),
                Expanded(child: _ItemImage(icon: item.icon, compact: true)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              const _StatusPill(label: 'Available'),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            item.category,
            style: const TextStyle(
              color: _kMutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFCFE5E9),
                child: Icon(Icons.person, size: 18, color: _kBrandTeal),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.owner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.price,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.deposit,
                    style: const TextStyle(
                      color: _kMutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: compact ? 34 : 46,
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
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
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
    return Material(
      color: _kBrandTeal,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.add, color: Colors.white, size: 28),
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
