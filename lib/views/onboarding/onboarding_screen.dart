import 'package:flutter/material.dart';
import 'package:jirani/core/theme/resident_surface_tokens.dart';

/// Four-step onboarding before login (resident mobile). Calls [onFinished] for Skip / Get Started.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  /// Navigate away to login/register (parent marks prefs).
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      imageAsset: 'assets/Splash1.png',
      title: 'Connect with verified neighbors',
      subtitle: 'Interact within your residential community.',
      imageAspectRatio: 381 / 191,
    ),
    _OnboardingPage(
      imageAsset: 'assets/Splash2.png',
      title: 'Borrow and lend safely',
      subtitle:
          'Share household items, track status, and build community resource sharing.',
      imageAspectRatio: 362 / 204,
    ),
    _OnboardingPage(
      imageAsset: 'assets/Splash3.png',
      title: 'Home services made simple',
      subtitle: 'Find reliable neighbors providing everyday home tasks.',
      imageAspectRatio: 380 / 214,
    ),
    _OnboardingPage(
      imageAsset: 'assets/Splash4.png',
      title: 'Connect With People',
      subtitle: 'Meet trusted Neighbors, and Build Connections.',
      imageAspectRatio: 353 / 325,
    ),
  ];

  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_page >= _pages.length - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  return _OnboardingSlide(page: _pages[index]);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
              child: _BottomBar(
                pageIndex: _page,
                onSkip: widget.onFinished,
                onNext: _goNext,
                nextLabel: _page >= _pages.length - 1 ? 'Get Started' : 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.pageIndex,
    required this.onSkip,
    required this.onNext,
    required this.nextLabel,
  });

  final int pageIndex;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final String nextLabel;

  static const Color _brand = Color(0xFF006D77);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: _brand,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          child: const Text(
            'SKIP',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ),
        Expanded(
          child: Center(
            child: _FourSlotIndicator(activeIndex: pageIndex.clamp(0, 3)),
          ),
        ),
        SizedBox(
          width: 98,
          height: 44,
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              nextLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma Group 9–12: teal pill moves across four slots (pages 1–4).
class _FourSlotIndicator extends StatelessWidget {
  const _FourSlotIndicator({required this.activeIndex});

  final int activeIndex;

  static const Color _brand = Color(0xFF006D77);
  static const Color _inactiveDot = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    const pillW = 50.0;
    const pillH = 9.0;
    const dotSize = 9.0;
    const gap = 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final isPill = i == activeIndex;
        final w = isPill ? pillW : dotSize;
        final h = isPill ? pillH : dotSize;
        return Padding(
          padding: EdgeInsets.only(right: i < 3 ? gap : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: isPill ? _brand : _inactiveDot,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.imageAspectRatio,
  });

  final String imageAsset;
  final String title;
  final String subtitle;
  final double imageAspectRatio;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.page});

  final _OnboardingPage page;

  static const Color _brand = Color(0xFF006D77);

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width;
    final horizontal = (maxW * (16 / 402)).clamp(16.0, 28.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: constraints.maxHeight * 0.04),
                AspectRatio(
                  aspectRatio: page.imageAspectRatio,
                  child: Image.asset(
                    page.imageAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
                SizedBox(height: (maxW * (28 / 402)).clamp(20.0, 36.0)),
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.appInk,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _brand,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.06),
              ],
            ),
          ),
        );
      },
    );
  }
}
