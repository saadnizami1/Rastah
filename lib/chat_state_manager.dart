import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/ai_service.dart';

// Chat message model with complete functionality
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String id;
  final Map<String, dynamic>? metadata;
  
  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    String? id,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now(),
       id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  Map<String, dynamic> toJson() => {
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'id': id,
    'metadata': metadata,
  };
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['content'] ?? '',
    isUser: json['isUser'] ?? false,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    metadata: json['metadata'],
  );
  
  ChatMessage copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? id,
    Map<String, dynamic>? metadata,
  }) => ChatMessage(
    content: content ?? this.content,
    isUser: isUser ?? this.isUser,
    timestamp: timestamp ?? this.timestamp,
    id: id ?? this.id,
    metadata: metadata ?? this.metadata,
  );
}

// Enhanced state manager with all features working
class ChatStateManager extends ChangeNotifier {
  // Private fields
  final List<ChatMessage> _messages = [];
  String _currentMode = 'therapist'; // Default to therapist mode
  bool _isTyping = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isConnected = true;
  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic> _userProfile = {};
  List<Map<String, dynamic>> _conversationSummaries = [];
  Map<String, dynamic> _moodLogs = {};
  String _lastError = '';
  
  // Timers and controllers
  Timer? _connectionTimer;
  Timer? _typingTimer;
  Timer? _autoSaveTimer;
  Timer? _heartbeatTimer;
  
  // Performance optimization caches
  String? _cachedUserName;
  int? _cachedTotalChats;
  Map<String, String> _cachedModeInfo = {};
  
  // Constants
  static const int _maxMessages = 1000;
  static const int _autoSaveInterval = 120; // 2 minutes
  static const int _connectionCheckInterval = 15; // 15 seconds
  
  // Getters with full functionality
  UnmodifiableListView<ChatMessage> get messages => UnmodifiableListView(_messages);
  String get currentMode => _currentMode;
  bool get isTyping => _isTyping;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic> get userProfile => Map.from(_userProfile);
  List<Map<String, dynamic>> get conversationSummaries => List.from(_conversationSummaries);
  Map<String, dynamic> get moodLogs => Map.from(_moodLogs);
  String get lastError => _lastError;
  bool get hasMessages => _messages.isNotEmpty;
  bool get canSendMessage => _isConnected && !_isTyping && !_isListening && !_isLoading && _isInitialized;
  
  // Enhanced getters with caching
  String get userName {
    _cachedUserName ??= _userProfile['name'] ?? _userProfile['user_name'] ?? 'دوست';
    return _cachedUserName!;
  }
  
  int get totalChats {
    _cachedTotalChats ??= _userProfile['totalChats'] ?? _userProfile['total_chats'] ?? 0;
    return _cachedTotalChats!;
  }
  
  String get currentModeDisplayName {
    if (_cachedModeInfo.containsKey(_currentMode)) {
      return _cachedModeInfo[_currentMode]!;
    }
    final modes = AIService.getAvailableModes();
    final name = modes[_currentMode]?['name'] ?? 'تھراپسٹ';
    _cachedModeInfo[_currentMode] = name;
    return name;
  }
  
