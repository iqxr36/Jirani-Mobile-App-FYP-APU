part of '../verification_process_view.dart';

class _ProgressStepData {
  const _ProgressStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.state,
  });

  final String title;
  final String description;
  final IconData icon;
  final _StepState state;
}

enum _StepState { complete, current, waiting, rejected }

class _StepColors {
  const _StepColors({
    required this.background,
    required this.icon,
    required this.cardBackground,
    required this.border,
    required this.connector,
    required this.label,
  });

  final Color background;
  final Color icon;
  final Color cardBackground;
  final Color border;
  final Color connector;
  final String label;

  static _StepColors forState(BuildContext context, _StepState state) {
    if (context.isDarkUi) {
      final scheme = context.residentScheme;
      switch (state) {
        case _StepState.complete:
          return _StepColors(
            background: scheme.primaryContainer.withValues(alpha: 0.72),
            icon: scheme.primary,
            cardBackground: scheme.surfaceContainerHighest.withValues(
              alpha: 0.92,
            ),
            border: scheme.outlineVariant,
            connector: scheme.primary,
            label: 'DONE',
          );
        case _StepState.current:
          return _StepColors(
            background: scheme.primary.withValues(alpha: 0.28),
            icon: scheme.primary,
            cardBackground: scheme.surfaceContainerHighest.withValues(
              alpha: 0.92,
            ),
            border: scheme.primary.withValues(alpha: 0.42),
            connector: scheme.primary.withValues(alpha: 0.42),
            label: 'NOW',
          );
        case _StepState.rejected:
          return _StepColors(
            background: scheme.errorContainer.withValues(alpha: 0.72),
            icon: scheme.error,
            cardBackground: scheme.surfaceContainerHighest.withValues(
              alpha: 0.92,
            ),
            border: scheme.error.withValues(alpha: 0.42),
            connector: scheme.error,
            label: 'FIX',
          );
        case _StepState.waiting:
          return _StepColors(
            background: scheme.surfaceContainerHighest,
            icon: scheme.onSurfaceVariant,
            cardBackground: scheme.surfaceContainerHighest.withValues(
              alpha: 0.92,
            ),
            border: scheme.outlineVariant,
            connector: scheme.outlineVariant.withValues(alpha: 0.55),
            label: 'WAIT',
          );
      }
    }

    switch (state) {
      case _StepState.complete:
        return const _StepColors(
          background: Color(0xFFD7F6DE),
          icon: Color(0xFF157A38),
          cardBackground: Color(0xFFF3FCF5),
          border: Color(0xFFB8E8C5),
          connector: Color(0xFF34C759),
          label: 'DONE',
        );
      case _StepState.current:
        return const _StepColors(
          background: Color(0x4083C5BE),
          icon: _kBrandTeal,
          cardBackground: Color(0xFFF2FBFA),
          border: Color(0x6683C5BE),
          connector: Color(0x6683C5BE),
          label: 'NOW',
        );
      case _StepState.rejected:
        return const _StepColors(
          background: Color(0xFFFFDFE2),
          icon: Color(0xFFE5484D),
          cardBackground: Color(0xFFFFF5F6),
          border: Color(0xFFFFBAC0),
          connector: Color(0xFFFF8F98),
          label: 'FIX',
        );
      case _StepState.waiting:
        return const _StepColors(
          background: Color(0xFFEFEFF0),
          icon: Color(0xFF737378),
          cardBackground: Colors.white,
          border: Color(0xFFE3E3E6),
          connector: Color(0x4D3C3C43),
          label: 'WAIT',
        );
    }
  }
}
