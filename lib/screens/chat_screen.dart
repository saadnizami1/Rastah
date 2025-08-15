import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_service.dart';
import '../chat_helpers.dart';
import '../chat_state_manager.dart';
// import 'ai_service.dart'; // Import your enhanced AI service

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Map<String, String>> _conversations = [];
  String _currentMode = 'friend';
  bool _isTyping = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _showProfilePanel = false;
  Map<String, dynamic> _userProfile = {};
  List<Map<String, dynamic>> _conversationSummaries = [];
  Map<String, dynamic> _moodLogs = {};
  
  // Animation controllers
  late AnimationController _typingAnimationController;
  late AnimationController _profilePanelController;
  late AnimationController _messageAnimationController;
  
  // Animations
  late Animation<double> _typingAnimation;
  late Animation<Offset> _profilePanelAnimation;
  late Animation<double> _messageScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _initializeServices();
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _profilePanelController = AnimationController(
      duration: Duration(milliseconds: 350),
      vsync: this,
    );
    
    _messageAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: Curves.easeInOut),
    );
    
    _profilePanelAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _profilePanelController, curve: Curves.easeInOut));
    
    _messageScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageAnimationController, curve: Curves.elasticOut),
    );
  }

  void _initializeServices() async {
    await AIService.initializeTTS();
    await AIService.initializeSTT();
  }

  void _loadData() async {
    _userProfile = await AIService.getUserProfile();
    _conversationSummaries = await AIService.getConversationSummaries();
    _moodLogs = await AIService.getMoodLogs();
    setState(() {});
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _profilePanelController.dispose();
    _messageAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    AIService.stopSpeaking();
    AIService.stopListening();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _conversations.add({'role': 'user', 'content': message});
      _isTyping = true;
      _messageController.clear();
    });

    _typingAnimationController.repeat();
    _scrollToBottom();

    try {
      final response = await AIService.generateResponse(
        userMessage: message,
        mode: _currentMode,
        conversationHistory: _conversations,
        userProfile: _userProfile,
      );

      setState(() {
        _conversations.add({'role': 'assistant', 'content': response});
        _isTyping = false;
      });

      _typingAnimationController.stop();
      _messageAnimationController.forward().then((_) {
        _messageAnimationController.reset();
      });

      // Auto-save conversation summary
      await AIService.autoSaveConversationSummary(_conversations);
      await AIService.incrementChatCounter();

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _conversations.add({
          'role': 'assistant', 
          'content': 'معذرت، کوئی خرابی ہوئی ہے۔ براہ کرم دوبارہ کوشش کریں۔ 🔄'
        });
        _isTyping = false;
      });
      _typingAnimationController.stop();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startListening() async {
    if (_isListening) {
      await AIService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    
    try {
      final result = await AIService.listenToSpeech();
      if (result.isNotEmpty && !result.contains('خرابی') && !result.contains('دستیاب نہیں')) {
        _messageController.text = result;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('آواز سننے میں خرابی ہوئی')),
      );
    } finally {
      setState(() => _isListening = false);
    }
  }

  void _speakMessage(String text) async {
    if (_isSpeaking) {
      await AIService.stopSpeaking();
      setState(() => _isSpeaking = false);
      return;
    }

    setState(() => _isSpeaking = true);
    await AIService.speakText(text);
    setState(() => _isSpeaking = false);
  }

  void _toggleProfilePanel() {
    setState(() => _showProfilePanel = !_showProfilePanel);
    if (_showProfilePanel) {
      _profilePanelController.forward();
    } else {
      _profilePanelController.reverse();
    }
  }

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Mode منتخب کریں',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D63),
                    ),
                  ),
                  SizedBox(height: 15),
                  ...AIService.getAvailableModes().entries.map((mode) => 
                    _buildModeOption(
                      mode.key, 
                      mode.value['name']!, 
                      mode.value['emoji']!,
                    ),
                  ).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String modeKey, String modeName, String emoji) {
    bool isSelected = _currentMode == modeKey;
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _currentMode = modeKey);
            Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF2E7D63).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Color(0xFF2E7D63) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    modeName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Color(0xFF2E7D63) : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Color(0xFF2E7D63)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, String> message, int index) {
    bool isUser = message['role'] == 'user';
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2E7D63),
              child: Icon(Icons.psychology, color: Colors.white, size: 18),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF2E7D63) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['content']!,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (!isUser) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _speakMessage(message['content']!),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              _isSpeaking ? Icons.volume_off : Icons.volume_up,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: _userProfile['profilePic']?.isNotEmpty == true 
                  ? FileImage(File(_userProfile['profilePic'])) 
                  : null,
              child: _userProfile['profilePic']?.isEmpty != false 
                  ? Icon(Icons.person, color: Colors.grey[600], size: 18) 
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF2E7D63),
            child: Icon(Icons.psychology, color: Colors.white, size: 18),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    double delay = index * 0.2;
                    double animationValue = (_typingAnimation.value - delay).clamp(0.0, 1.0);
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.translate(
                        offset: Offset(0, -10 * (0.5 - (animationValue - 0.5).abs()) * 2),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(0xFF2E7D63),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePanel() {
    return SlideTransition(
      position: _profilePanelAnimation,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(-5, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                SizedBox(height: 30),
                _buildProfileSection('تفصیلات تبدیل کریں', Icons.edit, _showEditProfile),
                _buildProfileSection('میرا موڈ', Icons.mood, _showMoodTracker),
                _buildProfileSection('پچھلی گفتگو', Icons.history, _showPastConversations),
                _buildProfileSection('نئی گفتگو شروع کریں', Icons.add_comment, _startNewChat),
                _buildProfileSection('موڈ کی تاریخ', Icons.timeline, _showMoodLogs),
                _buildProfileSection('راستہ کے بارے میں', Icons.info, _showAboutRastah),
                _buildProfileSection('ڈیولپر کے بارے میں', Icons.person, _showAboutDeveloper),
                _buildProfileSection('تمام ڈیٹا صاف کریں', Icons.delete_forever, _showClearDataDialog, 
                  color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey[300],
              backgroundImage: _userProfile['profilePic']?.isNotEmpty == true 
                  ? FileImage(File(_userProfile['profilePic'])) 
                  : null,
              child: _userProfile['profilePic']?.isEmpty != false 
                  ? Icon(Icons.person, size: 40, color: Colors.grey[600]) 
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Text(
                  _userProfile['currentMood'] ?? '😐',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userProfile['name']?.isNotEmpty == true 
                    ? _userProfile['name'] 
                    : 'صارف',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D63),
                ),
              ),
              if (_userProfile['city']?.isNotEmpty == true)
                Text(
                  _userProfile['city'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              Text(
                'تناؤ: ${_userProfile['stressLevel'] ?? 5}/10',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _toggleProfilePanel,
          icon: Icon(Icons.close, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProfileSection(String title, IconData icon, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: color ?? Color(0xFF2E7D63), size: 24),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: color ?? Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileSheet(
        userProfile: _userProfile,
        onSave: (updatedProfile) {
          setState(() => _userProfile = updatedProfile);
          AIService.updateUserProfile(updatedProfile);
        },
      ),
    );
  }

  void _showMoodTracker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodTrackerSheet(
        userProfile: _userProfile,
        onUpdate: (mood, stress, lastCried) {
          setState(() {
            _userProfile['currentMood'] = mood;
            _userProfile['stressLevel'] = stress;
            if (lastCried != null) _userProfile['lastCried'] = lastCried.toIso8601String();
          });
          AIService.updateUserMood(mood, stress, lastCried: lastCried);
        },
      ),
    );
  }

  void _showPastConversations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PastConversationsSheet(summaries: _conversationSummaries),
    );
  }

  void _startNewChat() async {
    // Save current conversation summary if it has enough messages
    if (_conversations.where((msg) => msg['role'] == 'user').length >= 4) {
      final summary = await AIService.generateConversationSummary(_conversations);
      if (summary.isNotEmpty) {
        await AIService.saveConversationSummary(summary);
      }
    }
    
    setState(() {
      _conversations.clear();
    });
    
    await AIService.clearCurrentConversation();
    _loadData();
    _toggleProfilePanel();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('نئی گفتگو شروع کی گئی')),
    );
  }

  void _showMoodLogs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodLogsSheet(moodLogs: _moodLogs),
    );
  }

  void _showAboutRastah() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AboutRastahSheet(),
    );
  }

  void _showAboutDeveloper() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AboutDeveloperSheet(),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('تمام ڈیٹا صاف کریں؟'),
        content: Text('کیا آپ واقعی تمام ڈیٹا حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں ہو سکتا۔'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('منسوخ', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              await AIService.clearAllData();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف کریں', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/chat.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          
          // Main content
          Column(
            children: [
              // App bar
              SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Logo/Title
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(0xFF2E7D63),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.psychology, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'راستہ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D63),
                                  ),
                                ),
                                Text(
                                  AIService.getAvailableModes()[_currentMode]!['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Mode selector
                      InkWell(
                        onTap: _showModeSelector,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2E7D63).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFF2E7D63).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AIService.getAvailableModes()[_currentMode]!['emoji']!,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(width: 5),
                              Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E7D63), size: 20),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      // Profile button
                      InkWell(
                        onTap: _toggleProfilePanel,
                        borderRadius: BorderRadius.circular(20),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _userProfile['profilePic']?.isNotEmpty == true 
                              ? FileImage(File(_userProfile['profilePic'])) 
                              : null,
                          child: _userProfile['profilePic']?.isEmpty != false 
                              ? Icon(Icons.person, color: Colors.grey[600], size: 20) 
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  itemCount: _conversations.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _conversations.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildChatBubble(_conversations[index], index);
                  },
                ),
              ),
              
              // Input area
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Voice input button
                      Container(
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.red : Color(0xFF2E7D63),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _startListening,
                          icon: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 12),
                      
                      // Text input
                      Expanded(
  child: Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: TextField(
      controller: _messageController,
      decoration: InputDecoration(
        hintText: 'یہاں لکھیں...',
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      maxLines: null,
      textDirection: TextDirection.rtl,  // ✅ Changed from LTR to rtl (for Urdu text)
      onSubmitted: (_) => _sendMessage(),
    ),
  ),
),
                      
                      SizedBox(width: 12),
                      
                      // Send button
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF2E7D63),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Profile panel overlay
          if (_showProfilePanel) ...[
            // Background overlay
            GestureDetector(
              onTap: _toggleProfilePanel,
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
            // Profile panel
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildProfilePanel(),
            ),
          ],
        ],
      ),
    );
  }
}