  // Initialize with comprehensive setup
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    try {
      debugPrint('ChatStateManager: Starting initialization...');
      
      // Load all user data
      await _loadUserData();
      
      // Load conversation history
      await _loadConversationHistory();
      
      // Check connectivity
      await _checkConnection();
      
      // Start background services
      _startConnectionMonitoring();
      _startAutoSave();
      _startHeartbeat();
      
      // Initialize AI services
      await _initializeAIServices();
      
      // Set default mode if not already set
      if (_currentMode.isEmpty || !AIService.getAvailableModes().containsKey(_currentMode)) {
        _currentMode = 'therapist';
      }
      
      _isInitialized = true;
      debugPrint('ChatStateManager: Initialization completed successfully');
      
    } catch (e) {
      _setError('شروعاتی ڈیٹا لوڈ کرنے میں خرابی: $e');
      debugPrint('ChatStateManager: Initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load comprehensive user data
  Future<void> _loadUserData() async {
    try {
      _userProfile = await AIService.getUserProfile();
      _conversationSummaries = await AIService.getConversationSummaries();
      _moodLogs = await AIService.getMoodLogs();
      
      // Clear cache to force refresh
      _cachedUserName = null;
      _cachedTotalChats = null;
      _cachedModeInfo.clear();
      
      debugPrint('ChatStateManager: User data loaded successfully');
    } catch (e) {
      debugPrint('ChatStateManager: Error loading user data: $e');
      _setError('صارف کا ڈیٹا لوڈ کرنے میں خرابی: $e');
    }
  }
  
  // Load conversation history from storage
  Future<void> _loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationJson = prefs.getString('current_conversation');
      
      if (conversationJson != null && conversationJson.isNotEmpty) {
        final List<dynamic> messageList = json.decode(conversationJson);
        _messages.clear();
        
        for (final messageData in messageList) {
          try {
            final message = ChatMessage.fromJson(messageData);
            _messages.add(message);
          } catch (e) {
            debugPrint('ChatStateManager: Error parsing message: $e');
          }
        }
        
        // Limit messages to prevent memory issues
        if (_messages.length > _maxMessages) {
          _messages.removeRange(0, _messages.length - _maxMessages);
        }
        
        debugPrint('ChatStateManager: Loaded ${_messages.length} messages from history');
      }
    } catch (e) {
      debugPrint('ChatStateManager: Error loading conversation history: $e');
    }
  }
  
