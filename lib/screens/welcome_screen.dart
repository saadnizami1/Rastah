import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../app_state_manager.dart';
import '../utils/theme.dart';
import '../utils/localization.dart';
import '../widgets/language_toggle.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> 
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _buttonsController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _buttonsSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _buttonsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOutCubic,
    ));

    _buttonsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() async {
    await _mainController.forward();
    if (mounted) {
      _buttonsController.forward();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  void _navigateToPrivacy() {
    context.go('/privacy');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          final isUrdu = appState.currentLanguage == 'ur';
          
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Language Toggle
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: LanguageToggle(),
                    ),
                  ),
                  
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Main Content
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                // Hero Image/Icon
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.accentColor,
                                        AppTheme.accentColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_stories_rounded,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                                
                                const SizedBox(height: 48),
                                
                                // Welcome Title
                                Text(
                                  AppLocalizations.translate('welcome_title', appState.currentLanguage),
                                  style: isUrdu 
                                      ? AppTheme.urduHeading.copyWith(fontSize: 32)
                                      : AppTheme.lightTheme.textTheme.displayLarge,
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Subtitle
                                Text(
                                  AppLocalizations.translate('welcome_subtitle', appState.currentLanguage),
                                  style: isUrdu 
                                      ? AppTheme.urduBody.copyWith(
                                          fontSize: 18,
                                          color: AppTheme.textSecondary,
                                        )
                                      : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 18,
                                        ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Description
                                Text(
                                  AppLocalizations.translate('welcome_description', appState.currentLanguage),
                                  style: isUrdu 
                                      ? AppTheme.urduBody.copyWith(
                                          color: AppTheme.textTertiary,
                                          height: 1.6,
                                        )
                                      : AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.textTertiary,
                                          height: 1.6,
                                        ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Animated Buttons
                        SlideTransition(
                          position: _buttonsSlideAnimation,
                          child: FadeTransition(
                            opacity: _buttonsFadeAnimation,
                            child: Column(
                              children: [
                                // Get Started Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _navigateToPrivacy,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.translate('get_started', appState.currentLanguage),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Features Preview
                                _buildFeaturesList(appState.currentLanguage),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Footer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      isUrdu 
                          ? 'پاکستانی طلباء کے لیے خصوصی طور پر ڈیزائن کیا گیا'
                          : 'Specially designed for Pakistani students',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturesList(String language) {
    final features = language == 'ur' 
        ? [
            '🎯 ذہین مطالعہ شیڈول',
            '⏰ پومودورو ٹائمر',
            '🤖 AI ٹیوٹر مدد',
            '📊 پیش قدمی ٹریکنگ',
          ]
        : [
            '🎯 Smart Study Schedules',
            '⏰ Pomodoro Timer',
            '🤖 AI Tutor Help',
            '📊 Progress Tracking',
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: features.map((feature) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(
                feature.split(' ')[0], // Emoji
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature.substring(feature.indexOf(' ') + 1),
                  style: language == 'ur'
                      ? AppTheme.urduBody.copyWith(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        )
                      : AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}