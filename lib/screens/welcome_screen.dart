import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onNext;
  const WelcomeScreen({super.key, this.onNext});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _showUrdu = true;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Fade in/out loop
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with glow + fade
                  FadeTransition(
                    opacity: Tween(begin: 0.3, end: 1.0).animate(_logoController),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 30 + (_logoController.value * 20),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/welcome_img.png',
                          width: size.width * 0.35,
                          height: size.width * 0.35,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'رستہ',
                    style: GoogleFonts.amiri(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Language toggle card
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showUrdu = !_showUrdu;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _showUrdu
                                ? 'خود تیار کردہ اور اُردو پر مکمل عبور رکھنے والا معالج — آپ کی بات سننے کو تیار۔'
                                : 'A custom-built therapist fluent in Urdu — ready to listen to you.',
                            style: _showUrdu
                                ? GoogleFonts.notoNaskhArabic(
                                    fontSize: 18,
                                    color: Colors.white,
                                    height: 1.5,
                                  )
                                : GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'تبدیل کرنے کے لیے ٹچ کریں • Tap to toggle',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Start button
                  ElevatedButton.icon(
                    onPressed: widget.onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: Text(
                      'شروع کریں',
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
