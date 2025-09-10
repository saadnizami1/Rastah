import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';  // 🔧 NEW: Added Provider import
import 'dart:async';

// Import screens
import 'onboarding_pager.dart';
import 'screens/chat_screen.dart';
import 'chat_state_manager.dart';  // 🔧 NEW: Added ChatStateManager import

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
    // 🔧 NEW: Wrapped MaterialApp.router with ChangeNotifierProvider
    return ChangeNotifierProvider(
      create: (context) => ChatStateManager(),
      child: MaterialApp.router(
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

  // 🔧 UPDATED: Enhanced route determination with personalization data check
  Future<void> _determineInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check completion flag
      final isFirstTimeComplete = prefs.getBool('first_time_complete') ?? false;
      
      // 🔧 NEW: Check for actual personalization data
      final hasName = (prefs.getString('name')?.isNotEmpty == true) || 
                     (prefs.getString('user_name')?.isNotEmpty == true);
      final hasAge = prefs.getInt('age') != null || prefs.getInt('user_age') != null;
      final hasBasicPersonalization = hasName && hasAge;
      
      // 🔧 NEW: Check for any personalization data at all
      final hasAnyPersonalizationData = hasName || hasAge || 
                                       prefs.getString('gender') != null ||
                                       prefs.getString('student_type') != null ||
                                       prefs.getString('city') != null;
      
      if (mounted) {
        // Route determination logic
        if (isFirstTimeComplete && hasBasicPersonalization) {
          // User completed onboarding and has personalization data
          context.go('/welcome-returning');
        } else if (isFirstTimeComplete && hasAnyPersonalizationData) {
          // User has some data but not complete - go to chat directly
          context.go('/chat');
        } else if (hasAnyPersonalizationData) {
          // User has some personalization data but didn't mark complete - go to chat
          context.go('/chat');
        } else {
          // First time user or no personalization data
          context.go('/onboarding');
        }
      }
    } catch (e) {
      // Fallback to onboarding on error
      if (mounted) {
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: const Column(
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'آپ کا AI تھراپسٹ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🔧 ENHANCED: Returning User Welcome Screen with full personalization
class ReturningUserWelcome extends StatefulWidget {
  const ReturningUserWelcome({super.key});

  @override
  State<ReturningUserWelcome> createState() => _ReturningUserWelcomeState();
}

class _ReturningUserWelcomeState extends State<ReturningUserWelcome> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // 🔧 NEW: Enhanced user data
  String _userName = 'دوست';
  String _userCity = '';
  String _currentMood = '😐';
  int _userAge = 0;
  String _occupation = '';
  String _personalizedGreeting = '';
  bool _isLoading = true;

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

    _loadUserData();
    _animationController.forward();
    
    // Auto-navigate to chat after welcome
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/chat');
      }
    });
  }

  // 🔧 UPDATED: Load comprehensive user data
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user data
      final name = prefs.getString('name') ?? prefs.getString('user_name') ?? 'دوست';
      final city = prefs.getString('city') ?? prefs.getString('user_city') ?? '';
      final mood = prefs.getString('current_mood') ?? '😐';
      final age = prefs.getInt('age') ?? prefs.getInt('user_age') ?? 0;
      final occupation = prefs.getString('student_type') ?? prefs.getString('user_occupation') ?? '';
      final preferredTime = prefs.getString('preferred_time') ?? '';
      
      // Create personalized greeting
      final greeting = _createPersonalizedGreeting(name, city, occupation, preferredTime, age);
      
      setState(() {
        _userName = name;
        _userCity = city;
        _currentMood = mood;
        _userAge = age;
        _occupation = occupation;
        _personalizedGreeting = greeting;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _personalizedGreeting = 'خوش آمدید واپس! آپ کا AI تھراپسٹ تیار ہے۔';
        _isLoading = false;
      });
    }
  }

  // 🔧 NEW: Create personalized greeting based on user data and time
  String _createPersonalizedGreeting(String name, String city, String occupation, String preferredTime, int age) {
    final currentHour = DateTime.now().hour;
    String timeGreeting = '';
    String contextualMessage = '';
    
    // Time-based greeting
    if (currentHour >= 5 && currentHour < 12) {
      timeGreeting = 'صبح بخیر';
    } else if (currentHour >= 12 && currentHour < 17) {
      timeGreeting = 'دوپہر مبارک';
    } else if (currentHour >= 17 && currentHour < 21) {
      timeGreeting = 'شام مبارک';
    } else {
      timeGreeting = 'رات کی مبارکباد';
    }
    
    // Contextual message based on user data
    if (occupation.isNotEmpty) {
      if (occupation == 'طالب علم' || occupation == 'Student') {
        contextualMessage = ' آج کی پڑھائی کیسی چل رہی ہے؟';
      } else if (occupation == 'ملازم' || occupation == 'Employee') {
        contextualMessage = ' آج کا کام کیسا چل رہا ہے؟';
      } else {
        contextualMessage = ' آج کا دن کیسا گزر رہا ہے؟';
      }
    } else {
      contextualMessage = ' آج کیسا محسوس کر رہے ہیں؟';
    }
    
    // Build complete greeting
    String fullGreeting = '$timeGreeting، $name!';
    if (city.isNotEmpty && city != 'اور') {
      fullGreeting += ' $city سے';
    }
    fullGreeting += contextualMessage;
    
    return fullGreeting;
  }

  // 🔧 NEW: Get appropriate mood emoji based on time and data
  String _getContextualMood() {
    final currentHour = DateTime.now().hour;
    
    // Return user's current mood if available
    if (_currentMood.isNotEmpty && _currentMood != '😐') {
      return _currentMood;
    }
    
    // Default mood based on time
    if (currentHour >= 6 && currentHour < 10) {
      return '☀️'; // Morning sunshine
    } else if (currentHour >= 18 && currentHour < 22) {
      return '🌅'; // Evening
    } else {
      return '😊'; // Default happy
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
              child: _isLoading 
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔧 NEW: Contextual mood emoji
                      Text(
                        _getContextualMood(),
                        style: const TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 20),
                      
                      // Welcome back message
                      const Text(
                        'خوش آمدید واپس!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // User name with highlight
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // 🔧 NEW: Personalized greeting
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 60,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          _personalizedGreeting,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // 🔧 NEW: User info chips (if available)
                      if (_userCity.isNotEmpty || _occupation.isNotEmpty || _userAge > 0)
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 60,
                          ),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (_userCity.isNotEmpty && _userCity != 'اور')
                                _buildInfoChip('📍 $_userCity'),
                              if (_occupation.isNotEmpty)
                                _buildInfoChip('💼 $_occupation'),
                              if (_userAge > 0)
                                _buildInfoChip('🎂 $_userAge سال'),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 30),
                      
                      // Start button
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
                            'بات شروع کریں',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Skip to chat option
                      TextButton(
                        onPressed: () => context.go('/chat'),
                        child: const Text(
                          'فوری طور پر چیٹ پر جائیں',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
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

  // 🔧 NEW: Helper method to build info chips
  Widget _buildInfoChip(String text) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}