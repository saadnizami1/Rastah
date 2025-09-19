import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app_state_manager.dart';
import '../../models/study_session.dart';
import '../../utils/theme.dart';
import '../../utils/localization.dart';
import '../../utils/time_helper.dart';
import '../../widgets/language_toggle.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  
  final TransformationController _transformationController = TransformationController();
  double _currentZoom = 1.0;
  final double _minZoom = 0.8;
  final double _maxZoom = 2.0;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() async {
    _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _contentController.forward();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    if (_currentZoom < _maxZoom) {
      setState(() {
        _currentZoom = (_currentZoom * 1.2).clamp(_minZoom, _maxZoom);
      });
      _transformationController.value = Matrix4.identity()..scale(_currentZoom);
    }
  }

  void _zoomOut() {
    if (_currentZoom > _minZoom) {
      setState(() {
        _currentZoom = (_currentZoom / 1.2).clamp(_minZoom, _maxZoom);
      });
      _transformationController.value = Matrix4.identity()..scale(_currentZoom);
    }
  }

  void _resetZoom() {
    setState(() {
      _currentZoom = 1.0;
    });
    _transformationController.value = Matrix4.identity();
  }

  void _startSession(String sessionId) {
    context.go('/timer/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          final isUrdu = appState.currentLanguage == 'ur';
          final weeklySchedule = appState.getWeeklySchedule();
          final currentSession = appState.getCurrentSession();
          final nextSession = appState.getNextSession();
          
          return SafeArea(
            child: Column(
              children: [
                // Header
                FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: _buildHeader(appState, isUrdu, currentSession, nextSession),
                ),
                
                // Main content
                Expanded(
                  child: SlideTransition(
                    position: _contentSlideAnimation,
                    child: Column(
                      children: [
                        // Zoom controls
                        _buildZoomControls(isUrdu),
                        
                        // Timetable
                        Expanded(
                          child: _buildZoomableTimetable(weeklySchedule, appState, isUrdu),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      
      // Floating action button for quick session start
      floatingActionButton: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          final currentSession = appState.getCurrentSession();
          if (currentSession == null) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () => _startSession(currentSession.id),
            backgroundColor: AppTheme.accentColor,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              appState.currentLanguage == 'ur' ? 'شروع کریں' : 'Start Now',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppStateManager appState, bool isUrdu, StudySession? currentSession, StudySession? nextSession) {
    final userName = appState.studentProfile?.name ?? (isUrdu ? 'طالب علم' : 'Student');
    final currentTime = TimeHelper.getCurrentTimeString();
    final currentDate = TimeHelper.getCurrentDateString();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor.withValues(alpha: 0.1),
            AppTheme.surfaceColor,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              // App name and greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? 'رستہ' : 'Rasta',
                      style: isUrdu 
                          ? AppTheme.urduHeading.copyWith(fontSize: 20)
                          : AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentColor,
                            ),
                    ),
                    Text(
                      isUrdu ? 'سلام $userName!' : 'Hello $userName!',
                      style: isUrdu 
                          ? AppTheme.urduBody.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            )
                          : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                    ),
                  ],
                ),
              ),
              
              // Language toggle and settings
              Row(
                children: [
                  LanguageToggle(size: 32, showLabels: false),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => context.go('/settings'),
                    icon: Icon(
                      Icons.settings_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Current time and session status
          Row(
            children: [
              // Time display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentTime,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Session status
              Expanded(
                child: _buildSessionStatus(currentSession, nextSession, isUrdu),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStatus(StudySession? currentSession, StudySession? nextSession, bool isUrdu) {
    if (currentSession != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isUrdu 
                    ? '${currentSession.subjectNameUrdu} کا وقت'
                    : '${currentSession.subjectName} time',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (nextSession != null) {
      final timeUntil = nextSession.timeUntilStart;
      final minutesUntil = timeUntil.inMinutes;
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.warningColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              size: 12,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                isUrdu 
                    ? '$minutesUntil منٹ میں ${nextSession.subjectNameUrdu}'
                    : '${nextSession.subjectName} in ${minutesUntil}m',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.textTertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isUrdu ? 'آج کوئی سیشن نہیں' : 'No sessions today',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textTertiary,
          ),
        ),
      );
    }
  }

  Widget _buildZoomControls(bool isUrdu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            AppLocalizations.translate('my_schedule', isUrdu ? 'ur' : 'en'),
            style: isUrdu 
                ? AppTheme.urduBody.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  )
                : AppTheme.lightTheme.textTheme.titleMedium,
          ),
          
          const Spacer(),
          
          // Zoom controls
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _currentZoom > _minZoom ? _zoomOut : null,
                  icon: Icon(
                    Icons.zoom_out,
                    size: 20,
                    color: _currentZoom > _minZoom 
                        ? AppTheme.textSecondary 
                        : AppTheme.textTertiary,
                  ),
                ),
                GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${(_currentZoom * 100).round()}%',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _currentZoom < _maxZoom ? _zoomIn : null,
                  icon: Icon(
                    Icons.zoom_in,
                    size: 20,
                    color: _currentZoom < _maxZoom 
                        ? AppTheme.textSecondary 
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomableTimetable(Map<String, List<StudySession>> weeklySchedule, AppStateManager appState, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: _minZoom,
          maxScale: _maxZoom,
          onInteractionUpdate: (details) {
            setState(() {
              _currentZoom = _transformationController.value.getMaxScaleOnAxis();
            });
          },
          child: _buildTimetableContent(weeklySchedule, appState, isUrdu),
        ),
      ),
    );
  }

  Widget _buildTimetableContent(Map<String, List<StudySession>> weeklySchedule, AppStateManager appState, bool isUrdu) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final daysUrdu = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
    final currentDay = TimeHelper.getDayOfWeek();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: days.map((day) {
          final dayIndex = days.indexOf(day);
          final dayUrdu = daysUrdu[dayIndex];
          final sessions = weeklySchedule[day] ?? [];
          final isToday = day == currentDay;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isToday 
                  ? AppTheme.accentColor.withValues(alpha: 0.05)
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday 
                    ? AppTheme.accentColor.withValues(alpha: 0.2)
                    : AppTheme.borderColor,
                width: isToday ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // Day header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isToday 
                        ? AppTheme.accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isUrdu ? 'آج' : 'Today',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        isUrdu ? dayUrdu : day,
                        style: isUrdu 
                            ? AppTheme.urduBody.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isToday ? AppTheme.accentColor : AppTheme.primaryColor,
                              )
                            : AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isToday ? AppTheme.accentColor : AppTheme.primaryColor,
                              ),
                      ),
                      const Spacer(),
                      Text(
                        '${sessions.where((s) => s.type == SessionType.study).length} ${isUrdu ? 'سیشنز' : 'sessions'}',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Sessions list
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isUrdu ? 'آج کوئی سیشن نہیں' : 'No sessions today',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  )
                else
                  ...sessions.map((session) => _buildSessionCard(session, appState, isUrdu)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionCard(StudySession session, AppStateManager appState, bool isUrdu) {
    final isCurrentSession = session.isCurrentSession;
    final canStart = session.isCurrentSession || 
                     (session.timeUntilStart.inMinutes <= 5 && session.timeUntilStart.inMinutes >= 0);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canStart ? () => _startSession(session.id) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentSession 
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: isCurrentSession 
                  ? Border.all(color: AppTheme.successColor.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                // Session type indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSessionColor(session),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Session details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getSessionIcon(session),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isUrdu ? session.subjectNameUrdu : session.subjectName,
                              style: isUrdu 
                                  ? AppTheme.urduBody.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    )
                                  : AppTheme.lightTheme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            session.timeDisplayString,
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${session.plannedDuration}m',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: _getSessionColor(session),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action button
                if (canStart)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentSession 
                          ? AppTheme.successColor 
                          : AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else if (session.isCompleted)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppTheme.successColor,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSessionColor(StudySession session) {
    switch (session.type) {
      case SessionType.study:
        return AppTheme.accentColor;
      case SessionType.breakTime:
        return AppTheme.warningColor;
      case SessionType.prayer:
        return AppTheme.successColor;
      case SessionType.meal:
        return Color(0xFFFF6B35);
      case SessionType.sports:
        return Color(0xFF8B5CF6);
      default:
        return AppTheme.textTertiary;
    }
  }

  String _getSessionIcon(StudySession session) {
    switch (session.type) {
      case SessionType.study:
        return session.subjectIcon;
      case SessionType.breakTime:
        return '☕';
      case SessionType.prayer:
        return '🕌';
      case SessionType.meal:
        return '🍽️';
      case SessionType.sports:
        return '⚽';
      default:
        return '📅';
    }
  }
}