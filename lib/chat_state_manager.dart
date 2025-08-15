import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';
import 'services/ai_service.dart';
// import 'ai_service.dart'; // Import your AI service

// Main state manager for the chat functionality
class ChatStateManager extends ChangeNotifier {
  // Private fields
  List<ChatMessage> _messages = [];
  String _currentMode = 'friend';
  bool _isTyping = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isConnected = true;
  bool _isLoading = false;
  Map<String, dynamic> _userProfile = {};
  List<Map<String, dynamic>> _conversationSummaries = [];
  Map<String, dynamic> _moodLogs = {};
  String _lastError = '';
  Timer? _connectionTimer;
  Timer? _typingTimer;

  // Getters
  UnmodifiableListView<ChatMessage> get messages => UnmodifiableListView(_messages);
  String get currentMode => _currentMode;
  bool get isTyping => _isTyping;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get userProfile => Map.from(_userProfile);
  List<Map<String, dynamic>> get conversationSummaries => List.from(_conversationSummaries);
  Map<String, dynamic> get moodLogs => Map.from(_moodLogs);
  String get lastError => _lastError;
  bool get hasMessages => _messages.isNotEmpty;
  bool get canSendMessage => _isConnected && !_isTyping && !_isListening;

  // Initialize the state manager
  Future<void> initialize() async {
    await _loadUserData();
    await _checkConnection();
    _startConnectionMonitoring();
  }

  // Load user data from storage
  Future<void> _loadUserData() async {
    try {
      _userProfile = await AIService.getUserProfile();
      _conversationSummaries = await AIService.getConversationSummaries();
      _moodLogs = await AIService.getMoodLogs();
      notifyListeners();
    } catch (e) {
      _setError('ڈیٹا لوڈ کرنے میں خرابی: $e');
    }
  }

