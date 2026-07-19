// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_process_timeline_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../verification_process_view.dart';

class _VerificationTimeline extends StatelessWidget {
  const _VerificationTimeline({required this.steps});

  final List<_ProgressStepData> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({required this.steps});

  final List<_ProgressStepData> steps;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final completed = steps
        .where((step) => step.state == _StepState.complete)
        .length;
    final rejected = steps.any((step) => step.state == _StepState.rejected);
    final accent = rejected ? const Color(0xFFE5484D) : _kBrandTeal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              rejected
                  ? Icons.error_outline_rounded
                  : Icons.verified_user_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rejected
                      ? 'Verification Needs Attention'
                      : '$completed of ${steps.length} Steps Complete',
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  rejected
                      ? 'Review the highlighted step and submit updated proof.'
                      : 'Completed tasks stay highlighted as you move forward.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isLast});

  final _ProgressStepData step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = _StepColors.forState(context, step.state);
    final ink = context.appInk;
    final muted = context.appMuted;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isLast ? 84 : 116),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 67,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (!isLast)
                    Positioned(
                      top: 67,
                      bottom: 0,
                      child: SizedBox(
                        width: 2,
                        child: CustomPaint(
                          painter: _DashedLinePainter(color: colors.connector),
                        ),
                      ),
                    ),
                  Container(
                    width: 67,
                    height: 67,
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(step.icon, size: 28, color: colors.icon),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 1, bottom: isLast ? 0 : 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: TextStyle(
                                color: ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                          ),
                          _StepChip(label: colors.label, color: colors.icon),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.description,
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const dashHeight = 8.0;
    const dashGap = 4.0;
    var y = 0.0;
    final x = size.width / 2;

    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dashHeight).clamp(0, size.height)),
        paint,
      );
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
