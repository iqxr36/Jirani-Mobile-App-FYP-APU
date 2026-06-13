import 'package:flutter/material.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kModalSurface = Colors.white;
const Color _kMutedText = Color(0xFF6B7280);

Future<T?> showJiraniModalBottomSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  IconData? icon,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (context) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
              child: _JiraniModalSurface(
                title: title,
                subtitle: subtitle,
                icon: icon,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class JiraniDialog extends StatelessWidget {
  const JiraniDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.content,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _kModalSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _JiraniModalHeader(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                ),
                const SizedBox(height: 18),
                content,
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JiraniModalOption extends StatelessWidget {
  const JiraniModalOption({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.selected = false,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? _kBrandTeal
        : Colors.black.withValues(alpha: 0.10);
    final backgroundColor = selected
        ? _kBrandTeal.withValues(alpha: 0.08)
        : const Color(0xFFF9FBFB);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kBrandTeal.withValues(
                      alpha: selected ? 0.16 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _kBrandTeal, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kMutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected
                      ? _kBrandTeal
                      : Colors.black.withValues(alpha: 0.28),
                  size: selected ? 22 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JiraniModalSurface extends StatelessWidget {
  const _JiraniModalSurface({
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kModalSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _JiraniModalHeader(title: title, subtitle: subtitle, icon: icon),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JiraniModalHeader extends StatelessWidget {
  const _JiraniModalHeader({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _kBrandTeal, size: 23),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.15,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: _kMutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