// Additional widget classes for modular components

class EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final Function(Map<String, dynamic>) onSave;

  EditProfileSheet({required this.userProfile, required this.onSave});

  @override
  _EditProfileSheetState createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _cityController;
  String? _profilePicPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile['name'] ?? '');
    _ageController = TextEditingController(
      text: widget.userProfile['age']?.toString() ?? '',
    );
    _cityController = TextEditingController(text: widget.userProfile['city'] ?? '');
    _profilePicPath = widget.userProfile['profilePic'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'تفصیلات تبدیل کریں',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D63),
              ),
            ),
            SizedBox(height: 30),
            
            // Profile picture
            Center(
              child: GestureDetector(
                onTap: _pickProfilePicture,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profilePicPath?.isNotEmpty == true 
                          ? FileImage(File(_profilePicPath!)) 
                          : null,
                      child: _profilePicPath?.isEmpty != false 
                          ? Icon(Icons.person, size: 50, color: Colors.grey[600]) 
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF2E7D63),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Form fields
            _buildTextField('نام', _nameController, Icons.person),
            SizedBox(height: 20),
            _buildTextField('عمر', _ageController, Icons.calendar_today, isNumber: true),
            SizedBox(height: 20),
            _buildTextField('شہر', _cityController, Icons.location_city),
            
            Spacer(),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D63),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'محفوظ کریں',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, 
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF2E7D63)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF2E7D63)),
            ),
          ),
        ),
      ],
    );
  }

  void _pickProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _profilePicPath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تصویر منتخب کرنے میں خرابی ہوئی')),
      );
    }
  }

  void _saveProfile() {
    final updatedProfile = Map<String, dynamic>.from(widget.userProfile);
    updatedProfile['name'] = _nameController.text.trim();
    updatedProfile['city'] = _cityController.text.trim();
    updatedProfile['profilePic'] = _profilePicPath ?? '';
    
    if (_ageController.text.trim().isNotEmpty) {
      updatedProfile['age'] = int.tryParse(_ageController.text.trim());
    }
    
    widget.onSave(updatedProfile);
    Navigator.pop(context);
  }
}

