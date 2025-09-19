import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import 'models/student_profile.dart';
import 'models/timetable.dart';
import 'models/study_session.dart';
import 'models/subject.dart';
import 'utils/time_helper.dart';

class AppStateManager extends ChangeNotifier {
  // Private fields
  StudentProfile? _studentProfile;
  Timetable? _currentTimetable;
  String _currentLanguage = 'en'; // 'en' or 'ur'
  bool _isOnboardingComplete = false;
  bool _isLoading = false;
  String _lastError = '';
  
  // Timer and session management
  StudySession? _activeSession;
  Timer? _sessionTimer;
  Duration _sessionTimeRemaining = Duration.zero;
  bool _isSessionPaused = false;
  
  // Chat state for AI tutor
  List<Map<String, String>> _chatMessages = [];
  bool _isChatVisible = false;
  bool _isAiTyping = false;
  
  // App lifecycle
  bool _isInitialized = false;
  Timer? _autoSaveTimer;
  Timer? _notificationTimer;
  
  // Getters
  StudentProfile? get studentProfile => _studentProfile;
  Timetable? get currentTimetable => _currentTimetable;
  String get currentLanguage => _currentLanguage;
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  
  // Session getters
  StudySession? get activeSession => _activeSession;
  Duration get sessionTimeRemaining => _sessionTimeRemaining;
  bool get isSessionActive => _activeSession?.isActive ?? false;
  bool get isSessionPaused => _isSessionPaused;
  bool get hasActiveTimer => _sessionTimer?.isActive ?? false;
  
  // Chat getters
  List<Map<String, String>> get chatMessages => List.from(_chatMessages);
  bool get isChatVisible => _isChatVisible;
  bool get isAiTyping => _isAiTyping;
  
