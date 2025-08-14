import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';

// Import your enhanced AI service and Voice service
import '../services/ai_service.dart';
import '../services/voice_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _conversationHistory = [];
  bool _isTyping = false;
  bool _isTherapyMode = true;
  String _userName = '';
  String _profileImagePath = '';
  bool _isAIConfigured = false;
  late AnimationController _typingController;
  int _messageCount = 0;
  
  // Voice-related variables
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _recognizedText = '';
  late AnimationController _voiceAnimationController;
  
  @override
  void initState() {
    super.initState();
    _initializeChat();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Initialize voice animation controller
    _voiceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Initialize voice service
    _initializeVoiceService();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
      _checkFirstTimeUser();
      
      // Start AI warm-up as early as possible
      if (AIService.isConfigured()) {
        _warmUpAIService();
      }
    });
  }

  // Warm up AI service for faster first response
  Future<void> _warmUpAIService() async {
    if (_isAIConfigured) {
      try {
        // Background warm-up call - don't await in initializeChat
        await AIService.generateResponse(
          userMessage: "test",
          isTherapyMode: false,
          conversationHistory: [],
          userProfile: {},
        );
      } catch (e) {
        // Ignore warm-up errors
      }
    }
  }

  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
    
    // Listen to voice service streams
    _voiceService.listeningState.listen((isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
        });
      }
    });
    
    _voiceService.speakingState.listen((isSpeaking) {
      if (mounted) {
        setState(() {
          _isSpeaking = isSpeaking;
        });
      }
    });
    
    _voiceService.recognizedText.listen((recognizedText) {
      if (mounted) {
        setState(() {
          _recognizedText = recognizedText;
        });
        
        // Auto-fill the message controller as user speaks
        if (recognizedText.isNotEmpty) {
          _messageController.text = recognizedText;
        }
      }
    });
  }

  @override
  void dispose() {
    _typingController.dispose();
    _voiceAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await _loadUserData();
    await _loadChatHistory();
    _checkAIConfiguration();
    
    // Start warm-up in background (don't await)
    if (_isAIConfigured) {
      _warmUpAIService();
    }
  }

  void _checkAIConfiguration() {
    setState(() {
      _isAIConfigured = AIService.isConfigured();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? 'دوست';
      _profileImagePath = prefs.getString('profile_image') ?? '';
    });
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistory = prefs.getString('chat_history');
    final conversationHistory = prefs.getString('conversation_history');
    
    if (chatHistory != null) {
      try {
        final List<dynamic> decoded = json.decode(chatHistory);
        setState(() {
          _messages = decoded.map((msg) => ChatMessage.fromJson(msg)).toList();
          _messageCount = _messages.where((msg) => msg.isUser).length;
        });
      } catch (e) {
        print('Error loading chat history: $e');
        setState(() {
          _messages = [];
          _messageCount = 0;
        });
      }
    }
    
    if (conversationHistory != null) {
      try {
        final List<dynamic> decoded = json.decode(conversationHistory);
        setState(() {
          _conversationHistory = decoded.map((item) {
            final Map<String, dynamic> map = item as Map<String, dynamic>;
            return {
              'role': map['role']?.toString() ?? '',
              'content': map['content']?.toString() ?? '',
            };
          }).toList();
        });
      } catch (e) {
        print('Error loading conversation history: $e');
        setState(() {
          _conversationHistory = [];
        });
      }
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_messages.map((msg) => msg.toJson()).toList());
      final conversationEncoded = json.encode(_conversationHistory);
      
      await prefs.setString('chat_history', encoded);
      await prefs.setString('conversation_history', conversationEncoded);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text: 'السلام علیکم $_userName! میں رستہ ہوں، آپ کا پیشہ ور AI تھراپسٹ۔ آپ آج کیسا محسوس کر رہے ہیں؟ مہربانی کر کے اپنے احساسات کے بارے میں تفصیل سے بتائیں۔',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
    _saveChatHistory();
  }

  // Voice interaction methods
  Future<void> _startListening() async {
    if (_isTyping) return; // Don't start listening while AI is responding
    
    try {
      final hasPermission = await _voiceService.checkMicrophonePermission();
      if (!hasPermission) {
        final granted = await _voiceService.requestMicrophonePermission();
        if (!granted) {
          _showPermissionDialog();
          return;
        }
      }
      
      _messageController.clear();
      await _voiceService.startListening();
    } catch (e) {
      _showErrorSnackBar('آواز سننے میں مسئلہ: $e');
    }
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    
    // Auto-send message if we have recognized text
    if (_recognizedText.isNotEmpty && _messageController.text.isNotEmpty) {
      _sendMessage();
    }
  }

  Future<void> _speakMessage(String text) async {
    try {
      if (_isSpeaking) {
        await _voiceService.stop();
      } else {
        await _voiceService.speak(text);
      }
    } catch (e) {
      _showErrorSnackBar('TTS Error: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'مائیکروفون کی اجازت درکار',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'آپ کی آواز سننے کے لیے مائیکروفون کی اجازت ضروری ہے۔',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 16,
            color: Colors.white,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'بعد میں',
              style: GoogleFonts.notoNaskhArabic(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _voiceService.requestMicrophonePermission();
            },
            child: Text(
              'اجازت دیں',
              style: GoogleFonts.notoNaskhArabic(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.notoNaskhArabic(color: Colors.white),
        ),
        backgroundColor: Colors.red.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _isTyping) return; // Block if AI is responding

    final userMessage = ChatMessage(
      text: _messageController.text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
      _messageCount++;
    });

    _conversationHistory.add({
      'role': 'user',
      'content': userMessage.text,
    });

    if (_conversationHistory.length > 20) {
      _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();
    _recognizedText = ''; // Clear recognized text
    _scrollToBottom();
    _saveChatHistory();

    _generateAIResponse(messageText);
  }

  // Optimized AI response generation
  void _generateAIResponse(String userInput) async {
    try {
      String aiResponse;
      
      if (_isAIConfigured) {
        final isFirstMessage = _messageCount <= 1;
        
        if (isFirstMessage) {
          // Fastest possible first response - no profile loading, no history
          aiResponse = await AIService.generateResponse(
            userMessage: userInput,
            isTherapyMode: false,
            conversationHistory: [],
            userProfile: {},
          );
        } else {
          // Normal response with full context
          final userProfile = await AIService.getUserProfile();
          aiResponse = await AIService.generateResponse(
            userMessage: userInput,
            isTherapyMode: _isTherapyMode,
            conversationHistory: _conversationHistory.map((item) => {
              'role': item['role'].toString(),
              'content': item['content'].toString(),
            }).toList(),
            userProfile: userProfile,
          );
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        aiResponse = 'معذرت، سروس دستیاب نہیں ہے۔ کچھ دیر بعد کوشش کریں۔';
      }
      
      final aiMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _conversationHistory.add({
        'role': 'assistant',
        'content': aiResponse,
      });

      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });
      
      _scrollToBottom();
      _saveChatHistory();
      
    } catch (e) {
      print('Error generating AI response: $e');
      
      final fallbackMessage = ChatMessage(
        text: 'معذرت، کوئی مسئلہ پیش آیا ہے۔ مہربانی کر کے اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _isTyping = false;
        _messages.add(fallbackMessage);
      });
      
      _scrollToBottom();
      _saveChatHistory();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleTherapyMode() {
    setState(() {
      _isTherapyMode = !_isTherapyMode;
    });

    final modeMessage = ChatMessage(
      text: _isTherapyMode
        ? 'اب میں Therapy Mode میں ہوں - میں زیادہ تفصیل سے آپ کی بات سنوں گا اور thoughtful responses دوں گا۔'
        : 'اب میں Quick Q&A Mode میں ہوں - میں مختصر اور direct جوابات دوں گا تاکہ آپ کو فوری مدد مل سکے۔',
      isUser: false,
      timestamp: DateTime.now(),
      isSystemMessage: true,
    );

    setState(() {
      _messages.add(modeMessage);
    });
    
    _saveChatHistory();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildProfileDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat.png',
              fit: BoxFit.cover,
            ),
          ),
          
          Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: _profileImagePath.isNotEmpty
                          ? ClipOval(
                              child: Image.file(
                                File(_profileImagePath),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                      ),
                    ),
                    
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'رستہ - آپ کا تھراپسٹ',
                            style: GoogleFonts.notoNaskhArabic(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isAIConfigured ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isAIConfigured ? 'Professional Mode' : 'Basic Mode',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    GestureDetector(
                      onTap: _showModeMenu,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isTherapyMode 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isTherapyMode ? Colors.green : Colors.blue,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isTherapyMode ? Icons.psychology : Icons.quiz,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isTherapyMode ? 'Therapy' : 'Quick',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _buildChatArea(),
              ),
              _buildEnhancedMessageInput(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        
        final message = _messages[index];
        return _buildEnhancedMessageBubble(message, index);
      },
    );
  }

  Widget _buildEnhancedMessageBubble(ChatMessage message, int index) {
    final isLastAiMessage = !message.isUser && 
        (index == _messages.length - 1 || 
         (index < _messages.length - 1 && _messages[index + 1].isUser));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: message.isSystemMessage == true 
                  ? Colors.orange.withOpacity(0.8)
                  : Colors.green.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isSystemMessage == true 
                  ? Icons.info_outline
                  : Icons.psychology,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            
            // TTS button for AI messages
            if (!message.isSystemMessage!)
              GestureDetector(
                onTap: () => _speakMessage(message.text),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _isSpeaking && isLastAiMessage
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isSpeaking && isLastAiMessage
                        ? Colors.blue
                        : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _isSpeaking && isLastAiMessage 
                      ? _voiceAnimationController 
                      : _typingController,
                    builder: (context, child) {
                      return Icon(
                        _isSpeaking && isLastAiMessage 
                          ? Icons.volume_up 
                          : Icons.volume_up_outlined,
                        size: 14,
                        color: _isSpeaking && isLastAiMessage
                          ? Colors.blue.withOpacity(0.7 + _voiceAnimationController.value * 0.3)
                          : Colors.white.withOpacity(0.7),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser
                  ? Colors.blue.withOpacity(0.8)
                  : message.isSystemMessage == true
                    ? Colors.orange.withOpacity(0.8)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.notoNaskhArabic(
                      fontSize: 16,
                      color: message.isUser 
                        ? Colors.white 
                        : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: message.isUser 
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                shape: BoxShape.circle,
                image: _profileImagePath.isNotEmpty
                  ? DecorationImage(
                      image: FileImage(File(_profileImagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: _profileImagePath.isEmpty
                ? Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isFirstMessage = _messageCount <= 1;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
                const SizedBox(width: 8),
                Text(
                  isFirstMessage 
                    ? 'پہلا جواب تیار کر رہا ہے...'
                    : 'جواب لکھ رہا ہے...',
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = (_typingController.value + delay) % 1.0;
        final opacity = (animationValue < 0.5) 
          ? (animationValue * 2) 
          : ((1.0 - animationValue) * 2);
        
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildEnhancedMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Voice recognition indicator
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _voiceAnimationController,
                    builder: (context, child) {
                      return Icon(
                        Icons.mic,
                        color: Colors.green.withOpacity(0.5 + _voiceAnimationController.value * 0.5),
                        size: 16,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _recognizedText.isEmpty ? 'سن رہا ہوں...' : _recognizedText,
                    style: GoogleFonts.notoNaskhArabic(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          Row(
            children: [
              // Voice input button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _isTyping ? null : (_isListening ? _stopListening : _startListening),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isTyping 
                        ? Colors.grey.withOpacity(0.3)
                        : _isListening 
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isTyping 
                          ? Colors.grey.withOpacity(0.5)
                          : _isListening 
                            ? Colors.red.withOpacity(0.5)
                            : Colors.green.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _isListening ? _voiceAnimationController : _typingController,
                      builder: (context, child) {
                        return Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: _isTyping 
                            ? Colors.grey.withOpacity(0.7)
                            : _isListening 
                              ? Colors.red.withOpacity(0.7 + _voiceAnimationController.value * 0.3)
                              : Colors.green.withOpacity(0.8),
                          size: 20,
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_isTyping ? 0.5 : 0.95),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: _isAIConfigured && !_isTyping, // Disable when AI is responding
                    decoration: InputDecoration(
                      hintText: _isTyping
                        ? 'AI جواب لکھ رہا ہے...'
                        : _isAIConfigured 
                          ? (_messageCount <= 1 
                              ? 'پہلے مختصر پیغام لکھیں...' 
                              : 'اپنے احساسات یہاں لکھیں...')
                          : 'سروس دستیاب نہیں...',
                      hintStyle: GoogleFonts.notoNaskhArabic(
                        fontSize: 14,
                        color: _isTyping ? Colors.grey : Colors.black54,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.notoNaskhArabic(
                      fontSize: 16,
                      color: _isTyping ? Colors.grey : Colors.black87,
                    ),
                    maxLines: null,
                    textDirection: TextDirection.rtl,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: (_isAIConfigured && !_isTyping) ? _sendMessage : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (_isAIConfigured && !_isTyping)
                      ? Colors.green 
                      : Colors.grey.withOpacity(0.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isTyping
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final isPM = hour >= 12;
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute ${isPM ? 'PM' : 'AM'}';
  }

  // Keep all your existing drawer and dialog methods exactly the same
  Widget _buildProfileDrawer() {
    return Drawer(
      backgroundColor: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.greenAccent.withOpacity(0.8),
                  backgroundImage: _profileImagePath.isNotEmpty
                    ? FileImage(File(_profileImagePath))
                    : null,
                  child: _profileImagePath.isEmpty 
                    ? Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'آپ کا پیشہ ور AI تھراپسٹ',
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isAIConfigured ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isAIConfigured ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _isAIConfigured ? 'Professional Mode Active' : 'Basic Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _isAIConfigured ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  titleUrdu: 'پروفائل تبدیل کریں',
                  onTap: () => _showEditProfileDialog(),
                ),
                _buildDrawerItem(
                  icon: Icons.mood,
                  title: 'Mood Tracking',
                  titleUrdu: 'موڈ کی نگرانی',
                  onTap: () => _showMoodChart(),
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: 'Session History',
                  titleUrdu: 'سیشن کی تاریخ',
                  onTap: () => _showSessionHistory(),
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About Rastah',
                  titleUrdu: 'رستہ کے بارے میں',
                  onTap: () => _showAboutDialog(),
                ),
                _buildDrawerItem(
                  icon: Icons.report_outlined,
                  title: 'Report Issue',
                  titleUrdu: 'مسئلہ کی رپورٹ',
                  onTap: () => _reportIssue(),
                ),
                _buildDrawerItem(
                  icon: Icons.delete_outline,
                  title: 'Clear All Data',
                  titleUrdu: 'تمام ڈیٹا صاف کریں',
                  onTap: () => _showClearDataDialog(),
                  isDestructive: true,
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'رستہ - آپ کا ہمسفر\n${AIService.getModelInfo()}',
              style: GoogleFonts.notoNaskhArabic(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String titleUrdu,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.white,
        size: 24,
      ),
      title: Text(
        titleUrdu,
        style: GoogleFonts.notoNaskhArabic(
          fontSize: 16,
          color: isDestructive ? Colors.redAccent : Colors.white,
        ),
      ),
      subtitle: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: isDestructive 
            ? Colors.redAccent.withOpacity(0.7) 
            : Colors.white.withOpacity(0.6),
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  // Add all your existing dialog methods (showModeMenu, showEditProfileDialog, etc.) here
  // They remain exactly the same as in your original code

  void _showModeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'موڈ منتخب کریں',
              style: GoogleFonts.notoNaskhArabic(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Therapy Mode
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.green),
              ),
              title: Text(
                'Therapy Mode',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'تفصیلی اور گہری تھراپی - زیادہ وقت، بہتر سمجھ',
                style: GoogleFonts.notoNaskhArabic(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              trailing: _isTherapyMode 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
              onTap: () {
                if (!_isTherapyMode) {
                  Navigator.of(context).pop();
                  _toggleTherapyMode();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            
            const Divider(color: Colors.white24),
            
            // Quick Mode
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.quiz, color: Colors.blue),
              ),
              title: Text(
                'Quick Q&A Mode',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'فوری اور مختصر جوابات - تیز مدد کے لیے',
                style: GoogleFonts.notoNaskhArabic(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              trailing: !_isTherapyMode 
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : null,
              onTap: () {
                if (_isTherapyMode) {
                  Navigator.of(context).pop();
                  _toggleTherapyMode();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Add all other dialog methods exactly as they were in your original code
  // _showEditProfileDialog(), _showMoodChart(), _showSessionHistory(), 
  // _showAboutDialog(), _reportIssue(), _showClearDataDialog(), _checkFirstTimeUser()

  void _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownWelcome = prefs.getBool('first_time_welcome_shown') ?? false;
    
    if (!hasShownWelcome) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _showFirstTimeWelcome();
    }
  }

  void _showFirstTimeWelcome() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'رستہ میں خوش آمدید! 🎉',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'میں آپ کا پیشہ ور AI تھراپسٹ ہوں۔ آپ سے کھل کر بات کر سکتے ہیں۔ میں آپ کا موڈ ٹریک کروں گا اور مکمل طور پر محفوظ ہوں۔',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 16,
            color: Colors.white,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('first_time_welcome_shown', true);
              Navigator.of(context).pop();
            },
            child: Text(
              'چلیں شروع کرتے ہیں! 🚀',
              style: GoogleFonts.notoNaskhArabic(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _userName);
    final prefs = await SharedPreferences.getInstance();
    int currentAge = prefs.getInt('age') ?? 20;
    int currentStressLevel = prefs.getInt('stress_level') ?? 5;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'پروفائل تبدیل کریں',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'آپ کا نام',
                  labelStyle: GoogleFonts.notoNaskhArabic(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.greenAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: GoogleFonts.notoNaskhArabic(color: Colors.white),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              
              Text(
                'عمر: $currentAge سال',
                style: GoogleFonts.notoNaskhArabic(color: Colors.white, fontSize: 16),
              ),
              Slider(
                value: currentAge.toDouble(),
                min: 15,
                max: 40,
                divisions: 25,
                activeColor: Colors.greenAccent,
                inactiveColor: Colors.white.withOpacity(0.3),
                onChanged: (value) {
                  setDialogState(() {
                    currentAge = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),
              
              Text(
                'تناؤ کی سطح: $currentStressLevel/10',
                style: GoogleFonts.notoNaskhArabic(color: Colors.white, fontSize: 16),
              ),
              Slider(
                value: currentStressLevel.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: currentStressLevel <= 3 
                  ? Colors.green 
                  : currentStressLevel <= 6 
                    ? Colors.orange 
                    : Colors.red,
                inactiveColor: Colors.white.withOpacity(0.3),
                onChanged: (value) {
                  setDialogState(() {
                    currentStressLevel = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _profileImagePath = image.path;
                    });
                    await prefs.setString('profile_image', image.path);
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 2),
                  ),
                  child: _profileImagePath.isNotEmpty
                    ? ClipOval(
                        child: Image.file(
                          File(_profileImagePath),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.add_a_photo,
                        color: Colors.greenAccent,
                        size: 30,
                      ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'منسوخ کریں',
              style: GoogleFonts.notoNaskhArabic(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              await prefs.setString('name', nameController.text.trim());
              await prefs.setInt('age', currentAge);
              await prefs.setInt('stress_level', currentStressLevel);
              
              setState(() {
                _userName = nameController.text.trim().isNotEmpty 
                  ? nameController.text.trim() 
                  : 'دوست';
              });
              
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'پروفائل اپ ڈیٹ ہو گئی',
                    style: GoogleFonts.notoNaskhArabic(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'محفوظ کریں',
              style: GoogleFonts.notoNaskhArabic(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodChart() async {
    final moodData = await AIService.getMoodHistory();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'موڈ ٹریکنگ - پچھلے 30 دن',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: moodData.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mood,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ابھی تک کوئی موڈ ڈیٹا نہیں ہے',
                      style: GoogleFonts.notoNaskhArabic(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'آج کا موڈ شامل کریں:',
                      style: GoogleFonts.notoNaskhArabic(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        {'emoji': '😰', 'score': 2, 'label': 'پریشان'},
                        {'emoji': '😔', 'score': 4, 'label': 'اداس'},
                        {'emoji': '😐', 'score': 5, 'label': 'عام'},
                        {'emoji': '😊', 'score': 7, 'label': 'خوش'},
                        {'emoji': '😄', 'score': 9, 'label': 'بہت خوش'},
                      ].map((mood) => GestureDetector(
                        onTap: () async {
                          await AIService.updateUserMood(
                            mood['emoji'] as String,
                            mood['score'] as int,
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'موڈ محفوظ ہو گیا: ${mood['emoji']}',
                                style: GoogleFonts.notoNaskhArabic(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(mood['emoji'] as String, style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(
                                mood['label'] as String,
                                style: GoogleFonts.notoNaskhArabic(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: moodData.length,
                itemBuilder: (context, index) {
                  final entries = moodData.entries.toList()
                    ..sort((a, b) => b.key.compareTo(a.key));
                  
                  if (index >= entries.length) return const SizedBox();
                  
                  final entry = entries[index];
                  final date = DateTime.parse(entry.key);
                  final mood = entry.value;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(mood['emoji'], style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${date.day}/${date.month}/${date.year}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'اسکور: ${mood['score']}/10',
                                style: GoogleFonts.notoNaskhArabic(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ٹھیک ہے',
              style: GoogleFonts.notoNaskhArabic(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistory = prefs.getString('chat_history');
    final sessions = <Map<String, String>>[];
    
    if (chatHistory != null) {
      final List<dynamic> messages = json.decode(chatHistory);
      final messagesByDate = <String, List<dynamic>>{};
      
      for (final message in messages) {
        final timestamp = DateTime.parse(message['timestamp']);
        final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        
        if (!messagesByDate.containsKey(dateKey)) {
          messagesByDate[dateKey] = [];
        }
        messagesByDate[dateKey]!.add(message);
      }
      
      messagesByDate.forEach((date, dayMessages) {
        final userMessages = dayMessages.where((msg) => msg['isUser'] == true).toList();
        if (userMessages.isNotEmpty) {
          final firstMessage = userMessages.first['text'] as String;
          final summary = firstMessage.length > 50 
            ? '${firstMessage.substring(0, 50)}...'
            : firstMessage;
          
          sessions.add({
            'date': date,
            'summary': summary,
            'messageCount': userMessages.length.toString(),
          });
        }
      });
    }
    
    sessions.sort((a, b) => b['date']!.compareTo(a['date']!));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'سیشن کی تاریخ',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: sessions.isEmpty
            ? Center(
                child: Text(
                  'ابھی تک کوئی سیشن نہیں ہے',
                  style: GoogleFonts.notoNaskhArabic(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final date = DateTime.parse(session['date']!);
                  final formattedDate = '${date.day}/${date.month}/${date.year}';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate,
                              style: GoogleFonts.poppins(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${session['messageCount']} پیغامات',
                              style: GoogleFonts.notoNaskhArabic(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session['summary']!,
                          style: GoogleFonts.notoNaskhArabic(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ٹھیک ہے',
              style: GoogleFonts.notoNaskhArabic(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'رستہ کے بارے میں',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'رستہ پاکستانی طلباء کے لیے خصوصی طور پر ڈیزائن کیا گیا پیشہ ور AI تھراپسٹ ہے۔ یہ آپ کو جذباتی سپورٹ فراہم کرتا ہے اور cultural context کو سمجھتے ہوئے آپ کی مدد کرتا ہے۔',
            style: GoogleFonts.notoNaskhArabic(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ٹھیک ہے',
              style: GoogleFonts.notoNaskhArabic(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reportIssue() async {
    const email = 'saadnizami114@gmail.com';
    final subject = 'Rastah App - Professional Support';
    final body = 'Describe your issue or feedback for professional improvement...';
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        Clipboard.setData(const ClipboardData(text: email));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email copied: $email',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      Clipboard.setData(const ClipboardData(text: email));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email copied: $email',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تمام ڈیٹا صاف کریں',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'یہ تمام چیٹ ہسٹری، موڈ ڈیٹا اور سیٹنگز کو صاف کر دے گا۔ یہ عمل واپس نہیں ہو سکتا۔',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 14,
            color: Colors.white,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'منسوخ کریں',
              style: GoogleFonts.notoNaskhArabic(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              setState(() {
                _messages.clear();
                _conversationHistory.clear();
                _userName = 'دوست';
                _profileImagePath = '';
                _messageCount = 0;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تمام ڈیٹا صاف کر دیا گیا',
                    style: GoogleFonts.notoNaskhArabic(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'صاف کریں',
              style: GoogleFonts.notoNaskhArabic(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool? isSystemMessage;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isSystemMessage = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isSystemMessage': isSystemMessage ?? false,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      isSystemMessage: json['isSystemMessage'] ?? false,
    );
  }
}