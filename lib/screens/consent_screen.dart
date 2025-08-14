import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _hasReadTerms = false;
  bool _agreesToPrivacy = false;
  bool _understandsLimitations = false;

  bool get _canProceed =>
      _hasReadTerms && _agreesToPrivacy && _understandsLimitations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full background image
          Positioned.fill(
            child: Image.asset(
              "assets/images/welcome.png",
              fit: BoxFit.cover,
            ),
          ),
          // Subtle overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Urdu only notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _glassDecoration(),
                    child: Text(
                      "یہ ماڈل صرف اردو میں بات چیت کر سکتا ہے کیونکہ یہ خاص طور پر اردو کے لیے تیار کیا گیا ہے۔",
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Header section
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: _glassDecoration(),
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 50,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'آپ کی رضامندی اور محفوظیت',
                          style: GoogleFonts.notoNaskhArabic(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Consent & Privacy',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Info cards
                  _buildInfoCard(
                    icon: Icons.lock_person_outlined,
                    title: 'آپ کی پرائیویسی',
                    titleEng: 'Your Privacy',
                    content:
                        'آپ کی تمام باتیں صرف آپ کے فون میں محفوظ رہیں گی۔ کوئی بھی ڈیٹا انٹرنیٹ پر نہیں بھیجا جاتا۔ نہ کوئی اکاؤنٹ، نہ کوئی ٹریکنگ۔',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.psychology_outlined,
                    title: 'سپورٹ کی نوعیت',
                    titleEng: 'Nature of Support',
                    content:
                        'یہ AI جذباتی سپورٹ فراہم کرتا ہے لیکن کسی ڈاکٹر یا پروفیشنل تھراپسٹ کا متبادل نہیں۔ سنگین حالات میں پروفیشنل مدد لیں۔',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'رضاکارانہ شرکت',
                    titleEng: 'Voluntary Participation',
                    content:
                        'آپ کسی بھی وقت بات چیت روک سکتے ہیں۔ یہ مکمل طور پر رضاکارانہ ہے اور آپ کا اختیار ہے۔',
                  ),

                  const SizedBox(height: 25),

                  // Consent checkboxes
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _glassDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'براہ کرم تصدیق کریں:',
                          style: GoogleFonts.notoNaskhArabic(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCheckboxTile(
                          value: _hasReadTerms,
                          onChanged: (v) =>
                              setState(() => _hasReadTerms = v ?? false),
                          title: 'میں نے تمام شرائط پڑھ لی ہیں',
                          subtitle: 'I have read all the terms',
                        ),
                        _buildCheckboxTile(
                          value: _agreesToPrivacy,
                          onChanged: (v) =>
                              setState(() => _agreesToPrivacy = v ?? false),
                          title: 'میں پرائیویسی کی پالیسی سے اتفاق کرتا ہوں',
                          subtitle: 'I agree to the privacy policy',
                        ),
                        _buildCheckboxTile(
                          value: _understandsLimitations,
                          onChanged: (v) => setState(
                              () => _understandsLimitations = v ?? false),
                          title: 'میں سمجھتا ہوں یہ طبی مشورہ نہیں ہے',
                          subtitle: 'I understand this is not medical advice',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Encouragement text if all checked
                  if (_canProceed)
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'بہت اچھا! اب آپ آگے بڑھ سکتے ہیں ',
                          textStyle: GoogleFonts.notoNaskhArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.greenAccent,
                          ),
                          speed: const Duration(milliseconds: 80),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),

                  const SizedBox(height: 30),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _canProceed ? () => context.go('/personalization') : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canProceed
                            ? Colors.greenAccent.withOpacity(0.8)
                            : Colors.grey.shade500.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _canProceed
                            ? 'رضامندی، آگے بڑھیں'
                            : 'پہلے تصدیق کریں',
                        style: GoogleFonts.notoNaskhArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Emergency contact info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _glassDecoration().copyWith(
                      color: Colors.red.withOpacity(0.25),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emergency_outlined,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ہنگامی صورتحال میں: 1122 یا قریبی ہسپتال سے رابطہ کریں',
                            style: GoogleFonts.notoNaskhArabic(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Glass effect decoration
  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.15),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String titleEng,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      titleEng,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.notoNaskhArabic(
              fontSize: 15,
              color: Colors.white,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: value ? Colors.greenAccent : Colors.white70,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
                color: value
                    ? Colors.greenAccent.withOpacity(0.8)
                    : Colors.transparent,
              ),
              child: value
                  ? Icon(Icons.check, size: 16, color: Colors.black87)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoNaskhArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
