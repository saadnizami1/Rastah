import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/language_screen.dart';
import 'screens/consent_screen.dart';

/// Custom physics to allow a smaller drag distance to trigger a page change.
/// thresholdFraction: how much of the page must be dragged to trigger a change (0.15 = 15%).
class FastPageScrollPhysics extends PageScrollPhysics {
  final double thresholdFraction;

  const FastPageScrollPhysics({this.thresholdFraction = 0.15, ScrollPhysics? parent})
      : super(parent: parent);

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(
      thresholdFraction: thresholdFraction,
      parent: buildParent(ancestor),
    );
  }

  @override
  double getTargetPixels(ScrollMetrics position, double velocity) {
    // current page as a fractional value
    final double page = position.pixels / position.viewportDimension;
    double targetPage;

    // If user flings fast enough, honor the velocity
    const double velocityThreshold = 400.0; // px/sec, tweak if needed
    if (velocity.abs() >= velocityThreshold) {
      targetPage = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();
    } else {
      // Otherwise use a low threshold (e.g., 15% drag)
      final double pageFloor = page.floorToDouble();
      final double frac = page - pageFloor;
      if (frac > thresholdFraction) {
        targetPage = page.ceilToDouble();
      } else {
        targetPage = pageFloor;
      }
    }

    return targetPage * position.viewportDimension;
  }
}

class OnboardingPager extends StatefulWidget {
  const OnboardingPager({super.key});

  @override
  State<OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<OnboardingPager> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _arrowController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  int _pageCount = 3; // update if you add/remove pages
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.25)).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    _pageController.addListener(() {
      final page = (_pageController.page ?? 0).round();
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 540), curve: Curves.easeOutCubic);
    } else {
      // last page action, or you can route with GoRouter here
    }
  }

  @override
  Widget build(BuildContext context) {
    // Put the actual page widgets you already have here (preferably without Scaffold)
    final pages = <Widget>[
      // Make sure WelcomeScreen returns just the page content (no Scaffold) or
      // create a wrapper that extracts the body.
      const WelcomeScreen(),
      const LanguageScreen(),
      const ConsentScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const FastPageScrollPhysics(
              thresholdFraction: 0.15,
              parent: BouncingScrollPhysics(),
            ),
            children: pages,
          ),

          // Bouncy scroll indicator (hidden on last page)
          if (_currentPage < pages.length - 1)
            Positioned(
              bottom: 18 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _goToNextPage,
                  behavior: HitTestBehavior.translucent,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 34,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.95)
                              : Colors.black.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
