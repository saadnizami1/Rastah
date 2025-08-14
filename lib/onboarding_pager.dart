import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'screens/language_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/personalization_screen.dart';


class OnboardingPager extends StatefulWidget {
  const OnboardingPager({super.key});

  @override
  State<OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<OnboardingPager> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late AnimationController _progressAnimationController;
  late AnimationController _fadeAnimationController;
  
  final List<Widget> _screens = [
    const WelcomeScreen(),
    const LanguageScreen(),
    const ConsentScreen(),
    const PersonalizationScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Animation controllers for smooth transitions
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Haptic feedback for better UX
    HapticFeedback.lightImpact();
    
    // Animate progress
    _progressAnimationController.forward();
    
    // Fade animation for smooth transitions
    _fadeAnimationController.reset();
    _fadeAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content with vertical page view
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemCount: _screens.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _fadeAnimationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimationController,
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: _screens[index],
                    ),
                  );
                },
              );
            },
          ),
          
          // Enhanced progress indicator (right side)
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress dots with elegant design
                    ...List.generate(
                      _screens.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: _currentIndex == index ? 32 : 12,
                        width: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          boxShadow: _currentIndex == index
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Progress text
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 0.7,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          '${_currentIndex + 1}/${_screens.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Scroll hint indicator (bottom center)
          if (_currentIndex < _screens.length - 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _currentIndex == 0 ? 1.0 : 0.6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scroll instruction text
                        if (_currentIndex == 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Swipe up to continue',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        
                        // Animated scroll indicator
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1500),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, -10 * value),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: 1.0 - value,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_up,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            // Restart animation
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                setState(() {});
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Elegant screen transition overlay
          if (_currentIndex > 0)
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 0.8,
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Screen title overlay (top center)
          Positioned(
            top: 60,
            left: 20,
            right: 80,
            child: SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: 0.9,
                child: Row(
                  children: [
                    // Current screen indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getScreenTitle(_currentIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Welcome';
      case 1:
        return 'Language';
      case 2:
        return 'Privacy';
      case 3:
        return 'Profile';
      case 4:
        return 'Confirm';
      default:
        return 'Step ${index + 1}';
    }
  }
}