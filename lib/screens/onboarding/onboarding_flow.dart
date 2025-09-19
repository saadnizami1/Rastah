import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app_state_manager.dart';
import '../../models/student_profile.dart';
import '../../utils/theme.dart';
import '../../utils/localization.dart';
import '../../widgets/language_toggle.dart';
import 'personal_info_screen.dart';
import 'academic_info_screen.dart';
import 'preferences_screen.dart';
import 'schedule_preview_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _currentPage = 0;
  final int _totalPages = 4;
  
  // User data collection
  Map<String, dynamic> _userData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _updateProgress();
  }

  void _updateProgress() {
    final progress = (_currentPage + 1) / _totalPages;
    _progressController.animateTo(progress);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateUserData(Map<String, dynamic> data) {
    setState(() {
      _userData.addAll(data);
    });
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create student profile
      final profile = StudentProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _userData['name'] ?? '',
        age: _userData['age'] ?? 15,
        gender: _userData['gender'] ?? '',
        province: _userData['province'] ?? '',
        classLevel: _userData['classLevel'] ?? '',
        subjects: List<String>.from(_userData['subjects'] ?? []),
        weakestSubject: _userData['weakestSubject'] ?? '',
        dailyStudyHours: _userData['dailyStudyHours'] ?? 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        subjectDifficulty: Map<String, String>.from(_userData['subjectDifficulty'] ?? {}),
        subjectPreferences: Map<String, int>.from(_userData['subjectPreferences'] ?? {}),
      );

      // Complete onboarding in app state
      final appState = Provider.of<AppStateManager>(context, listen: false);
      await appState.completeOnboarding(profile);

      // Navigate to main app
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          final isUrdu = appState.currentLanguage == 'ur';
          
          return SafeArea(
            child: Column(
              children: [
                // Header with progress
                _buildHeader(appState, isUrdu),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      _updateProgress();
                    },
                    children: [
                      PersonalInfoScreen(
                        onDataChanged: _updateUserData,
                        userData: _userData,
                      ),
                      AcademicInfoScreen(
                        onDataChanged: _updateUserData,
                        userData: _userData,
                      ),
                      PreferencesScreen(
                        onDataChanged: _updateUserData,
                        userData: _userData,
                      ),
                      SchedulePreviewScreen(
                        userData: _userData,
                        onComplete: _completeOnboarding,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
                
                // Navigation buttons
                if (_currentPage < _totalPages - 1)
                  _buildNavigationButtons(isUrdu),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppStateManager appState, bool isUrdu) {
    return Container(
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
      child: Column(
        children: [
          // Top row with back button and language toggle
          Row(
            children: [
              if (_currentPage > 0)
                IconButton(
                  onPressed: _previousPage,
                  icon: Icon(
                    isUrdu ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                    color: AppTheme.textSecondary,
                  ),
                )
              else
                IconButton(
                  onPressed: () => context.go('/privacy'),
                  icon: Icon(
                    isUrdu ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                    color: AppTheme.textSecondary,
                  ),
                ),
              
              const Spacer(),
              
              LanguageToggle(size: 36),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress indicator
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.translate('lets_get_to_know_you', appState.currentLanguage),
                      style: isUrdu 
                          ? AppTheme.urduHeading.copyWith(fontSize: 18)
                          : AppTheme.lightTheme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentPage + 1} / $_totalPages',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Circular progress
              SizedBox(
                width: 60,
                height: 60,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _progressAnimation.value,
                      strokeWidth: 4,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.accentColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Step indicators
          Row(
            children: List.generate(_totalPages, (index) {
              final isActive = index == _currentPage;
              final isCompleted = index < _currentPage;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _totalPages - 1 ? 8 : 0,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive 
                        ? AppTheme.accentColor 
                        : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isUrdu) {
    final canProceed = _canProceedToNextPage();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Skip button (only on first few pages)
          if (_currentPage < 2)
            TextButton(
              onPressed: () {
                // Skip to preferences with minimal data
                _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                AppLocalizations.translate('skip', _currentPage == 0 ? 'en' : 'ur'),
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            )
          else
            const SizedBox(width: 60),
          
          const Spacer(),
          
          // Next button
          SizedBox(
            width: 120,
            height: 48,
            child: ElevatedButton(
              onPressed: canProceed ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed 
                    ? AppTheme.accentColor 
                    : AppTheme.textTertiary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.translate('next', _currentPage == 0 ? 'en' : 'ur'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isUrdu ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextPage() {
    switch (_currentPage) {
      case 0: // Personal info
        return _userData['name']?.isNotEmpty == true &&
               _userData['age'] != null &&
               _userData['gender']?.isNotEmpty == true &&
               _userData['province']?.isNotEmpty == true;
      
      case 1: // Academic info
        return _userData['classLevel']?.isNotEmpty == true &&
               _userData['subjects']?.isNotEmpty == true;
      
      case 2: // Preferences
        return _userData['weakestSubject']?.isNotEmpty == true &&
               _userData['dailyStudyHours'] != null;
      
      case 3: // Preview
        return true;
      
      default:
        return false;
    }
  }
}