import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state_manager.dart';
import '../../models/student_profile.dart';
import '../../models/subject.dart';
import '../../models/timetable.dart';
import '../../utils/theme.dart';
import '../../utils/localization.dart';
import '../../utils/time_helper.dart';

class SchedulePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onComplete;
  final bool isLoading;

  const SchedulePreviewScreen({
    super.key,
    required this.userData,
    required this.onComplete,
    required this.isLoading,
  });

  @override
  State<SchedulePreviewScreen> createState() => _SchedulePreviewScreenState();
}

class _SchedulePreviewScreenState extends State<SchedulePreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timetable? _previewTimetable;
  bool _isGenerating = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generatePreviewTimetable();
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

  void _generatePreviewTimetable() async {
    setState(() {
      _isGenerating = true;
    });

    // Simulate generation time
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Create a temporary profile for preview
      final profile = StudentProfile(
        id: 'preview',
        name: widget.userData['name'] ?? 'Student',
        age: widget.userData['age'] ?? 15,
        gender: widget.userData['gender'] ?? '',
        province: widget.userData['province'] ?? '',
        classLevel: widget.userData['classLevel'] ?? '',
        subjects: List<String>.from(widget.userData['subjects'] ?? []),
        weakestSubject: widget.userData['weakestSubject'] ?? '',
        dailyStudyHours: widget.userData['dailyStudyHours'] ?? 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        subjectDifficulty: Map<String, String>.from(widget.userData['subjectDifficulty'] ?? {}),
        subjectPreferences: Map<String, int>.from(widget.userData['subjectPreferences'] ?? {}),
      );

      // Get subjects for the student's class
      final subjects = Subject.getSubjectsForClass(profile.classLevel);
      
      // Filter to only user's selected subjects
      final userSubjects = subjects.where((subject) => 
        profile.subjects.contains(subject.id)
      ).toList();

      // Update subjects with user preferences
      final updatedSubjects = userSubjects.map((subject) {
        final difficulty = profile.getSubjectDifficulty(subject.id);
        final weeklyHours = profile.getSubjectHours(subject.id);
        
        return subject.copyWith(
          difficulty: difficulty,
          weeklyHours: weeklyHours,
          sessionDuration: TimeHelper.getOptimalSessionLength(
            profile.age,
            subject.id,
            difficulty,
          ),
        );
      }).toList();

      // Generate the timetable
      final timetable = Timetable.generateTimetable(
        studentId: profile.id,
        profile: profile,
        subjects: updatedSubjects,
      );

      if (mounted) {
        setState(() {
          _previewTimetable = timetable;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildSectionHeader(
                    AppLocalizations.translate('schedule_preview', appState.currentLanguage),
                    isUrdu,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Content
                  Expanded(
                    child: _isGenerating
                        ? _buildGeneratingState(isUrdu)
                        : _previewTimetable != null
                            ? _buildSchedulePreview(appState.currentLanguage, isUrdu)
                            : _buildErrorState(isUrdu),
                  ),
                  
                  // Complete button
                  _buildCompleteButton(appState.currentLanguage, isUrdu),
                ],
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
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '4/4',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.successColor,
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
              ? 'آپ کے لیے خصوصی طور پر تیار کیا گیا شیڈول'
              : 'Your personalized study schedule',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(color: AppTheme.textSecondary)
              : AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
        ),
      ],
    );
  }

  Widget _buildGeneratingState(bool isUrdu) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading animation
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            isUrdu ? 'آپ کا شیڈول تیار کیا جا رہا ہے...' : 'Generating your schedule...',
            style: isUrdu 
                ? AppTheme.urduBody.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  )
                : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            isUrdu 
                ? 'AI آپ کی ضروریات کے مطابق بہترین شیڈول بنا رہا ہے'
                : 'AI is creating the optimal schedule based on your needs',
            style: isUrdu 
                ? AppTheme.urduBody.copyWith(color: AppTheme.textSecondary)
                : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePreview(String language, bool isUrdu) {
    final weeklySchedule = _previewTimetable!.getWeeklySchedule();
    final stats = _previewTimetable!.getCompletionStats();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics overview
          _buildStatsOverview(language, isUrdu),
          
          const SizedBox(height: 24),
          
          // Weekly schedule preview
          _buildWeeklyOverview(weeklySchedule, language, isUrdu),
          
          const SizedBox(height: 24),
          
          // Today's schedule detail
          _buildTodaySchedule(weeklySchedule, language, isUrdu),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(String language, bool isUrdu) {
    final totalHours = _previewTimetable!.totalWeeklyHours;
    final subjectCount = _previewTimetable!.getHoursBySubject().length;
    final sessionsPerDay = _previewTimetable!.sessions
        .where((s) => s.type.toString().contains('study'))
        .length / 7;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor.withValues(alpha: 0.1),
            AppTheme.successColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isUrdu ? 'شیڈول کی تفصیلات' : 'Schedule Overview',
                style: isUrdu 
                    ? AppTheme.urduBody.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      )
                    : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor,
                      ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  value: '${totalHours.toStringAsFixed(1)}h',
                  label: isUrdu ? 'ہفتہ وار' : 'Weekly',
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.book,
                  value: '$subjectCount',
                  label: isUrdu ? 'مضامین' : 'Subjects',
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.today,
                  value: '${sessionsPerDay.toStringAsFixed(1)}',
                  label: isUrdu ? 'روزانہ' : 'Daily',
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview(Map<String, List<dynamic>> weeklySchedule, String language, bool isUrdu) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final daysUrdu = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isUrdu ? 'ہفتہ وار جھلک' : 'Weekly Overview',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = days[index];
              final dayUrdu = daysUrdu[index];
              final sessions = weeklySchedule[day] ?? [];
              final studySessions = sessions.where((s) => 
                s.type.toString().contains('study')).length;
              
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isUrdu ? dayUrdu : day.substring(0, 3),
                      style: isUrdu 
                          ? AppTheme.urduBody.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            )
                          : AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: studySessions > 0 
                            ? AppTheme.accentColor 
                            : AppTheme.textTertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$studySessions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUrdu ? 'سیشنز' : 'sessions',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule(Map<String, List<dynamic>> weeklySchedule, String language, bool isUrdu) {
    final today = TimeHelper.getDayOfWeek();
    final todaySessions = weeklySchedule[today] ?? [];
    final studySessions = todaySessions.where((s) => 
      s.type.toString().contains('study')).take(4).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isUrdu ? 'آج کا شیڈول' : 'Today\'s Schedule',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        
        const SizedBox(height: 12),
        
        if (studySessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isUrdu ? 'آج کوئی مطالعہ سیشن نہیں ہے' : 'No study sessions today',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          )
        else
          Column(
            children: studySessions.map((session) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu ? session.subjectNameUrdu : session.subjectName,
                            style: isUrdu 
                                ? AppTheme.urduBody.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )
                                : AppTheme.lightTheme.textTheme.titleSmall,
                          ),
                          Text(
                            session.timeDisplayString,
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${session.plannedDuration}m',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildErrorState(bool isUrdu) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            isUrdu ? 'شیڈول بنانے میں خرابی' : 'Error generating schedule',
            style: isUrdu 
                ? AppTheme.urduBody.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                  )
                : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.errorColor,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            isUrdu ? 'دوبارہ کوشش کریں' : 'Please try again',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(String language, bool isUrdu) {
    final canComplete = !_isGenerating && _previewTimetable != null;
    
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canComplete && !widget.isLoading ? widget.onComplete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canComplete && !widget.isLoading
                    ? AppTheme.successColor 
                    : AppTheme.textTertiary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: widget.isLoading 
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isUrdu ? 'مطالعہ شروع کریں!' : 'Start Studying!',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            isUrdu 
                ? 'آپ بعد میں اپنا شیڈول تبدیل کر سکتے ہیں'
                : 'You can modify your schedule later',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}