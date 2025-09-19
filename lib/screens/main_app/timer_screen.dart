import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app_state_manager.dart';
import '../../models/study_session.dart';
import '../../utils/theme.dart';
import '../../utils/localization.dart';
import '../../utils/time_helper.dart';
import '../components/floating_tutor.dart';
import 'dart:math' as math;

class TimerScreen extends StatefulWidget {
  final String sessionId;

  const TimerScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _floatingAnimation;
  
  bool _isTutorVisible = false;
  StudySession? _currentSession;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSession();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _backgroundAnimation = ColorTween(
      begin: AppTheme.backgroundColor,
      end: AppTheme.accentColor.withValues(alpha: 0.1),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _floatingAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.02),
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _timerController.forward();
    _pulseController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
    _backgroundController.repeat(reverse: true);
  }

  void _startSession() async {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    await appState.startSession(widget.sessionId);
    
    // Get the session details
    if (mounted) {
      setState(() {
        _currentSession = appState.activeSession;
      });
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _toggleTutor() {
    setState(() {
      _isTutorVisible = !_isTutorVisible;
    });
  }

  void _pauseSession() {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    appState.pauseSession();
  }

  void _resumeSession() {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    appState.resumeSession();
  }

  void _completeSession() async {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    await appState.completeSession();
    
    if (mounted) {
      // Show completion dialog
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    final isUrdu = appState.currentLanguage == 'ur';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: AppTheme.successColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isUrdu ? 'مبارک ہو!' : 'Congratulations!',
              style: isUrdu 
                  ? AppTheme.urduBody.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    )
                  : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.successColor,
                    ),
            ),
          ],
        ),
        content: Text(
          isUrdu 
              ? 'آپ نے کامیابی سے اپنا مطالعہ سیشن مکمل کیا ہے۔'
              : 'You have successfully completed your study session.',
          style: isUrdu 
              ? AppTheme.urduBody
              : AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/main');
            },
            child: Text(
              isUrdu ? 'واپس جائیں' : 'Back to Schedule',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          final isUrdu = appState.currentLanguage == 'ur';
          final timeRemaining = appState.sessionTimeRemaining;
          final isActive = appState.isSessionActive;
          final isPaused = appState.isSessionPaused;
          final session = appState.activeSession ?? _currentSession;
          
          if (session == null) {
            return _buildErrorState(isUrdu);
          }
          
          return AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _backgroundAnimation.value ?? AppTheme.backgroundColor,
                      AppTheme.backgroundColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Main timer content
                    _buildTimerContent(session, timeRemaining, isActive, isPaused, isUrdu),
                    
                    // Floating AI tutor
                    if (_isTutorVisible)
                      FloatingTutor(
                        onClose: () => setState(() => _isTutorVisible = false),
                        session: session,
                      ),
                    
                    // AI tutor button
                    _buildTutorButton(isUrdu),
                  ],
                ),
              );
            },
          );
        },
      ),
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
            isUrdu ? 'سیشن نہیں ملا' : 'Session not found',
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/main'),
            child: Text(
              isUrdu ? 'واپس جائیں' : 'Go Back',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerContent(StudySession session, Duration timeRemaining, bool isActive, bool isPaused, bool isUrdu) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            _buildHeader(session, isUrdu),
            
            const SizedBox(height: 40),
            
            // Timer circle
            Expanded(
              child: Center(
                child: _buildTimerCircle(session, timeRemaining, isActive, isPaused),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Controls
            _buildControls(isActive, isPaused, isUrdu),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StudySession session, bool isUrdu) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/main'),
          icon: Icon(
            isUrdu ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
            color: AppTheme.textSecondary,
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
                    ? AppTheme.urduHeading.copyWith(fontSize: 20)
                    : AppTheme.lightTheme.textTheme.titleLarge,
              ),
              Text(
                AppLocalizations.translate('focus_time', isUrdu ? 'ur' : 'en'),
                style: isUrdu 
                    ? AppTheme.urduBody.copyWith(color: AppTheme.textSecondary)
                    : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
              ),
            ],
          ),
        ),
        
        // Session info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${session.plannedDuration}m',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerCircle(StudySession session, Duration timeRemaining, bool isActive, bool isPaused) {
    final totalDuration = Duration(minutes: session.plannedDuration);
    final progress = totalDuration.inSeconds > 0 
        ? (totalDuration.inSeconds - timeRemaining.inSeconds) / totalDuration.inSeconds
        : 0.0;
    
    return SlideTransition(
      position: _floatingAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isActive ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    
                    // Progress indicator
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: AppTheme.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isActive 
                              ? AppTheme.accentColor 
                              : isPaused 
                                  ? AppTheme.warningColor 
                                  : AppTheme.textTertiary,
                        ),
                      ),
                    ),
                    
                    // Inner content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Subject icon
                        Text(
                          session.subjectIcon,
                          style: const TextStyle(fontSize: 48),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Time remaining
                        Text(
                          TimeHelper.formatDuration(timeRemaining),
                          style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                            fontSize: 48,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(isActive, isPaused).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(isActive, isPaused),
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: _getStatusColor(isActive, isPaused),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(bool isActive, bool isPaused, bool isUrdu) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop button
        _buildControlButton(
          icon: Icons.stop,
          label: AppLocalizations.translate('stop', isUrdu ? 'ur' : 'en'),
          color: AppTheme.errorColor,
          onPressed: () => context.go('/main'),
        ),
        
        // Pause/Resume button
        _buildControlButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: AppLocalizations.translate(
            isPaused ? 'resume' : 'pause', 
            isUrdu ? 'ur' : 'en'
          ),
          color: isPaused ? AppTheme.successColor : AppTheme.warningColor,
          onPressed: isPaused ? _resumeSession : _pauseSession,
        ),
        
        // Complete button
        _buildControlButton(
          icon: Icons.check,
          label: AppLocalizations.translate('done', isUrdu ? 'ur' : 'en'),
          color: AppTheme.successColor,
          onPressed: _completeSession,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTutorButton(bool isUrdu) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: FloatingActionButton(
        onPressed: _toggleTutor,
        backgroundColor: AppTheme.accentColor,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isTutorVisible ? Icons.close : Icons.smart_toy,
            key: ValueKey(_isTutorVisible),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(bool isActive, bool isPaused) {
    if (isPaused) return AppTheme.warningColor;
    if (isActive) return AppTheme.successColor;
    return AppTheme.textTertiary;
  }

  String _getStatusText(bool isActive, bool isPaused) {
    if (isPaused) return 'Paused';
    if (isActive) return 'Active';
    return 'Ready';
  }
}