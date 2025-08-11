import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/language_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/personalization_screen.dart';
import 'screens/profile_confirmation_screen.dart';
import 'screens/chat_screen.dart';
import 'onboarding_pager.dart';

void main() {
  runApp(RastahApp());
}

class RastahApp extends StatelessWidget {
  RastahApp({super.key});

  // Navigation configuration for all 7 screens
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingPager(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/personalization',
        builder: (context, state) => const PersonalizationScreen(),
      ),
      GoRoute(
        path: '/profile-confirmation',
        builder: (context, state) => const ProfileConfirmationScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
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
        // Mughal-inspired color scheme
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF7F3E9), // Warm beige
        
        // Urdu font as default
        textTheme: GoogleFonts.notoNaskhArabicTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          // Override some fonts for English text
          headlineSmall: GoogleFonts.amiri(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D5A5A), // Deep teal
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D5A5A), // Deep teal
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