  // Save conversation to storage
  Future<void> _saveConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messageList = _messages.map((msg) => msg.toJson()).toList();
      await prefs.setString('current_conversation', json.encode(messageList));
    } catch (e) {
      debugPrint('ChatStateManager: Error saving conversation: $e');
    }
  }
  
  // Initialize AI services
  Future<void> _initializeAIServices() async {
    try {
      await AIService.initializeTTS();
      await AIService.initializeSTT();
      debugPrint('ChatStateManager: AI services initialized');
    } catch (e) {
      debugPrint('ChatStateManager: Error initializing AI services: $e');
    }
  }
  
  // Enhanced message sending with full error handling
  Future<void> sendMessage(String content) async {
    if (!canSendMessage || content.trim().isEmpty) {
      debugPrint('ChatStateManager: Cannot send message - conditions not met');
      return;
    }
    
    final trimmedContent = content.trim();
    debugPrint('ChatStateManager: Sending message: ${trimmedContent.substring(0, trimmedContent.length > 50 ? 50 : trimmedContent.length)}...');
    
    // Create user message
    final userMessage = ChatMessage(
      content: trimmedContent,
      isUser: true,
      metadata: {
        'mode': _currentMode,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    // Add user message immediately
    _messages.add(userMessage);
    _setTyping(true);
    _clearError();
    notifyListeners();
    
    // Save immediately for data persistence
    unawaited(_saveConversationHistory());
    
    try {
      // Build conversation context
      final conversationHistory = _buildConversationHistory();
      
      debugPrint('ChatStateManager: Generating AI response...');
      
      // Generate AI response with timeout
      final response = await Future.any([
        AIService.generateResponse(
          userMessage: trimmedContent,
          mode: _currentMode,
          conversationHistory: conversationHistory,
          userProfile: _userProfile,
        ),
        Future.delayed(const Duration(seconds: 30), () => throw TimeoutException('AI response timeout', const Duration(seconds: 30))),
      ]);
      
      // Create AI message
      final aiMessage = ChatMessage(
        content: response,
        isUser: false,
        metadata: {
          'mode': _currentMode,
          'response_time': DateTime.now().toIso8601String(),
        },
      );
      
      _messages.add(aiMessage);
      
      // Update statistics
      await _updateChatStatistics();
      
      // Auto-save conversation summary if conversation is long enough
      if (_messages.where((msg) => msg.isUser).length >= 4) {
        unawaited(_autoSaveConversationSummary());
      }
      
      debugPrint('ChatStateManager: AI response received and processed');
      
    } catch (e) {
      debugPrint('ChatStateManager: Error generating AI response: $e');
      
      // Create error message
      final errorMessage = ChatMessage(
        content: _getLocalizedErrorMessage(e),
        isUser: false,
        metadata: {
          'error': true,
          'original_error': e.toString(),
        },
      );
      
      _messages.add(errorMessage);
      _setError('پیغام بھیجنے میں خرابی: $e');
    } finally {
      _setTyping(false);
      
      // Clean up old messages if too many
      if (_messages.length > _maxMessages) {
        _messages.removeRange(0, _messages.length - _maxMessages);
      }
      
      // Save updated conversation
      unawaited(_saveConversationHistory());
      notifyListeners();
    }
  }
  
  // Enhanced mode changing with validation
  Future<void> changeMode(String newMode) async {
    if (_currentMode == newMode) return;
    
    final availableModes = AIService.getAvailableModes();
    if (!availableModes.containsKey(newMode)) {
      debugPrint('ChatStateManager: Invalid mode: $newMode');
      return;
    }
    
    final oldMode = _currentMode;
    _currentMode = newMode;
    
    // Clear mode cache
    _cachedModeInfo.clear();
    
    // Add system message about mode change
    final modeInfo = availableModes[newMode]!;
    final systemMessage = ChatMessage(
      content: 'اب میں ${modeInfo['name']} ${modeInfo['emoji']} کے انداز میں آپ کی مدد کروں گا۔',
      isUser: false,
      metadata: {
        'system': true,
        'mode_change': {'from': oldMode, 'to': newMode},
      },
    );
    
    _messages.add(systemMessage);
    
    // Save mode preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_mode', newMode);
    } catch (e) {
      debugPrint('ChatStateManager: Error saving mode preference: $e');
    }
    
    notifyListeners();
    debugPrint('ChatStateManager: Mode changed from $oldMode to $newMode');
  }
  
  // Enhanced voice input with error handling
  Future<String> startListening() async {
    if (!canSendMessage || _isListening) return '';
    
    _setListening(true);
    try {
      debugPrint('ChatStateManager: Starting voice input...');
      
      final result = await Future.any([
        AIService.listenToSpeech(),
        Future.delayed(const Duration(seconds: 15), () => throw TimeoutException('Voice input timeout', const Duration(seconds: 15))),
      ]);
      
      debugPrint('ChatStateManager: Voice input result: $result');
      return result;
      
    } catch (e) {
      debugPrint('ChatStateManager: Voice input error: $e');
      _setError('آواز سننے میں خرابی: $e');
      return '';
    } finally {
      _setListening(false);
    }
  }
  
  // Stop voice input
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await AIService.stopListening();
      debugPrint('ChatStateManager: Voice input stopped');
    } catch (e) {
      debugPrint('ChatStateManager: Error stopping voice input: $e');
    } finally {
      _setListening(false);
    }
  }
  
  // Enhanced text-to-speech
  Future<void> speakText(String text) async {
    if (text.trim().isEmpty) return;
    
    if (_isSpeaking) {
      await stopSpeaking();
      return;
    }
    
    _setSpeaking(true);
    try {
      debugPrint('ChatStateManager: Starting TTS for text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      
      await AIService.speakText(text);
      
    } catch (e) {
      debugPrint('ChatStateManager: TTS error: $e');
      _setError('آواز میں بولنے میں خرابی: $e');
    } finally {
      _setSpeaking(false);
    }
  }
  
  // Stop text-to-speech
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;
    
    try {
      await AIService.stopSpeaking();
      debugPrint('ChatStateManager: TTS stopped');
    } catch (e) {
      debugPrint('ChatStateManager: Error stopping TTS: $e');
    } finally {
      _setSpeaking(false);
    }
  }
  
  // Enhanced profile management
  Future<void> updateUserProfile(Map<String, dynamic> updatedProfile) async {
    try {
      await AIService.updateUserProfile(updatedProfile);
      _userProfile = await AIService.getUserProfile();
      
      // Clear cache
      _cachedUserName = null;
      _cachedTotalChats = null;
      
      notifyListeners();
      debugPrint('ChatStateManager: User profile updated successfully');
      
    } catch (e) {
      debugPrint('ChatStateManager: Error updating profile: $e');
      _setError('پروفائل اپڈیٹ کرنے میں خرابی: $e');
    }
  }
  
  // Enhanced mood tracking
  Future<void> updateUserMood(String mood, int stressLevel, {DateTime? lastCried}) async {
    try {
      _userProfile['currentMood'] = mood;
      _userProfile['stressLevel'] = stressLevel;
      if (lastCried != null) {
        _userProfile['lastCried'] = lastCried.toIso8601String();
      }
      
      await AIService.updateUserMood(mood, stressLevel, lastCried: lastCried);
      await _loadUserData(); // Reload to get updated mood logs
      
      debugPrint('ChatStateManager: Mood updated - $mood, stress: $stressLevel');
      
    } catch (e) {
      debugPrint('ChatStateManager: Error updating mood: $e');
      _setError('موڈ اپڈیٹ کرنے میں خرابی: $e');
    }
  }
  
  // Start new conversation
  Future<void> startNewChat() async {
    try {
      // Save current conversation if substantial
      if (_messages.where((msg) => msg.isUser).length >= 3) {
        await _saveCurrentConversationSummary();
      }
      
      _messages.clear();
      await AIService.clearCurrentConversation();
      await _loadUserData();
      _clearError();
      
      // Clear conversation from storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_conversation');
      
      notifyListeners();
      debugPrint('ChatStateManager: New chat started successfully');
      
    } catch (e) {
      debugPrint('ChatStateManager: Error starting new chat: $e');
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
      
      // Clear all caches
      _cachedUserName = null;
      _cachedTotalChats = null;
      _cachedModeInfo.clear();
      
      _clearError();
      notifyListeners();
      
      debugPrint('ChatStateManager: All data cleared successfully');
      
    } catch (e) {
      debugPrint('ChatStateManager: Error clearing data: $e');
      _setError('ڈیٹا صاف کرنے میں خرابی: $e');
    }
  }
  
  // Connection monitoring
  Future<void> _checkConnection() async {
    try {
      final connected = await AIService.hasInternetConnection();
      if (_isConnected != connected) {
        _isConnected = connected;
        notifyListeners();
        debugPrint('ChatStateManager: Connection status changed: $connected');
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        notifyListeners();
        debugPrint('ChatStateManager: Connection check failed: $e');
      }
    }
  }
  
  // Start connection monitoring
  void _startConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(Duration(seconds: _connectionCheckInterval), (_) {
      _checkConnection();
    });
  }
  
  // Start auto-save
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(Duration(seconds: _autoSaveInterval), (_) {
      _autoSaveConversation();
    });
  }
  
  // Start heartbeat for keeping app state fresh
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performHeartbeat();
    });
  }
  
  // Heartbeat operations
  Future<void> _performHeartbeat() async {
    try {
      // Refresh user data periodically
      await _loadUserData();
      
      // Clean up old messages if needed
      if (_messages.length > _maxMessages) {
        _messages.removeRange(0, _messages.length - (_maxMessages * 0.8).round());
        await _saveConversationHistory();
      }
      
    } catch (e) {
      debugPrint('ChatStateManager: Heartbeat error: $e');
    }
  }
  
  // Auto-save conversation
  Future<void> _autoSaveConversation() async {
    if (_messages.length < 4) return;
    
    try {
      await _saveConversationHistory();
      
      // Auto-save summary if conversation is substantial
      if (_messages.where((msg) => msg.isUser).length >= 6) {
        await _autoSaveConversationSummary();
      }
      
    } catch (e) {
      debugPrint('ChatStateManager: Auto-save error: $e');
    }
  }
  
  // Save conversation summary
  Future<void> _saveCurrentConversationSummary() async {
    try {
      final conversationHistory = _buildConversationHistory();
      final summary = await AIService.generateConversationSummary(conversationHistory);
      
      if (summary.isNotEmpty) {
        await AIService.saveConversationSummary(summary);
        _conversationSummaries = await AIService.getConversationSummaries();
        notifyListeners();
        debugPrint('ChatStateManager: Conversation summary saved');
      }
    } catch (e) {
      debugPrint('ChatStateManager: Error saving conversation summary: $e');
    }
  }
  
  // Auto-save conversation summary
  Future<void> _autoSaveConversationSummary() async {
    try {
      await _saveCurrentConversationSummary();
    } catch (e) {
      debugPrint('ChatStateManager: Auto-save summary error: $e');
    }
  }
  
  // Update chat statistics
  Future<void> _updateChatStatistics() async {
    try {
      await AIService.incrementChatCounter();
      _cachedTotalChats = null; // Reset cache
    } catch (e) {
      debugPrint('ChatStateManager: Error updating chat statistics: $e');
    }
  }
  
  // Build conversation history for AI context
  List<Map<String, String>> _buildConversationHistory() {
    // Get last 20 messages for context (to avoid token limits)
    final recentMessages = _messages.length > 20 
        ? _messages.sublist(_messages.length - 20)
        : _messages;
    
    return recentMessages
        .where((msg) => msg.metadata?['system'] != true) // Exclude system messages
        .map((msg) => {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        })
        .toList();
  }
  
  // State setters with notifications
  void _setTyping(bool typing) {
    if (_isTyping != typing) {
      _isTyping = typing;
      notifyListeners();
    }
  }
  
  void _setListening(bool listening) {
    if (_isListening != listening) {
      _isListening = listening;
      notifyListeners();
    }
  }
  
  void _setSpeaking(bool speaking) {
    if (_isSpeaking != speaking) {
      _isSpeaking = speaking;
      notifyListeners();
    }
  }
  
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _setError(String error) {
    _lastError = error;
    debugPrint('ChatStateManager Error: $error');
    notifyListeners();
  }
  
  void _clearError() {
    if (_lastError.isNotEmpty) {
      _lastError = '';
      notifyListeners();
    }
  }
  
  // Enhanced error message localization
  String _getLocalizedErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (error is TimeoutException) {
      return 'وقت ختم ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔ ⏰';
    } else if (errorString.contains('timeout')) {
      return 'انٹرنیٹ سست ہے۔ براہ کرم دوبارہ کوشش کریں۔ 🐌';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'کنکشن میں خرابی ہے۔ براہ کرم انٹرنیٹ چیک کریں۔ 📡';
    } else if (errorString.contains('permission')) {
      return 'اجازت کی ضرورت ہے۔ براہ کرم settings چیک کریں۔ ⚙️';
    } else if (errorString.contains('api') || errorString.contains('401')) {
      return 'AI سروس میں خرابی ہے۔ براہ کرم بعد میں کوشش کریں۔ 🔧';
    } else if (errorString.contains('429')) {
      return 'AI سروس مصروف ہے۔ براہ کرم کچھ دیر بعد کوشش کریں۔ ⏰';
    } else if (errorString.contains('microphone') || errorString.contains('speech')) {
      return 'مائیکروفون کی خرابی۔ براہ کرم permissions چیک کریں۔ 🎤';
    } else {
      return 'کوئی خرابی ہوئی ہے۔ براہ کرم دوبارہ کوشش کریں۔ 🔄';
    }
  }
  
  // Get app statistics
  Map<String, dynamic> getAppStatistics() {
    return {
      'total_messages': _messages.length,
      'user_messages': _messages.where((msg) => msg.isUser).length,
      'ai_messages': _messages.where((msg) => !msg.isUser).length,
      'current_mode': _currentMode,
      'total_chats': totalChats,
      'conversation_summaries': _conversationSummaries.length,
      'mood_logs': _moodLogs.length,
      'is_connected': _isConnected,
      'is_initialized': _isInitialized,
    };
  }
  
  // Cleanup resources
  @override
  void dispose() {
    debugPrint('ChatStateManager: Disposing resources...');
    
    _connectionTimer?.cancel();
    _typingTimer?.cancel();
    _autoSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    
    // Save current state before disposing
    if (_isInitialized && _messages.isNotEmpty) {
      _saveConversationHistory();
    }
    
    super.dispose();
  }
}

// Utility function for fire-and-forget operations
void unawaited(Future<void> future) {
  future.catchError((error) {
    debugPrint('Unawaited operation failed: $error');
  });
}