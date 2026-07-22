// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : reviews_tab_bar.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_reviews_view.dart';

class _ReviewTabBar extends StatelessWidget {
  const _ReviewTabBar({required this.selected, required this.onChanged});

  final _ReviewTab selected;
  final ValueChanged<_ReviewTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'All',
            selected: selected == _ReviewTab.all,
            onTap: () => onChanged(_ReviewTab.all),
          ),
          _TabButton(
            label: 'Lending',
            selected: selected == _ReviewTab.lending,
            onTap: () => onChanged(_ReviewTab.lending),
          ),
          _TabButton(
            label: 'Borrowing',
            selected: selected == _ReviewTab.borrowing,
            onTap: () => onChanged(_ReviewTab.borrowing),
          ),
          _TabButton(
            label: 'Services',
            selected: selected == _ReviewTab.services,
            onTap: () => onChanged(_ReviewTab.services),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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

    return Expanded(
      child: Material(
        color: selected ? _kBrandTeal : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? onPrimary : context.appMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
