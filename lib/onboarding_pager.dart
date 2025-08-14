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

class _OnboardingPagerState extends State<OnboardingPager> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isTransitioning = false; // Prevent multiple rapid taps
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Haptic feedback for better UX
    HapticFeedback.lightImpact();
  }

  // Navigation methods to pass to child screens
  void _goToNextPage() async {
    if (_currentIndex < _getScreens().length - 1 && !_isTransitioning) {
      setState(() {
        _isTransitioning = true;
      });
      
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
      
      // Small delay to ensure smooth completion
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (mounted) {
        setState(() {
          _isTransitioning = false;
        });
      }
    }
  }

  void _goToPreviousPage() async {
    if (_currentIndex > 0 && !_isTransitioning) {
      setState(() {
        _isTransitioning = true;
      });
      
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
      
      // Small delay to ensure smooth completion
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (mounted) {
        setState(() {
          _isTransitioning = false;
        });
      }
    }
  }

  // Get screens with navigation callbacks
  List<Widget> _getScreens() {
    return [
      WelcomeScreen(onNext: _goToNextPage),
      LanguageScreen(onNext: _goToNextPage),
      ConsentScreen(onNext: _goToNextPage),
      PersonalizationScreen(onNext: _goToNextPage),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content with ultra-smooth transitions
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: screens.length,
            pageSnapping: true, // Ensures clean snapping
            allowImplicitScrolling: false, // Prevents preloading conflicts
            itemBuilder: (context, index) {
              return RepaintBoundary( // Isolate repaints for better performance
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: screens[index],
                ),
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
                      screens.length,
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
                          '${_currentIndex + 1}/${screens.length}',
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
          
          // Back button (top left)
          if (_currentIndex > 0)
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 0.8,
                  child: GestureDetector(
                    onTap: _goToPreviousPage,
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
      default:
        return 'Step ${index + 1}';
    }
  }
}