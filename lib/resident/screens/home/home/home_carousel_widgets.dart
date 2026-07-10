part of '../resident_home_view.dart';

class _CarouselSlide {
  const _CarouselSlide({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    this.imageUrl,
    this.postId,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final String? imageUrl;
  final String? postId;

  bool get hasPost => postId != null && postId!.isNotEmpty;
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.slide, required this.active});

  final _CarouselSlide slide;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: _softSurfaceShadow(
          opacity: active ? 0.18 : 0.10,
          blurRadius: active ? 30 : 20,
          dy: active ? 16 : 10,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (slide.imageUrl != null && slide.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: slide.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) =>
                    _gradientFallback(),
              )
            else
              _gradientFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    slide.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Icon(slide.icon, size: 24, color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      height: 1.06,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kBrandTeal,
            const Color(0xFF83C5BE),
            const Color(0xFFE9C46A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          slide.icon,
          size: 72,
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}
