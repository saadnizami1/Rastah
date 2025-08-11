import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scrollController = ScrollController();

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >
              notification.metrics.maxScrollExtent * 0.8) {
            // Navigate when scrolled near bottom
            context.go('/language');
          }
          return true;
        },
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/welcome.png',
                fit: BoxFit.cover,
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Urdu brand name
                    Text(
                      'رستہ',
                      style: GoogleFonts.amiri(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D5A5A),
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.15),
                            offset: const Offset(2, 2),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // English brand name
                    Text(
                      'RASTAH',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D5A5A),
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Tagline in glass card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2D5A5A).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'آپ کا ہمسفر، سننے اور سمجھنے کے لیے',
                            textStyle: GoogleFonts.notoNaskhArabic(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2D5A5A),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            speed: const Duration(milliseconds: 90),
                          ),
                        ],
                        totalRepeatCount: 1,
                        pause: const Duration(milliseconds: 2000),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Hero image
                    SizedBox(
                      height: size.height * 0.35,
                      child: Image.asset(
                        'assets/images/welcome_img.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // About Rastah moved up
                    TextButton(
                      onPressed: () => _showAboutDialog(context),
                      child: Text(
                        'About Rastah',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF2D5A5A),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height), // extra space to scroll
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'About Rastah',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D5A5A),
            ),
          ),
          content: Text(
            'Rastah is your trusted AI companion designed specifically for Pakistani students. We provide confidential, culturally sensitive mental health support using evidence based approaches.\n\nYour conversations are private and never shared.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D5A5A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
