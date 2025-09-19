import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state_manager.dart';
import '../../models/subject.dart';
import '../../utils/theme.dart';
import '../../utils/localization.dart';

class PreferencesScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic> userData;

  const PreferencesScreen({
    super.key,
    required this.onDataChanged,
    required this.userData,
  });

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _weakestSubject = '';
  int _dailyStudyHours = 3;
  Map<String, String> _subjectDifficulty = {};
  Map<String, int> _subjectPreferences = {};
  List<Subject> _userSubjects = [];
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadExistingData();
    _loadUserSubjects();
    _animationController.forward();
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
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _loadExistingData() {
    _weakestSubject = widget.userData['weakestSubject'] ?? '';
    _dailyStudyHours = widget.userData['dailyStudyHours'] ?? 3;
    _subjectDifficulty = Map<String, String>.from(widget.userData['subjectDifficulty'] ?? {});
    _subjectPreferences = Map<String, int>.from(widget.userData['subjectPreferences'] ?? {});
  }

  void _loadUserSubjects() {
    final selectedSubjectIds = List<String>.from(widget.userData['subjects'] ?? []);
    final allSubjects = Subject.getDefaultSubjects();
    
    setState(() {
      _userSubjects = allSubjects
          .where((subject) => selectedSubjectIds.contains(subject.id))
          .toList();
    });
    
    // Initialize default preferences
    _initializeDefaultPreferences();
  }

  void _initializeDefaultPreferences() {
    for (final subject in _userSubjects) {
      _subjectDifficulty[subject.id] ??= 'medium';
      _subjectPreferences[subject.id] ??= _getDefaultHoursForSubject(subject.id);
    }
    _updateData();
  }

  int _getDefaultHoursForSubject(String subjectId) {
    switch (subjectId) {
      case 'math':
      case 'physics':
      case 'chemistry':
        return 4; // STEM subjects get more time
      case 'english':
      case 'urdu':
        return 3;
      default:
        return 2;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateData() {
    // Recalculate subject preferences based on difficulty
    for (final subject in _userSubjects) {
      final difficulty = _subjectDifficulty[subject.id] ?? 'medium';
      final baseHours = _getDefaultHoursForSubject(subject.id);
      
      if (difficulty == 'weak') {
        _subjectPreferences[subject.id] = (baseHours * 1.5).round();
      } else if (difficulty == 'strong') {
        _subjectPreferences[subject.id] = (baseHours * 0.5).round().clamp(1, 10);
      } else {
        _subjectPreferences[subject.id] = baseHours;
      }
    }

    final data = {
      'weakestSubject': _weakestSubject,
      'dailyStudyHours': _dailyStudyHours,
      'subjectDifficulty': _subjectDifficulty,
      'subjectPreferences': _subjectPreferences,
    };
    widget.onDataChanged(data);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        final isUrdu = appState.currentLanguage == 'ur';
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildSectionHeader(
                      AppLocalizations.translate('study_preferences', appState.currentLanguage),
                      isUrdu,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Daily study hours
                    _buildStudyHoursSelector(appState.currentLanguage, isUrdu),
                    
                    const SizedBox(height: 32),
                    
                    // Weakest subject
                    _buildWeakestSubjectSelector(appState.currentLanguage, isUrdu),
                    
                    const SizedBox(height: 32),
                    
                    // Subject difficulty levels
                    _buildSubjectDifficultySection(appState.currentLanguage, isUrdu),
                    
                    const SizedBox(height: 32),
                    
                    // Study time preview
                    _buildStudyTimePreview(appState.currentLanguage, isUrdu),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '3/4',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: isUrdu 
              ? AppTheme.urduHeading.copyWith(fontSize: 24)
              : AppTheme.lightTheme.textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isUrdu 
              ? 'آپ کی ترجیحات ہمیں بہترین شیڈول بنانے میں مدد کریں گی'
              : 'Your preferences help us create the optimal schedule',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(color: AppTheme.textSecondary)
              : AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
        ),
      ],
    );
  }

  Widget _buildStudyHoursSelector(String language, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.translate('study_time_available', language),
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUrdu ? '1 گھنٹہ' : '1 hour',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    isUrdu ? '8 گھنٹے' : '8 hours',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.accentColor,
                  thumbColor: AppTheme.accentColor,
                  overlayColor: AppTheme.accentColor.withValues(alpha: 0.2),
                  valueIndicatorColor: AppTheme.accentColor,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Slider(
                  value: _dailyStudyHours.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: isUrdu 
                      ? '$_dailyStudyHours گھنٹے'
                      : '$_dailyStudyHours hours',
                  onChanged: (value) {
                    setState(() {
                      _dailyStudyHours = value.round();
                    });
                    _updateData();
                  },
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isUrdu 
                      ? 'روزانہ $_dailyStudyHours گھنٹے'
                      : '$_dailyStudyHours hours daily',
                  style: isUrdu 
                      ? AppTheme.urduBody.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentColor,
                        )
                      : AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.accentColor,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeakestSubjectSelector(String language, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.translate('weakest_subject', language),
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isUrdu 
              ? 'جس مضمون میں آپ کو سب سے زیادہ مدد چاہیے'
              : 'The subject you need the most help with',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                )
              : AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _userSubjects.length,
          itemBuilder: (context, index) {
            final subject = _userSubjects[index];
            final isSelected = subject.id == _weakestSubject;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _weakestSubject = subject.id;
                  _subjectDifficulty[subject.id] = 'weak';
                });
                _updateData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.warningColor
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.warningColor
                        : AppTheme.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subject.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUrdu ? subject.nameUrdu : subject.name,
                      style: isUrdu 
                          ? AppTheme.urduBody.copyWith(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 12,
                            )
                          : AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubjectDifficultySection(String language, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isUrdu ? 'باقی مضامین کی سطح' : 'Other Subjects Level',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isUrdu 
              ? 'ہر مضمون میں آپ کی مہارت کا درجہ بتائیں'
              : 'Rate your skill level in each subject',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                )
              : AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
        ),
        const SizedBox(height: 16),
        Column(
          children: _userSubjects
              .where((subject) => subject.id != _weakestSubject)
              .map((subject) => _buildSubjectDifficultyRow(subject, language, isUrdu))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSubjectDifficultyRow(Subject subject, String language, bool isUrdu) {
    final difficulty = _subjectDifficulty[subject.id] ?? 'medium';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                subject.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUrdu ? subject.nameUrdu : subject.name,
                  style: isUrdu 
                      ? AppTheme.urduBody.copyWith(
                          fontWeight: FontWeight.w600,
                        )
                      : AppTheme.lightTheme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDifficultyOption(
                'strong',
                isUrdu ? 'آسان' : 'Easy',
                AppTheme.successColor,
                difficulty == 'strong',
                (value) {
                  setState(() {
                    _subjectDifficulty[subject.id] = value;
                  });
                  _updateData();
                },
              ),
              const SizedBox(width: 8),
              _buildDifficultyOption(
                'medium',
                isUrdu ? 'متوسط' : 'Medium',
                AppTheme.accentColor,
                difficulty == 'medium',
                (value) {
                  setState(() {
                    _subjectDifficulty[subject.id] = value;
                  });
                  _updateData();
                },
              ),
              const SizedBox(width: 8),
              _buildDifficultyOption(
                'weak',
                isUrdu ? 'مشکل' : 'Hard',
                AppTheme.warningColor,
                difficulty == 'weak',
                (value) {
                  setState(() {
                    _subjectDifficulty[subject.id] = value;
                  });
                  _updateData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(
    String value,
    String label,
    Color color,
    bool isSelected,
    Function(String) onSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildStudyTimePreview(String language, bool isUrdu) {
    final totalWeeklyHours = _subjectPreferences.values.fold(0, (sum, hours) => sum + hours);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isUrdu ? 'ہفتہ وار مطالعہ کا وقت' : 'Weekly Study Time',
                style: isUrdu 
                    ? AppTheme.urduBody.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      )
                    : AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.accentColor,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isUrdu 
                ? 'کل: $totalWeeklyHours گھنٹے فی ہفتہ'
                : 'Total: $totalWeeklyHours hours per week',
            style: isUrdu 
                ? AppTheme.urduBody.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  )
                : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            isUrdu 
                ? 'روزانہ تقریباً ${(totalWeeklyHours / 7).toStringAsFixed(1)} گھنٹے'
                : 'About ${(totalWeeklyHours / 7).toStringAsFixed(1)} hours daily',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}