// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : marketplace_shared_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_marketplace_view.dart';

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
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.appMuted,
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

class _ScreenTitleBar extends StatelessWidget {
  const _ScreenTitleBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _CircleIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Back',
              onTap: onBack,
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 56),
      ],
    );
  }
}

class _SectionSwitch extends StatelessWidget {
  const _SectionSwitch({required this.selected, required this.onChanged});

  final _MarketplaceSection selected;
  final ValueChanged<_MarketplaceSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.glassBorder(lightAlpha: 0.90)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SectionButton(
              label: 'Browse',
              icon: Icons.storefront_rounded,
              selected: selected == _MarketplaceSection.browse,
              onTap: () => onChanged(_MarketplaceSection.browse),
            ),
          ),
          Expanded(
            child: _SectionButton(
              label: 'My Requests',
              icon: Icons.receipt_long_rounded,
              selected: selected == _MarketplaceSection.requests,
              onTap: () => onChanged(_MarketplaceSection.requests),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.appMuted;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kBrandTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? onPrimary : muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? onPrimary : context.appInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: JiraniResponsive.scaled(context, 56),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.78),
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 20),
        ),
        border: Border.all(color: context.glassBorder(lightAlpha: 0.86)),
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
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: TextStyle(
                  color: context.appMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextStyle(
                color: context.appInk,
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
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ItemProvider>().selectedCategoryFilter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < _categoryFilters.length; i++) ...[
            _CategoryChip(
              label: _categoryFilters[i].label,
              selected: selected == _categoryFilters[i].value,
              onTap: () => context.read<ItemProvider>().setCategoryFilter(
                _categoryFilters[i].value,
              ),
            ),
            if (i != _categoryFilters.length - 1) const SizedBox(width: 9),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: JiraniResponsive.scaled(context, 40),
        constraints: const BoxConstraints(minWidth: 56),
        padding: EdgeInsets.symmetric(
          horizontal: JiraniResponsive.scaled(context, 16),
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kBrandTeal : context.softSurface(),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _kBrandTeal
                : context.glassBorder(lightAlpha: 0.88),
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
            color: selected ? onPrimary : context.appInk,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InsetContent extends StatelessWidget {
  const _InsetContent({required this.sideInset, required this.child});

  final double sideInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sideInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: child,
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final panelColor = context.glassFill();
    final borderColor = context.glassBorder();

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 22),
        ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkUi ? 0.24 : 0.09),
            blurRadius: JiraniResponsive.scaled(context, 24),
            offset: Offset(0, JiraniResponsive.scaled(context, 12)),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _MarketplaceSkeletonCard extends StatelessWidget {
  const _MarketplaceSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 124,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.08),
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

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

    return _GlassPanel(
      child: Column(
        children: [
          Icon(icon, color: _kBrandTeal, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final muted = context.appMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kBrandTeal,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? ink : muted,
              fontSize: emphasized ? 15 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: emphasized ? _kBrandTeal : ink,
              fontSize: emphasized ? 17 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeDisplay extends StatelessWidget {
  const _CodeDisplay({required this.label, required this.code});

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    final muted = context.appMuted;
    final cleanCode = code.trim().isEmpty ? '----' : code.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final char in cleanCode.characters)
                Expanded(
                  child: Container(
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.softSurface(),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.residentOutline()),
                    ),
                    child: Text(
                      char,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _kBrandTeal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.appInk,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: disabled
          ? scheme.onSurface.withValues(alpha: 0.38)
          : _kBrandTeal,
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

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;

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
              Icon(icon, color: _kBrandTeal, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
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

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = disabled
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
        : const Color(0xFFB42318);
    return Material(
      color: color.withValues(alpha: context.isDarkUi ? 0.22 : 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.glassFill(lightAlpha: 0.90),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: _kBrandTeal),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = JiraniResponsive.scaled(context, 56);
    return Material(
      color: _kBrandTeal,
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

class _RequestThumb extends StatelessWidget {
  const _RequestThumb({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _ItemImage(url: imageUrl, compact: true),
    );
  }
}