  // Initialize the app state
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    try {
      await _loadUserData();
      await _loadTimetable();
      await _loadChatHistory();
      _setupAutoSave();
      _setupNotificationCheck();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize app: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Onboarding management
  Future<void> completeOnboarding(StudentProfile profile) async {
    try {
      _setLoading(true);
      _studentProfile = profile;
      _isOnboardingComplete = true;
      
      // Generate initial timetable
      await generateTimetable();
      
      // Save to storage
      await _saveUserData();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to complete onboarding: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Language management
  void setLanguage(String languageCode) {
    if (languageCode == 'en' || languageCode == 'ur') {
      _currentLanguage = languageCode;
      _saveLanguagePreference();
      notifyListeners();
    }
  }
  
  void toggleLanguage() {
    setLanguage(_currentLanguage == 'en' ? 'ur' : 'en');
  }
  
  // Timetable management
  Future<void> generateTimetable() async {
    if (_studentProfile == null) return;
    
    try {
      _setLoading(true);
      
      // Get subjects for the student's class
      final subjects = Subject.getSubjectsForClass(_studentProfile!.classLevel);
      
      // Update subjects based on student preferences
      final updatedSubjects = subjects.map((subject) {
        final difficulty = _studentProfile!.getSubjectDifficulty(subject.id);
        final weeklyHours = _studentProfile!.getSubjectHours(subject.id);
        
        return subject.copyWith(
          difficulty: difficulty,
          weeklyHours: weeklyHours,
          sessionDuration: TimeHelper.getOptimalSessionLength(
            _studentProfile!.age,
            subject.id,
            difficulty,
          ),
        );
      }).toList();
      
      // Generate the timetable
      _currentTimetable = Timetable.generateTimetable(
        studentId: _studentProfile!.id,
        profile: _studentProfile!,
        subjects: updatedSubjects,
      );
      
      await _saveTimetable();
      notifyListeners();
    } catch (e) {
      _setError('Failed to generate timetable: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Session management
  Future<void> startSession(String sessionId) async {
    if (_currentTimetable == null) return;
    
    try {
      final session = _currentTimetable!.sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw Exception('Session not found'),
      );
      
      _activeSession = session.start();
      _sessionTimeRemaining = Duration(minutes: session.plannedDuration);
      _isSessionPaused = false;
      
      // Update timetable
      _currentTimetable = _currentTimetable!.updateSession(_activeSession!);
      
      // Start timer
      _startSessionTimer();
      
      await _saveTimetable();
      notifyListeners();
    } catch (e) {
      _setError('Failed to start session: $e');
    }
  }
  
  void pauseSession() {
    if (_activeSession == null) return;
    
    _sessionTimer?.cancel();
    _isSessionPaused = true;
    _activeSession = _activeSession!.pause();
    
    if (_currentTimetable != null) {
      _currentTimetable = _currentTimetable!.updateSession(_activeSession!);
    }
    
    notifyListeners();
  }
  
  void resumeSession() {
    if (_activeSession == null) return;
    
    _isSessionPaused = false;
    _activeSession = _activeSession!.resume();
    
    if (_currentTimetable != null) {
      _currentTimetable = _currentTimetable!.updateSession(_activeSession!);
    }
    
    _startSessionTimer();
    notifyListeners();
  }
  
  Future<void> completeSession() async {
    if (_activeSession == null) return;
    
    _sessionTimer?.cancel();
    _activeSession = _activeSession!.complete();
    
    if (_currentTimetable != null) {
      _currentTimetable = _currentTimetable!.updateSession(_activeSession!);
      await _saveTimetable();
    }
    
    // Clear active session
    final completedSession = _activeSession;
    _activeSession = null;
    _sessionTimeRemaining = Duration.zero;
    _isSessionPaused = false;
    
    notifyListeners();
    
    // Show completion message and start break if needed
    _handleSessionCompletion(completedSession!);
  }
  
  Future<void> skipSession(String sessionId) async {
    if (_currentTimetable == null) return;
    
    try {
      final session = _currentTimetable!.sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw Exception('Session not found'),
      );
      
      final skippedSession = session.skip();
      _currentTimetable = _currentTimetable!.updateSession(skippedSession);
      
      await _saveTimetable();
      notifyListeners();
    } catch (e) {
      _setError('Failed to skip session: $e');
    }
  }
  
  // Chat management
  void toggleChatVisibility() {
    _isChatVisible = !_isChatVisible;
    notifyListeners();
  }
  
  void showChat() {
    _isChatVisible = true;
    notifyListeners();
  }
  
  void hideChat() {
    _isChatVisible = false;
    notifyListeners();
  }
  
  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message
    _chatMessages.add({
      'role': 'user',
      'content': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Add to active session if exists
    if (_activeSession != null) {
      _activeSession = _activeSession!.addChatMessage('User: $message');
      if (_currentTimetable != null) {
        _currentTimetable = _currentTimetable!.updateSession(_activeSession!);
      }
    }
    
    notifyListeners();
    
    // Get AI response (this would connect to your AI service)
    _isAiTyping = true;
    notifyListeners();
    
    try {
      // Simulate AI thinking time
      await Future.delayed(Duration(seconds: 2));
      
      final aiResponse = await _getAiResponse(message);
      
      _chatMessages.add({
        'role': 'assistant',
        'content': aiResponse,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Add to active session if exists
      if (_activeSession != null) {
        _activeSession = _activeSession!.addChatMessage('AI: $aiResponse');
        if (_currentTimetable != null) {
          _currentTimetable = _currentTimetable!.updateSession(_activeSession!);
        }
      }
      
      await _saveChatHistory();
    } catch (e) {
      _setError('Failed to get AI response: $e');
    } finally {
      _isAiTyping = false;
      notifyListeners();
    }
  }
  
  void clearChatHistory() {
    _chatMessages.clear();
    _saveChatHistory();
    notifyListeners();
  }
  
  // Utility methods
  StudySession? getCurrentSession() {
    return _currentTimetable?.getCurrentSession();
  }
  
  StudySession? getNextSession() {
    return _currentTimetable?.getNextSession();
  }
  
  List<StudySession> getTodaysSessions() {
    if (_currentTimetable == null) return [];
    return _currentTimetable!.getSessionsForDay(TimeHelper.getCurrentPakistanTime());
  }
  
  Map<String, List<StudySession>> getWeeklySchedule() {
    if (_currentTimetable == null) return {};
    return _currentTimetable!.getWeeklySchedule();
  }
  
  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _lastError = error;
    if (error.isNotEmpty) {
      debugPrint('AppStateManager Error: $error');
    }
    notifyListeners();
  }
  
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_sessionTimeRemaining.inSeconds > 0) {
        _sessionTimeRemaining = _sessionTimeRemaining - Duration(seconds: 1);
        notifyListeners();
      } else {
        timer.cancel();
        completeSession();
      }
    });
  }
  
  void _handleSessionCompletion(StudySession completedSession) {
    // This would show a completion notification
    // and potentially start the break timer
    debugPrint('Session completed: ${completedSession.subjectName}');
  }
  
  Future<String> _getAiResponse(String message) async {
    // This would connect to your AI tutoring service
    // For now, return a mock response
    if (_currentLanguage == 'ur') {
      return 'یہ بہت اچھا سوال ہے! آئیے اس پر تفصیل سے بات کرتے ہیں۔';
    } else {
      return 'That\'s a great question! Let me help you understand this concept better.';
    }
  }
  
  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      _saveUserData();
      _saveTimetable();
      _saveChatHistory();
    });
  }
  
  void _setupNotificationCheck() {
    _notificationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkUpcomingSessions();
    });
  }
  
  void _checkUpcomingSessions() {
    final nextSession = getNextSession();
    if (nextSession != null) {
      final timeUntilStart = nextSession.timeUntilStart;
      if (timeUntilStart.inMinutes <= 5 && timeUntilStart.inMinutes > 0) {
        // This would trigger a notification
        debugPrint('Session starting soon: ${nextSession.subjectName}');
      }
    }
  }
  
  // Storage methods
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load onboarding status
      _isOnboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      
      // Load language preference
      _currentLanguage = prefs.getString('language') ?? 'en';
      
      // Load student profile
      final profileJson = prefs.getString('student_profile');
      if (profileJson != null) {
        final profileMap = json.decode(profileJson);
        _studentProfile = StudentProfile.fromJson(profileMap);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }
  
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('onboarding_complete', _isOnboardingComplete);
      await prefs.setString('language', _currentLanguage);
      
      if (_studentProfile != null) {
        final profileJson = json.encode(_studentProfile!.toJson());
        await prefs.setString('student_profile', profileJson);
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }
  
  Future<void> _loadTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timetableJson = prefs.getString('current_timetable');
      
      if (timetableJson != null) {
        final timetableMap = json.decode(timetableJson);
        _currentTimetable = Timetable.fromJson(timetableMap);
        
        // Check if timetable needs update
        if (_currentTimetable!.needsUpdate) {
          await generateTimetable();
        }
      }
    } catch (e) {
      debugPrint('Error loading timetable: $e');
    }
  }
  
  Future<void> _saveTimetable() async {
    try {
      if (_currentTimetable != null) {
        final prefs = await SharedPreferences.getInstance();
        final timetableJson = json.encode(_currentTimetable!.toJson());
        await prefs.setString('current_timetable', timetableJson);
      }
    } catch (e) {
      debugPrint('Error saving timetable: $e');
    }
  }
  
  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatJson = prefs.getString('chat_history');
      
      if (chatJson != null) {
        final chatList = json.decode(chatJson) as List;
        _chatMessages = chatList.map((msg) => Map<String, String>.from(msg)).toList();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }
  
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatJson = json.encode(_chatMessages);
      await prefs.setString('chat_history', chatJson);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }
  
  Future<void> _saveLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _currentLanguage);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }
  
  // Data cleanup (called periodically)
  Future<void> cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 16));
      
      // Clean old chat messages
      _chatMessages.removeWhere((message) {
        final timestamp = DateTime.tryParse(message['timestamp'] ?? '');
        return timestamp != null && timestamp.isBefore(cutoffDate);
      });
      
      // Clean old timetable data
      if (_currentTimetable != null && _currentTimetable!.createdAt.isBefore(cutoffDate)) {
        await generateTimetable();
      }
      
      await _saveChatHistory();
      await _saveTimetable();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error cleaning up old data: $e');
    }
  }
  
  // Reset app data (for testing or user request)
  Future<void> resetAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _studentProfile = null;
      _currentTimetable = null;
      _isOnboardingComplete = false;
      _activeSession = null;
      _chatMessages.clear();
      _sessionTimer?.cancel();
      _sessionTimeRemaining = Duration.zero;
      _isSessionPaused = false;
      _isChatVisible = false;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset app data: $e');
    }
  }
  
  // Get app statistics
  Map<String, dynamic> getAppStatistics() {
    final stats = <String, dynamic>{
      'profile_complete': _studentProfile?.isComplete ?? false,
      'onboarding_complete': _isOnboardingComplete,
      'current_language': _currentLanguage,
      'total_chat_messages': _chatMessages.length,
      'has_active_session': _activeSession != null,
      'has_timetable': _currentTimetable != null,
    };
    
    if (_currentTimetable != null) {
      stats.addAll(_currentTimetable!.getCompletionStats());
      stats['total_weekly_hours'] = _currentTimetable!.totalWeeklyHours;
      stats['subjects_count'] = _currentTimetable!.getHoursBySubject().length;
    }
    
    return stats;
  }
  
  // Check if user can start studying (has completed setup)
  bool get canStartStudying {
    return _isOnboardingComplete && 
           _studentProfile != null && 
           _currentTimetable != null &&
           _studentProfile!.isComplete;
  }
  
  // Get current study streak (consecutive days with completed sessions)
  int get currentStudyStreak {
    if (_currentTimetable == null) return 0;
    
    int streak = 0;
    final today = TimeHelper.getCurrentPakistanTime();
    
    for (int i = 0; i < 30; i++) { // Check last 30 days
      final checkDate = today.subtract(Duration(days: i));
      final daySessions = _currentTimetable!.getSessionsForDay(checkDate);
      final studySessions = daySessions.where((s) => s.type == SessionType.study);
      
      if (studySessions.isEmpty) break;
      
      final completedSessions = studySessions.where((s) => s.isCompleted);
      if (completedSessions.isEmpty) break;
      
      streak++;
    }
    
    return streak;
  }
  
  // Dispose method to clean up resources
  @override
  void dispose() {
    _sessionTimer?.cancel();
    _autoSaveTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }
}