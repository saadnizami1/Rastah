import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'app_state_manager.dart';
import 'utils/theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/main_app/timetable_screen.dart';
import 'screens/main_app/timer_screen.dart';
// Remove this line that's causing the error:
// import 'screens/main_app/settings_screen.dart';

void main() {
  runApp(RastaApp());
}

class RastaApp extends StatelessWidget {
  RastaApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash screen to determine user flow
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // First time user flow
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),
      
      // Main app
      GoRoute(
        path: '/main',
        builder: (context, state) => const TimetableScreen(),
      ),
      
      GoRoute(
        path: '/timer/:sessionId',
        builder: (context, state) => TimerScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      
      // Temporarily remove settings route
      // GoRoute(
      //   path: '/settings',
      //   builder: (context, state) => const SettingsScreen(),
      // ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateManager()..initialize(),
      child: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          return MaterialApp.router(
            title: 'Rasta - رستہ',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppTheme.lightTheme,
            builder: (context, child) {
              return Directionality(
                textDirection: appState.currentLanguage == 'ur' 
                    ? TextDirection.rtl 
                    : TextDirection.ltr,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

// Splash Screen - determines where to navigate
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAppState();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  void _checkAppState() async {
    // Wait for animations and app initialization
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final appState = Provider.of<AppStateManager>(context, listen: false);
    
    // Wait for app to initialize
    while (!appState.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    // Navigate based on app state
    if (appState.isOnboardingComplete && appState.canStartStudying) {
      context.go('/main');
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon/Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App Name in English
                    Text(
                      'Rasta',
                      style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // App Name in Urdu
                    Text(
                      'رستہ',
                      style: AppTheme.urduHeading.copyWith(
                        fontSize: 28,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tagline
                    Text(
                      'Your AI Study Companion',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'آپ کا AI مطالعہ ساتھی',
                      style: AppTheme.urduBody.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}