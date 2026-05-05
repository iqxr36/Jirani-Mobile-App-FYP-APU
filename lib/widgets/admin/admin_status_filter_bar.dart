import 'package:flutter/material.dart';

class AdminStatusFilterBar extends StatelessWidget {
  const AdminStatusFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _filters = <(String, String)>[
    ('submitted', 'Submitted'),
    ('verified', 'Verified'),
    ('rejected', 'Rejected'),
    ('all', 'All'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _filters
          .map(
            (f) => ChoiceChip(
              label: Text(f.$2),
              selected: selected == f.$1,
              onSelected: (_) => onChanged(f.$1),
            ),
          )
          .toList(growable: false),
    );
  }
}
