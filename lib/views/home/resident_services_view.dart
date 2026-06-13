import 'package:flutter/material.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF8E8E93);
const double _kMaxContentWidth = 390;

class ResidentServicesView extends StatelessWidget {
  const ResidentServicesView({super.key});

  static const _services = <_ServiceCardData>[
    _ServiceCardData(
      name: 'Carl Johnson',
      category: 'Handyman',
      rating: '4.0 (32 Reviews)',
      title: 'Handyman & Repairs',
      status: 'Service in Progress',
      price: 'RM 30',
      icon: Icons.construction_rounded,
    ),
    _ServiceCardData(
      name: 'Farah Islam',
      category: 'Home Care',
      rating: '4.9 (18 Reviews)',
      title: 'Home Care Assistant',
      status: 'Available',
      price: 'RM 25 /hr',
      icon: Icons.cleaning_services_rounded,
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
                          SizedBox(height: 24),
                          _PageHeader(
                            title: 'Services',
                            subtitle:
                                'Find reliable help from people in your community.',
                          ),
                          SizedBox(height: 20),
                          _SearchField(hint: 'Search services...'),
                          SizedBox(height: 16),
                          _CategoryChips(
                            labels: ['All', 'Handyman', 'Tutoring', 'Personal'],
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: _services.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: _ServiceCard(data: _services[index]),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 112)),
              ],
            ),
            const Positioned(right: 24, bottom: 24, child: _AddButton()),
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
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _kBrandTeal, size: 23),
          const SizedBox(width: 12),
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
      height: 38,
      constraints: const BoxConstraints(minWidth: 56),
      padding: const EdgeInsets.symmetric(horizontal: 18),
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

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.data});

  final _ServiceCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 284),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProviderAvatar(icon: data.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.category,
                      style: const TextStyle(
                        color: _kMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFCC00),
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              data.rating,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'STARTING FROM',
                      style: TextStyle(
                        color: _kMutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.price,
                      style: const TextStyle(
                        color: _kBrandTeal,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(label: data.status),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionButton(label: 'Message ${data.firstName}'),
              ),
              const SizedBox(width: 10),
              const Expanded(child: _ActionButton(label: 'View Profile')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: _kBrandTeal.withValues(alpha: 0.75), size: 48),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
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
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 58,
          height: 58,
          child: Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _ServiceCardData {
  const _ServiceCardData({
    required this.name,
    required this.category,
    required this.rating,
    required this.title,
    required this.status,
    required this.price,
    required this.icon,
  });

  final String name;
  final String category;
  final String rating;
  final String title;
  final String status;
  final String price;
  final IconData icon;

  String get firstName => name.split(' ').first;
}
