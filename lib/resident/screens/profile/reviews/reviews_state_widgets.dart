part of '../resident_reviews_view.dart';

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState({required this.tab});

  final _ReviewTab tab;

  @override
  Widget build(BuildContext context) {
    final label = switch (tab) {
      _ReviewTab.all => 'No published reviews yet',
      _ReviewTab.lending => 'No lending reviews yet',
      _ReviewTab.borrowing => 'No borrowing reviews yet',
    };
    return _StatePanel(
      icon: Icons.rate_review_outlined,
      title: label,
      message: 'Completed reviews will appear here after the blind period.',
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const _StatePanel(
      icon: Icons.hourglass_empty_rounded,
      title: 'Loading reviews',
      message: 'Checking published marketplace feedback.',
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.error_outline_rounded,
      title: 'Reviews unavailable',
      message: message.replaceFirst('Exception: ', ''),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const _StatePanel(
      icon: Icons.lock_outline_rounded,
      title: 'Sign in required',
      message: 'Your reviews are available after signing in.',
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          Icon(icon, color: _kBrandTeal, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