class MoodTrackerSheet extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final Function(String, int, DateTime?) onUpdate;

  MoodTrackerSheet({required this.userProfile, required this.onUpdate});

  @override
  _MoodTrackerSheetState createState() => _MoodTrackerSheetState();
}

class _MoodTrackerSheetState extends State<MoodTrackerSheet> {
  String _selectedMood = '😐';
  int _stressLevel = 5;
  DateTime? _lastCried;

  final List<String> _moods = ['😄', '😊', '😐', '😔', '😠', '😰', '😴'];
  final Map<String, String> _moodLabels = {
    '😄': 'بہت خوش',
    '😊': 'خوش',
    '😐': 'عام',
    '😔': 'اداس',
    '😠': 'ناراض',
    '😰': 'پریشان',
    '😴': 'تھکا ہوا',
  };

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.userProfile['currentMood'] ?? '😐';
    _stressLevel = widget.userProfile['stressLevel'] ?? 5;
    
    if (widget.userProfile['lastCried'] != null) {
      try {
        _lastCried = DateTime.parse(widget.userProfile['lastCried']);
      } catch (e) {
        _lastCried = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'آپ کا موڈ کیسا ہے؟',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D63),
              ),
            ),
            SizedBox(height: 30),
            
            // Mood selector
            Text(
              'موجودہ موڈ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 15),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: _moods.map((mood) => GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedMood == mood 
                        ? Color(0xFF2E7D63).withOpacity(0.1) 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedMood == mood 
                          ? Color(0xFF2E7D63) 
                          : Colors.grey[300]!,
                      width: _selectedMood == mood ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(mood, style: TextStyle(fontSize: 30)),
                      SizedBox(height: 5),
                      Text(
                        _moodLabels[mood]!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedMood == mood 
                              ? Color(0xFF2E7D63) 
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
            
            SizedBox(height: 30),
            
            // Stress level
            Text(
              'تناؤ کی سطح: $_stressLevel/10',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 15),
            Slider(
              value: _stressLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Color(0xFF2E7D63),
              onChanged: (value) => setState(() => _stressLevel = value.round()),
            ),
            
            SizedBox(height: 30),
            
            // Last cried
            Text(
              'آخری بار کب روئے؟',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _lastCried != null 
                        ? DateFormat('dd/MM/yyyy').format(_lastCried!)
                        : 'کوئی ریکارڈ نہیں',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                TextButton(
                  onPressed: _selectLastCriedDate,
                  child: Text('تبدیل کریں'),
                ),
              ],
            ),
            
            Spacer(),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onUpdate(_selectedMood, _stressLevel, _lastCried);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D63),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'محفوظ کریں',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLastCriedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastCried ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _lastCried = picked);
    }
  }
}

class PastConversationsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> summaries;

  PastConversationsSheet({required this.summaries});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'پچھلی گفتگو',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D63),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: summaries.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 20),
                        Text(
                          'ابھی تک کوئی گفتگو محفوظ نہیں ہوئی',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: summaries.length,
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.chat, color: Color(0xFF2E7D63), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  summary['day'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D63),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  summary['time'] ?? '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              summary['summary'] ?? '',
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                            SizedBox(height: 8),
                            Text(
                              summary['date'] ?? '',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MoodLogsSheet extends StatelessWidget {
  final Map<String, dynamic> moodLogs;

  MoodLogsSheet({required this.moodLogs});

  @override
  Widget build(BuildContext context) {
    final sortedLogs = moodLogs.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'موڈ کی تاریخ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D63),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sortedLogs.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timeline, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 20),
                        Text(
                          'ابھی تک کوئی موڈ ریکارڈ نہیں ہوا',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sortedLogs.length,
                    itemBuilder: (context, index) {
                      final entry = sortedLogs[index];
                      final date = entry.key;
                      final log = entry.value;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Text(
                              log['mood'] ?? '😐',
                              style: TextStyle(fontSize: 30),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D63),
                                    ),
                                  ),
                                  Text(
                                    'تناؤ: ${log['stressLevel']}/10',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  if (log['keywords'] != null && log['keywords'].isNotEmpty)
                                    Text(
                                      log['keywords'].join(', '),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStressColor(log['stressLevel'] ?? 5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStressColor(int stressLevel) {
    if (stressLevel <= 3) return Colors.green;
    if (stressLevel <= 6) return Colors.orange;
    return Colors.red;
  }
}

class AboutRastahSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF2E7D63),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.psychology, color: Colors.white, size: 40),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'راستہ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D63),
                    ),
                  ),
                  Text(
                    'ذہنی صحت کا معاون',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'راستہ کیا ہے؟',
                      'راستہ ایک AI پر مبنی ذہنی صحت کا معاون ہے جو آپ کو مشکل وقت میں سہارا دیتا ہے۔ یہ مختلف انداز میں بات کر سکتا ہے - دوست کی طرح، تھراپسٹ کی طرح، یا بزرگ کی طرح۔'
                    ),
                    _buildSection(
                      'رازداری کی پالیسی',
                      '• آپ کی گفتگو آپ کے فون میں محفوظ ہے\n• ہم آپ کا ڈیٹا کسی کے ساتھ شیئر نہیں کرتے\n• آپ جب چاہیں اپنا ڈیٹا حذف کر سکتے ہیں\n• صرف OpenAI کی API استعمال ہوتی ہے جوابات کے لیے'
                    ),
                    _buildSection(
                      'اہم نوٹ',
                      '• یہ پیشہ ورانہ علاج کا متبادل نہیں ہے\n• ہنگامی حالات میں فوری طور پر ڈاکٹر سے رابطہ کریں\n• یہ صرف ابتدائی مدد کے لیے ہے\n• ہم کسی نقصان کے ذمہ دار نہیں ہیں'
                    ),
                    _buildSection(
                      'تکنیکیں',
                      'راستہ آپ کو یہ تکنیکیں سکھاتا ہے:\n• Pomodoro Technique - بہتر توجہ کے لیے\n• Deep Breathing - تناؤ کم کرنے کے لیے\n• Self-talk Reframes - مثبت سوچ کے لیے\n• Impulse Control - غصے پر قابو کے لیے'
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D63),
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutDeveloperSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF2E7D63),
              child: Text(
                'SN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Saad Nizami',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D63),
              ),
            ),
            Text(
              '18 سال، لاہور سے',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'میں نے دیکھا ہے کہ پاکستان میں ذہنی صحت کو بہت نادیدہ کیا جاتا ہے۔ لوگ ڈپریشن، تناؤ، اور دوسرے ذہنی مسائل سے خاموشی سے لڑتے ہیں۔ میں نے راستہ بنایا تاکہ میرے ہم وطنوں کو ابتدائی مدد مل سکے۔\n\nیہ پیشہ ورانہ علاج کا متبادل نہیں ہے، لیکن یہ آپ کو بہتر محسوس کرانے میں مدد کر سکتا ہے۔',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey[700],
                    
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'رابطہ کریں',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D63),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildContactButton(
                      'GitHub',
                      Icons.code,
                      'https://github.com/saadnizami',
                    ),
                    _buildContactButton(
                      'LinkedIn',
                      Icons.business,
                      'https://linkedin.com/in/saadnizami',
                    ),
                    _buildContactButton(
                      'Email',
                      Icons.email,
                      'mailto:saadnizami.dev@gmail.com',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(String title, IconData icon, String url) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: () => _launchURL(url),
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2E7D63),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}