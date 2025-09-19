import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../app_state_manager.dart';
import '../utils/theme.dart';
import '../utils/localization.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _canAccept = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _animationController.forward();
    
    // Allow acceptance after 3 seconds or when scrolled to bottom
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _canAccept = true;
        });
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 50) {
        if (!_hasScrolledToBottom) {
          setState(() {
            _hasScrolledToBottom = true;
            _canAccept = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _acceptPrivacyPolicy() {
    if (_canAccept) {
      context.go('/onboarding');
    }
  }

  void _goBack() {
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          final isUrdu = appState.currentLanguage == 'ur';
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _goBack,
                            icon: Icon(
                              isUrdu ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.translate('privacy_title', appState.currentLanguage),
                              style: isUrdu 
                                  ? AppTheme.urduHeading.copyWith(fontSize: 20)
                                  : AppTheme.lightTheme.textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Privacy Icon
                            Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.security_rounded,
                                  size: 40,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Main Privacy Statement
                            _buildSection(
                              title: isUrdu ? 'آپ کی رازداری ہماری ترجیح ہے' : 'Your Privacy is Our Priority',
                              content: isUrdu 
                                  ? 'رستہ ایپ آپ کی رازداری کا مکمل احترام کرتا ہے۔ آپ کا ذاتی ڈیٹا محفوظ ہے اور صرف آپ کے تعلیمی تجربے کو بہتر بنانے کے لیے استعمال ہوتا ہے۔'
                                  : 'Rasta app respects your privacy completely. Your personal data is secure and is only used to improve your educational experience.',
                              isUrdu: isUrdu,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Data Collection
                            _buildSection(
                              title: isUrdu ? 'کیا ڈیٹا جمع کیا جاتا ہے؟' : 'What Data Do We Collect?',
                              content: isUrdu 
                                  ? '• آپ کا نام، عمر، اور صوبہ\n• آپ کے مطالعہ کے مضامین\n• مطالعہ کی پیش قدمی اور شیڈول\n• AI ٹیوٹر کے ساتھ گفتگو (صرف 16 دن)'
                                  : '• Your name, age, and province\n• Your study subjects\n• Study progress and schedule\n• AI tutor conversations (only 16 days)',
                              isUrdu: isUrdu,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Data Storage
                            _buildSection(
                              title: isUrdu ? 'ڈیٹا کیسے محفوظ کیا جاتا ہے؟' : 'How is Data Stored?',
                              content: isUrdu 
                                  ? '• تمام ڈیٹا آپ کے ڈیوائس پر محفوظ ہوتا ہے\n• کوئی بھی معلومات کلاؤڈ پر نہیں بھیجی جاتی\n• 16 دن بعد پرانا ڈیٹا خودکار طور پر ڈیلیٹ ہو جاتا ہے\n• آپ کسی بھی وقت تمام ڈیٹا صاف کر سکتے ہیں'
                                  : '• All data is stored locally on your device\n• No information is sent to the cloud\n• Old data is automatically deleted after 16 days\n• You can clear all data at any time',
                              isUrdu: isUrdu,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Data Sharing
                            _buildSection(
                              title: isUrdu ? 'کیا ڈیٹا شیئر کیا جاتا ہے؟' : 'Is Data Shared?',
                              content: isUrdu 
                                  ? 'نہیں! آپ کا ڈیٹا کبھی بھی کسی تیسری پارٹی کے ساتھ شیئر نہیں کیا جاتا۔ AI ٹیوٹر کی خدمات کے لیے صرف آپ کے سوالات OpenAI کو بھیجے جاتے ہیں، کوئی ذاتی معلومات نہیں۔'
                                  : 'No! Your data is never shared with any third party. Only your questions are sent to OpenAI for AI tutor services, no personal information.',
                              isUrdu: isUrdu,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Permissions
                            _buildSection(
                              title: isUrdu ? 'ایپ کی اجازات' : 'App Permissions',
                              content: isUrdu 
                                  ? '• مائیکروفون: آواز میں سوال پوچھنے کے لیے\n• انٹرنیٹ: AI ٹیوٹر سے بات کرنے کے لیے\n• نوٹیفیکیشن: مطالعہ کی یاد دہانی کے لیے'
                                  : '• Microphone: For voice questions\n• Internet: For AI tutor communication\n• Notifications: For study reminders',
                              isUrdu: isUrdu,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Your Rights
                            _buildSection(
                              title: isUrdu ? 'آپ کے حقوق' : 'Your Rights',
                              content: isUrdu 
                                  ? '• کسی بھی وقت ڈیٹا ڈیلیٹ کر سکتے ہیں\n• AI ٹیوٹر استعمال کرنا اختیاری ہے\n• آواز کی اجازت دینا اختیاری ہے\n• ایپ انسٹال کے ساتھ تمام ڈیٹا ختم ہو جاتا ہے'
                                  : '• Delete data at any time\n• AI tutor usage is optional\n• Voice permission is optional\n• All data is removed when app is uninstalled',
                              isUrdu: isUrdu,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Contact Information
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.accentColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUrdu ? 'رابطہ' : 'Contact',
                                    style: isUrdu 
                                        ? AppTheme.urduBody.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.accentColor,
                                          )
                                        : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                            color: AppTheme.accentColor,
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isUrdu 
                                        ? 'اگر آپ کے پاس کوئی سوال ہے تو رابطہ کریں: support@rasta.app'
                                        : 'If you have any questions, contact us: support@rasta.app',
                                    style: isUrdu 
                                        ? AppTheme.urduBody.copyWith(
                                            fontSize: 14,
                                            color: AppTheme.textSecondary,
                                          )
                                        : AppTheme.lightTheme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Scroll indicator
                            if (!_hasScrolledToBottom && !_canAccept)
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppTheme.textTertiary,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isUrdu ? 'مکمل پڑھنے کے لیے نیچے سکرول کریں' : 'Scroll down to read completely',
                                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bottom Button
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        border: Border(
                          top: BorderSide(
                            color: AppTheme.borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _canAccept ? _acceptPrivacyPolicy : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canAccept 
                                ? AppTheme.accentColor 
                                : AppTheme.textTertiary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_canAccept) ...[
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                AppLocalizations.translate('privacy_accept', appState.currentLanguage),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isUrdu,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  height: 1.6,
                  color: AppTheme.textSecondary,
                )
              : AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: AppTheme.textSecondary,
                ),
        ),
      ],
    );
  }
}