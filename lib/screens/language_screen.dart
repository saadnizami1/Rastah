import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageScreen extends StatelessWidget {
  final VoidCallback? onNext;
  
  const LanguageScreen({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
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
          // Glass overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _glassDecoration(),
                    child: Column(
                      children: [
                        Icon(
                          Icons.language,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'زبان کی سہولت',
                          style: GoogleFonts.notoNaskhArabic(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Language Support',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Input options
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _glassDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.greenAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'آپ کیسے لکھ سکتے ہیں',
                              style: GoogleFonts.notoNaskhArabic(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildInputOption(
                          icon: Icons.text_fields,
                          title: 'اردو میں',
                          subtitle: 'Pure Urdu',
                          example: 'میں آج بہت پریشان ہوں',
                          color: Colors.greenAccent,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildInputOption(
                          icon: Icons.abc,
                          title: 'انگریزی میں',
                          subtitle: 'English',
                          example: 'I am feeling very worried today',
                          color: Colors.blueAccent,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildInputOption(
                          icon: Icons.keyboard,
                          title: 'رومن اردو میں',
                          subtitle: 'Roman Urdu',
                          example: 'Main aaj bohat pareshan hun',
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Output explanation
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _glassDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'میں کیسے جواب دوں گا',
                              style: GoogleFonts.notoNaskhArabic(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.record_voice_over,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ہمیشہ اردو میں',
                                style: GoogleFonts.notoNaskhArabic(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Always in Urdu',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'آپ جس بھی زبان میں لکھیں، میں ہمیشہ اردو میں جواب دوں گا کیونکہ یہ ماڈل خاص طور پر اردو کے لیے تیار کیا گیا ہے۔',
                          style: GoogleFonts.notoNaskhArabic(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Whatever language you write in, I will always respond in Urdu as this model is specifically designed for Urdu.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Benefits
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _glassDecoration(),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star_outline,
                          color: Colors.yellowAccent,
                          size: 32,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'فائدے',
                          style: GoogleFonts.notoNaskhArabic(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildBenefit('آپ کو جیسے بھی آسان لگے، اسی طرح لکھ سکتے ہیں'),
                        _buildBenefit('اردو میں بہترین اور گہری گفتگو'),
                        _buildBenefit('آپ کی ثقافت اور زبان کا احترام'),
                      ],
                    ),
                  ),
                  
                  // Extra space for bottom button
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Glass navigation button (bottom right)
          Positioned(
            bottom: 30,
            right: 30,
            child: SafeArea(
              child: GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _glassDecoration().copyWith(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'آگے بڑھیں',
                        style: GoogleFonts.notoNaskhArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _glassDecoration({double opacity = 0.15}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildInputOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String example,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  example,
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 14,
                    color: color.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.greenAccent,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoNaskhArabic(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}