  // Check internet connection
  Future<void> _checkConnection() async {
    try {
      final connected = await AIService.hasInternetConnection();
      if (_isConnected != connected) {
        _isConnected = connected;
        notifyListeners();
      }
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  // Start monitoring connection
  void _startConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _checkConnection();
    });
  }

  // Send a message
  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty || !canSendMessage) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: messageText.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      mode: _currentMode,
    );

    // Add user message
    _messages.add(userMessage);
    _setTyping(true);
    notifyListeners();

    try {
      // Get AI response
      final response = await AIService.generateResponse(
        userMessage: messageText.trim(),
        mode: _currentMode,
        conversationHistory: _getConversationHistory(),
        userProfile: _userProfile,
      );

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        mode: _currentMode,
      );

      _messages.add(aiMessage);
      
      // Auto-save conversation summary
      await _autoSaveConversation();
      await AIService.incrementChatCounter();
      
      _clearError();
    } catch (e) {
      _setError('پیغام بھیجنے میں خرابی: $e');
      
      // Add error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'معذرت، کوئی خرابی ہوئی ہے۔ براہ کرم دوبارہ کوشش کریں۔ 🔄',
        isUser: false,
        timestamp: DateTime.now(),
        mode: _currentMode,
        isError: true,
      );
      _messages.add(errorMessage);
    } finally {
      _setTyping(false);
      notifyListeners();
    }
  }

  // Start/stop voice listening
  Future<void> toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<String> _startListening() async {
    try {
      _isListening = true;
      notifyListeners();
      
      final result = await AIService.listenToSpeech();
      
      if (result.isNotEmpty && 
          !result.contains('خرابی') && 
          !result.contains('دستیاب نہیں')) {
        return result; // Return the recognized text
      }
    } catch (e) {
      _setError('آواز سننے میں خرابی: $e');
    } finally {
      _isListening = false;
      notifyListeners();
    }
    return '';
  }

  Future<void> _stopListening() async {
    await AIService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  // Text-to-speech functionality
  Future<void> speakMessage(String text) async {
    if (_isSpeaking) {
      await _stopSpeaking();
    } else {
      await _startSpeaking(text);
    }
  }

  Future<void> _startSpeaking(String text) async {
    try {
      _isSpeaking = true;
      notifyListeners();
      await AIService.speakText(text);
    } catch (e) {
      _setError('آواز چلانے میں خرابی: $e');
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> _stopSpeaking() async {
    await AIService.stopSpeaking();
    _isSpeaking = false;
    notifyListeners();
  }

  // Change AI mode
  void changeMode(String newMode) {
    if (_currentMode != newMode) {
      _currentMode = newMode;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> newProfile) async {
    try {
      _userProfile = Map.from(newProfile);
      await AIService.updateUserProfile(newProfile);
      notifyListeners();
    } catch (e) {
      _setError('پروفائل اپڈیٹ کرنے میں خرابی: $e');
    }
  }

  // Update mood
  Future<void> updateMood(String mood, int stressLevel, {DateTime? lastCried}) async {
    try {
      _userProfile['currentMood'] = mood;
      _userProfile['stressLevel'] = stressLevel;
      if (lastCried != null) {
        _userProfile['lastCried'] = lastCried.toIso8601String();
      }
      
      await AIService.updateUserMood(mood, stressLevel, lastCried: lastCried);
      await _loadUserData(); // Reload to get updated mood logs
      notifyListeners();
    } catch (e) {
      _setError('موڈ اپڈیٹ کرنے میں خرابی: $e');
    }
  }

  // Start new chat
  Future<void> startNewChat() async {
    try {
      // Save current conversation if it has enough messages
      if (_messages.where((msg) => msg.isUser).length >= 4) {
        final conversationHistory = _getConversationHistory();
        final summary = await AIService.generateConversationSummary(conversationHistory);
        if (summary.isNotEmpty) {
          await AIService.saveConversationSummary(summary);
        }
      }
      
      _messages.clear();
      await AIService.clearCurrentConversation();
      await _loadUserData();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('نئی گفتگو شروع کرنے میں خرابی: $e');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      await AIService.clearAllData();
      _messages.clear();
      _userProfile.clear();
      _conversationSummaries.clear();
      _moodLogs.clear();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('ڈیٹا صاف کرنے میں خرابی: $e');
    }
  }

  // Auto-save conversation
  Future<void> _autoSaveConversation() async {
    try {
      final conversationHistory = _getConversationHistory();
      await AIService.autoSaveConversationSummary(conversationHistory);
      // Reload summaries
      _conversationSummaries = await AIService.getConversationSummaries();
    } catch (e) {
      // Silent fail for auto-save
      debugPrint('Auto-save failed: $e');
    }
  }

  // Get conversation history for AI
  List<Map<String, String>> _getConversationHistory() {
    return _messages.map((msg) => {
      'role': msg.isUser ? 'user' : 'assistant',
      'content': msg.content,
    }).toList();
  }

  // Private helper methods
  void _setTyping(bool typing) {
    if (_isTyping != typing) {
      _isTyping = typing;
      
      if (typing) {
        _typingTimer?.cancel();
        _typingTimer = Timer(Duration(seconds: 30), () {
          _setTyping(false);
          _setError('جواب کا انتظار زیادہ ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔');
        });
      } else {
        _typingTimer?.cancel();
      }
    }
  }

  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    if (_lastError.isNotEmpty) {
      _lastError = '';
      notifyListeners();
    }
  }

  // Retry last message
  Future<void> retryLastMessage() async {
    if (_messages.isNotEmpty) {
      // Find the last user message
      for (int i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].isUser) {
          final lastUserMessage = _messages[i].content;
          // Remove messages after the last user message
          _messages.removeRange(i + 1, _messages.length);
          await sendMessage(lastUserMessage);
          break;
        }
      }
    }
  }

  // Get app statistics
  Map<String, dynamic> getAppStats() {
    return {
      'totalMessages': _messages.length,
      'userMessages': _messages.where((msg) => msg.isUser).length,
      'aiMessages': _messages.where((msg) => !msg.isUser).length,
      'currentMode': _currentMode,
      'isConnected': _isConnected,
      'hasProfile': _userProfile['name']?.toString().isNotEmpty ?? false,
      'moodLogsCount': _moodLogs.length,
      'conversationSummariesCount': _conversationSummaries.length,
    };
  }

  // Search in conversation history
  List<ChatMessage> searchMessages(String query) {
    if (query.trim().isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _messages.where((msg) => 
      msg.content.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Export conversation
  String exportConversation() {
    final buffer = StringBuffer();
    buffer.writeln('راستہ - گفتگو کی برآمد');
    buffer.writeln('تاریخ: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('موڈ: $_currentMode');
    buffer.writeln('مجموعی پیغامات: ${_messages.length}');
    buffer.writeln('${'=' * 50}');
    buffer.writeln();
    
    for (final message in _messages) {
      final sender = message.isUser ? 'آپ' : 'راستہ';
      final time = '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}';
      buffer.writeln('[$time] $sender: ${message.content}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _typingTimer?.cancel();
    AIService.stopSpeaking();
    AIService.stopListening();
    super.dispose();
  }
}

// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String mode;
  final bool isError;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.mode,
    this.isError = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'mode': mode,
      'isError': isError,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      mode: json['mode'],
      isError: json['isError'] ?? false,
      metadata: json['metadata'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? mode,
    bool? isError,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      mode: mode ?? this.mode,
      isError: isError ?? this.isError,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Performance optimizations for the chat
class ChatPerformanceOptimizer {
  static const int maxMessagesInMemory = 100;
  static const int messagesToKeepWhenCleanup = 80;

  // Optimize message list for performance
  static List<ChatMessage> optimizeMessageList(List<ChatMessage> messages) {
    if (messages.length <= maxMessagesInMemory) {
      return messages;
    }

    // Keep recent messages and some important older ones
    final recentMessages = messages.sublist(messages.length - messagesToKeepWhenCleanup);
    return recentMessages;
  }

  // Debounce function for text input
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  // Throttle function for frequent operations
  static DateTime? _lastThrottleTime;
  static bool throttle({Duration delay = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || now.difference(_lastThrottleTime!) >= delay) {
      _lastThrottleTime = now;
      return true;
    }
    return false;
  }

  // Memory cleanup
  static void cleanup() {
    _debounceTimer?.cancel();
    _lastThrottleTime = null;
  }
}

// Cache manager for better performance
class ChatCacheManager {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheExpiry = Duration(minutes: 5);

  static void set(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static T? get<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > cacheExpiry) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _cache[key] as T?;
  }

  static void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}

// Analytics for chat usage
class ChatAnalytics {
  static final List<Map<String, dynamic>> _events = [];

  static void trackEvent(String eventName, {Map<String, dynamic>? parameters}) {
    _events.add({
      'event': eventName,
      'timestamp': DateTime.now().toIso8601String(),
      'parameters': parameters ?? {},
    });

    // Keep only last 100 events
    if (_events.length > 100) {
      _events.removeAt(0);
    }
  }

  static void trackMessageSent(String mode, int messageLength) {
    trackEvent('message_sent', parameters: {
      'mode': mode,
      'message_length': messageLength,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void trackModeChanged(String oldMode, String newMode) {
    trackEvent('mode_changed', parameters: {
      'old_mode': oldMode,
      'new_mode': newMode,
    });
  }

  static void trackVoiceUsed(String action) {
    trackEvent('voice_used', parameters: {
      'action': action, // 'listening' or 'speaking'
    });
  }

  static void trackError(String errorType, String errorMessage) {
    trackEvent('error_occurred', parameters: {
      'error_type': errorType,
      'error_message': errorMessage,
    });
  }

  static Map<String, dynamic> getUsageStats() {
    final messagesSent = _events.where((e) => e['event'] == 'message_sent').length;
    final modesUsed = _events
        .where((e) => e['event'] == 'mode_changed')
        .map((e) => e['parameters']['new_mode'])
        .toSet()
        .length;
    final voiceUsage = _events.where((e) => e['event'] == 'voice_used').length;
    final errors = _events.where((e) => e['event'] == 'error_occurred').length;

    return {
      'total_messages_sent': messagesSent,
      'different_modes_used': modesUsed,
      'voice_interactions': voiceUsage,
      'total_errors': errors,
      'session_start': _events.isNotEmpty ? _events.first['timestamp'] : null,
      'last_activity': _events.isNotEmpty ? _events.last['timestamp'] : null,
    };
  }

  static List<Map<String, dynamic>> getRecentEvents({int limit = 20}) {
    final recentEvents = _events.reversed.take(limit).toList();
    return recentEvents;
  }

  static void clearAnalytics() {
    _events.clear();
  }
}

// Error handling utilities
class ChatErrorHandler {
  static String getLocalizedErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout')) {
      return 'انٹرنیٹ سست ہے۔ براہ کرم دوبارہ کوشش کریں۔ 🐌';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'کنکشن میں خرابی ہے۔ براہ کرم انٹرنیٹ چیک کریں۔ 📡';
    } else if (errorString.contains('permission')) {
      return 'اجازت کی ضرورت ہے۔ براہ کرم settings چیک کریں۔ ⚙️';
    } else if (errorString.contains('api') || errorString.contains('401')) {
      return 'AI سروس میں خرابی ہے۔ براہ کرم بعد میں کوشش کریں۔ 🔧';
    } else if (errorString.contains('429')) {
      return 'AI سروس مصروف ہے۔ براہ کرم کچھ دیر بعد کوشش کریں۔ ⏰';
    } else {
      return 'کوئی خرابی ہوئی ہے۔ براہ کرم دوبارہ کوشش کریں۔ 🔄';
    }
  }

  static void logError(dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('Chat Error: $error');
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
      }
    }
    
    // Track error in analytics
    ChatAnalytics.trackError(
      error.runtimeType.toString(),
      error.toString(),
    );
  }

  static void handleError(BuildContext context, dynamic error) {
    final message = getLocalizedErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'ٹھیک ہے',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}