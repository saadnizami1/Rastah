import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Import screens
import 'onboarding_pager.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(RastahApp());
}

class RastahApp extends StatelessWidget {
  RastahApp({super.key});

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
        path: '/onboarding',
        builder: (context, state) => const OnboardingPager(),
      ),
      
      // Returning user flow
      GoRoute(
        path: '/welcome-returning',
        builder: (context, state) => const ReturningUserWelcome(),
      ),
      
      // Chat screen
      GoRoute(
        path: '/chat',
        builder: (context, state) => ChatScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rastah - رستہ',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF7F3E9),
        textTheme: GoogleFonts.notoNaskhArabicTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          headlineSmall: GoogleFonts.amiri(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D5A5A),
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D5A5A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            textStyle: GoogleFonts.notoNaskhArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Splash Screen to determine navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final prefs = await SharedPreferences.getInstance();
    final isFirstTimeComplete = prefs.getBool('first_time_complete') ?? false;
    
    if (mounted) {
      if (isFirstTimeComplete) {
        context.go('/welcome-returning');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'رستہ',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
              SizedBox(height: 20),
              Text(
                'آپ کا AI تھراپسٹ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Returning User Welcome Screen
class ReturningUserWelcome extends StatefulWidget {
  const ReturningUserWelcome({super.key});

  @override
  State<ReturningUserWelcome> createState() => _ReturningUserWelcomeState();
}

class _ReturningUserWelcomeState extends State<ReturningUserWelcome> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _userName = 'دوست';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadUserName();
    _animationController.forward();
    
    // Auto-navigate to chat after welcome
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/chat');
      }
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? 'دوست';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'خوش آمدید واپس!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'آپ کا AI تھراپسٹ تیار ہے',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () => context.go('/chat'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        'شروع کریں',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}