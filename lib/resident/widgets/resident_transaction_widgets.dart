// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_transaction_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Monday,06-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';

const Color residentBrandTeal = Color(0xFF006D77);
const Color residentWarmAccent = Color(0xFFE29578);
const double residentMaxContentWidth = 440;

class ResidentPageHeader extends StatelessWidget {
  const ResidentPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

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
            color: residentBrandTeal,
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

class ResidentScreenTitleBar extends StatelessWidget {
  const ResidentScreenTitleBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ResidentCircleIconButton(
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
              color: residentBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Align(
            alignment: Alignment.centerRight,
            child: trailing ?? const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class ResidentCircleIconButton extends StatelessWidget {
  const ResidentCircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.glassFill(lightAlpha: 0.84),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: residentBrandTeal, size: 24),
          ),
        ),
      ),
    );
  }
}

class ResidentInsetContent extends StatelessWidget {
  const ResidentInsetContent({
    super.key,
    required this.sideInset,
    required this.child,
  });

  final double sideInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sideInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: residentMaxContentWidth),
          child: child,
        ),
      ),
    );
  }
}

class ResidentGlassPanel extends StatelessWidget {
  const ResidentGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = JiraniResponsive.scaledRadius(context, 22);
    final content = Container(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.glassBorder()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkUi ? 0.24 : 0.09,
            ),
            blurRadius: JiraniResponsive.scaled(context, 24),
            offset: Offset(0, JiraniResponsive.scaled(context, 12)),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class ResidentSectionOption<T> {
  const ResidentSectionOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

class ResidentSectionSwitch<T> extends StatelessWidget {
  const ResidentSectionSwitch({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final T selected;
  final List<ResidentSectionOption<T>> options;
  final ValueChanged<T> onChanged;

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
          for (final option in options)
            Expanded(
              child: _ResidentSectionButton(
                label: option.label,
                icon: option.icon,
                selected: selected == option.value,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResidentSectionButton extends StatelessWidget {
  const _ResidentSectionButton({
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
          color: selected ? residentBrandTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? onPrimary : muted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? onPrimary : context.appInk,
                  fontSize: 11,
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

class ResidentSearchField extends StatelessWidget {
  const ResidentSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

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
            color: residentBrandTeal,
            size: JiraniResponsive.scaled(context, 22),
          ),
          SizedBox(width: JiraniResponsive.scaled(context, 12)),
          Expanded(
            child: TextField(
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

class ResidentCategoryOption {
  const ResidentCategoryOption(this.label, this.value);

  final String label;
  final String value;
}

class ResidentCategoryChips extends StatelessWidget {
  const ResidentCategoryChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<ResidentCategoryOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            ResidentCategoryChip(
              label: options[i].label,
              selected: selected == options[i].value,
              onTap: () => onSelected(options[i].value),
            ),
            if (i != options.length - 1) const SizedBox(width: 9),
          ],
        ],
      ),
    );
  }
}

class ResidentCategoryChip extends StatelessWidget {
  const ResidentCategoryChip({
    super.key,
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
          color: selected ? residentBrandTeal : context.softSurface(),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? residentBrandTeal
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

class ResidentStatusPill extends StatelessWidget {
  const ResidentStatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: residentBrandTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: residentBrandTeal,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class ResidentPrimaryButton extends StatelessWidget {
  const ResidentPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon ?? Icons.check_rounded, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: residentBrandTeal,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class ResidentSecondaryButton extends StatelessWidget {
  const ResidentSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon ?? Icons.chevron_right_rounded, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: residentBrandTeal,
          side: BorderSide(color: context.glassBorder(lightAlpha: 0.95)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class ResidentDangerButton extends StatelessWidget {
  const ResidentDangerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon ?? Icons.report_problem_outlined, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.error,
          side: BorderSide(color: scheme.error.withValues(alpha: 0.45)),
          backgroundColor: scheme.errorContainer.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class ResidentStateCard extends StatelessWidget {
  const ResidentStateCard({
    super.key,
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
    return ResidentGlassPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: residentBrandTeal, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
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

class ResidentIconTile extends StatelessWidget {
  const ResidentIconTile({
    super.key,
    required this.icon,
    this.size = 52,
    this.radius = 14,
  });

  final IconData icon;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: residentBrandTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: residentBrandTeal),
    );
  }
}

class ResidentAvatar extends StatelessWidget {
  const ResidentAvatar({
    super.key,
    required this.name,
    this.photoUrl = '',
    this.radius = 18,
  });

  final String name;
  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.avatarPlaceholder,
      child: Text(
        initials,
        style: const TextStyle(
          color: residentBrandTeal,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class ResidentPersonRow extends StatelessWidget {
  const ResidentPersonRow({
    super.key,
    required this.name,
    required this.subtitle,
    this.photoUrl = '',
    this.onTap,
  });

  final String name;
  final String subtitle;
  final String photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
              ResidentAvatar(name: name, photoUrl: photoUrl, radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.trim().isEmpty ? 'Resident' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.appMuted,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ResidentTrackingStepCard extends StatelessWidget {
  const ResidentTrackingStepCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.child,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: residentBrandTeal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: residentBrandTeal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
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
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child!],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

class ResidentSummaryRow extends StatelessWidget {
  const ResidentSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? context.appInk : context.appMuted,
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
              color: emphasized ? residentBrandTeal : context.appInk,
              fontSize: emphasized ? 17 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class ResidentProgressStep {
  const ResidentProgressStep({
    required this.label,
    required this.icon,
    required this.done,
  });

  final String label;
  final IconData icon;
  final bool done;
}

class ResidentProgressPanel extends StatelessWidget {
  const ResidentProgressPanel({super.key, required this.steps});

  final List<ResidentProgressStep> steps;

  @override
  Widget build(BuildContext context) {
    final muted = context.appMuted;
    return ResidentGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(child: _ResidentStepChip(step: steps[i])),
            if (i != steps.length - 1)
              Container(
                width: 12,
                height: 2,
                color: steps[i].done
                    ? residentBrandTeal
                    : muted.withValues(alpha: 0.20),
              ),
          ],
        ],
      ),
    );
  }
}

class _ResidentStepChip extends StatelessWidget {
  const _ResidentStepChip({required this.step});

  final ResidentProgressStep step;

  @override
  Widget build(BuildContext context) {
    final muted = context.appMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: step.done ? residentBrandTeal : context.softSurface(),
            shape: BoxShape.circle,
            border: Border.all(
              color: step.done ? residentBrandTeal : context.residentOutline(),
            ),
          ),
          child: Icon(
            step.icon,
            color: step.done
                ? Theme.of(context).colorScheme.onPrimary
                : muted,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: step.done ? residentBrandTeal : muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class ResidentCodeDisplay extends StatelessWidget {
  const ResidentCodeDisplay({
    super.key,
    required this.label,
    required this.code,
  });

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    final cleanCode = code.trim().isEmpty ? '----' : code.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: residentBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: residentBrandTeal.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            cleanCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: residentBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
  return initials.isEmpty ? 'R' : initials;
}
