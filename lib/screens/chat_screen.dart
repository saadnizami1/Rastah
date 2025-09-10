import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import '../services/ai_service.dart';
import '../chat_state_manager.dart';
import '../widgets/profile_panel.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Controllers & Focus
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late AnimationController _profileController;
  late AnimationController _typingController;
  late AnimationController _voiceController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _profileSlideAnimation;
  late Animation<double> _typingAnimation;
  late Animation<double> _voiceAnimation;

  // State
  bool _showProfilePanel = false;
  bool _isKeyboardVisible = false;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupObservers();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Slide animation for messages
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Fade animation for UI elements
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    // Bounce animation for send button
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));

    // Profile panel animation
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _profileSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _profileController, curve: Curves.easeOutCubic));

    // Typing animation
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _typingController, curve: Curves.easeInOut));

    // Voice button animation
    _voiceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _voiceAnimation = Tween<double>(begin: 0.0, end: 8.0)
        .animate(CurvedAnimation(parent: _voiceController, curve: Curves.easeInOut));

    // kick things off
    _fadeController.forward();
    _slideController.forward();
  }

  void _setupObservers() {
    WidgetsBinding.instance.addObserver(this);
    _inputFocusNode.addListener(_onFocusChanged);
    _messageController.addListener(_onTextChanged);
  }

  void _initializeApp() async {
    final stateManager = Provider.of<ChatStateManager>(context, listen: false);
    await stateManager.initialize();
    // Default to therapist mode (logic unchanged)
    if (stateManager.currentMode != 'therapist') {
      await stateManager.changeMode('therapist');
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isKeyboardVisible = _inputFocusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to update send button state
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    _profileController.dispose();
    _typingController.dispose();
    _voiceController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _autoScrollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Bounce animation for send button
    _bounceController.forward().then((_) => _bounceController.reverse());

    final stateManager = Provider.of<ChatStateManager>(context, listen: false);

    // Clear input immediately for better UX
    _messageController.clear();

    // Send message (logic unchanged)
    await stateManager.sendMessage(message);

    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _toggleVoiceInput() async {
    final stateManager = Provider.of<ChatStateManager>(context, listen: false);

    HapticFeedback.mediumImpact();
    
    // Animate voice button
    if (stateManager.isListening) {
      _voiceController.reverse();
      await stateManager.stopListening();
      // Auto-send the recorded message
      if (_messageController.text.trim().isNotEmpty) {
        _sendMessage();
      }
    } else {
      _voiceController.forward();
      final result = await stateManager.startListening();
      if (result.isNotEmpty) {
        _messageController.text = result;
        setState(() {}); // Update UI
      }
    }
  }

  void _speakMessage(String text) async {
    final stateManager = Provider.of<ChatStateManager>(context, listen: false);
    HapticFeedback.lightImpact();
    
    if (stateManager.isSpeaking) {
      // Stop TTS if already speaking
      await stateManager.stopSpeaking();
    } else {
      // Start TTS
      await stateManager.speakText(text);
    }
  }

  void _toggleProfilePanel() {
    setState(() {
      _showProfilePanel = !_showProfilePanel;
    });

    if (_showProfilePanel) {
      _profileController.forward();
    } else {
      _profileController.reverse();
    }

    HapticFeedback.mediumImpact();
  }

  void _showModeSelector() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModeSelector(),
    );
  }

  void _quickSendMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9F5F1), Color(0xFFF8FAF9)],
          ),
        ),
        child: Consumer<ChatStateManager>(
          builder: (context, stateManager, child) {
            // Start / stop typing animation
            if (stateManager.isTyping && !_typingController.isAnimating) {
              _typingController.repeat();
            } else if (!stateManager.isTyping && _typingController.isAnimating) {
              _typingController.stop();
              _typingController.reset();
            }

            return Stack(
              children: [
                // Full background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/chat.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // Main chat interface
                Column(
                  children: [
                    _buildAppBar(stateManager),
                    Expanded(
                      child: _buildMessagesList(stateManager),
                    ),
                    _buildInputArea(stateManager),
                  ],
                ),

                // Profile panel overlay
                if (_showProfilePanel) ...[
                  _buildProfileOverlay(),
                  _buildProfilePanel(stateManager),
                ],

                // Connection status overlay
                if (!stateManager.isConnected) _buildConnectionStatus(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===================== APP BAR =====================
  Widget _buildAppBar(ChatStateManager stateManager) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.06),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Profile Button (moved to left)
                  GestureDetector(
                    onTap: _toggleProfilePanel,
                    child: Consumer<ChatStateManager>(
                      builder: (context, stateManager, child) {
                        final profilePic = stateManager.userProfile['profilePic'] ?? '';
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            image: profilePic.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(profilePic)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profilePic.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: Colors.black.withOpacity(0.55),
                                  size: 16,
                                )
                              : null,
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Welcome Image and App Name
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/welcome_img.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'رستہ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D63),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== MESSAGES LIST =====================
  Widget _buildMessagesList(ChatStateManager stateManager) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: stateManager.messages.isEmpty
              ? _buildEmptyState(stateManager)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: stateManager.messages.length + (stateManager.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == stateManager.messages.length) {
                      return _buildTypingIndicator();
                    }

                    final message = stateManager.messages[index];
                    return SlideTransition(
                      position: _slideAnimation,
                      child: _buildMessageBubble(
                        message.content,
                        message.isUser,
                        message.timestamp,
                        stateManager.isSpeaking,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  // ===================== EMPTY STATE =====================
  Widget _buildEmptyState(ChatStateManager stateManager) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2E7D63).withOpacity(0.10),
                        const Color(0xFF2E7D63).withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.psychology,
                      size: 54,
                      color: Color(0xFF2E7D63),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'آپ کا AI ${AIService.getAvailableModes()[stateManager.currentMode]?['name'] ?? 'تھراپسٹ'} یہاں ہے',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F5F4F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'کچھ بھی پوچھیں یا اپنا دل ہلکا کریں',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _buildSuggestedMessages(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedMessages() {
    final suggestions = [
      'السلام علیکم، کیا حال ہے؟ 👋',
      'آج کیسا دن تھا؟ 🌅',
      'کچھ پریشانی ہے؟ 💭',
      'کوئی تکنیک سکھائیں 📚',
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 32,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: suggestions.map((suggestion) {
          return GestureDetector(
            onTap: () => _quickSendMessage(suggestion),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: Color(0xFF2E7D63),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===================== MESSAGE BUBBLE =====================
  Widget _buildMessageBubble(
      String message, bool isUser, DateTime timestamp, bool isSpeaking) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/chaticon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: GestureDetector(
              onTap: !isUser ? () => _speakMessage(message) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF2E7D63), Color(0xFF1F5F4F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.42,
                      ),
                    ),
                    if (!isUser) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSpeaking ? Icons.volume_up : Icons.volume_off_outlined,
                            size: 16,
                            color: const Color(0xFF2E7D63).withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'سننے کے لیے ٹیپ کریں',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF2E7D63).withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            Consumer<ChatStateManager>(
              builder: (context, stateManager, child) {
                final profilePic = stateManager.userProfile['profilePic'] ?? '';
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    image: profilePic.isNotEmpty
                        ? DecorationImage(
                            image: FileImage(File(profilePic)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profilePic.isEmpty
                      ? Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 18,
                        )
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ===================== TYPING INDICATOR =====================
  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/chaticon.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _typingAnimation,
                      builder: (context, child) {
                        final delay = index * 0.3;
                        final animationValue =
                            ((_typingAnimation.value - delay) % 1.0).clamp(0.0, 1.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          child: Transform.translate(
                            offset: Offset(
                                0, -8 * (0.5 - (animationValue - 0.5).abs()) * 2),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D63).withOpacity(0.85),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== INPUT AREA =====================
  Widget _buildInputArea(ChatStateManager stateManager) {
    final hasText = _messageController.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 6,
          bottom: _isKeyboardVisible ? 4 : 8,
        ),
        child: Row(
          children: [
            // Voice input button
            GestureDetector(
              onTap: stateManager.canSendMessage ? _toggleVoiceInput : null,
              child: AnimatedBuilder(
                animation: _voiceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_voiceAnimation.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: stateManager.isListening
                            ? const Color(0xFF2E7D63)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: stateManager.isListening 
                              ? const Color(0xFF1F5F4F)
                              : Colors.black.withOpacity(0.08),
                          width: stateManager.isListening ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: stateManager.isListening 
                                ? const Color(0xFF2E7D63).withOpacity(0.3)
                                : Colors.black.withOpacity(0.07),
                            blurRadius: stateManager.isListening ? 15 : 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        stateManager.isListening ? Icons.mic : Icons.mic_none,
                        color: stateManager.isListening ? Colors.white : const Color(0xFF2E7D63),
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 8),

            // Text input
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 96),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _inputFocusNode,
                      decoration: InputDecoration(
                        hintText: 'اپنا پیغام یہاں لکھیں...',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.45),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        height: 1.42,
                      ),
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) =>
                          stateManager.canSendMessage && hasText ? _sendMessage() : null,
                      enabled: stateManager.canSendMessage,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            ScaleTransition(
              scale: _bounceAnimation,
              child: GestureDetector(
                onTap: stateManager.canSendMessage && hasText ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: stateManager.canSendMessage && hasText
                        ? const LinearGradient(
                            colors: [Color(0xFF2E7D63), Color(0xFF1F5F4F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: stateManager.canSendMessage && hasText
                        ? null
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.send,
                    color: stateManager.canSendMessage && hasText
                        ? Colors.white
                        : const Color(0xFF2E7D63),
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== PROFILE OVERLAY & PANEL =====================
  Widget _buildProfileOverlay() {
    return GestureDetector(
      onTap: _toggleProfilePanel,
      child: Container(
        color: Colors.black54,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildProfilePanel(ChatStateManager stateManager) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: SlideTransition(
        position: _profileSlideAnimation,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Material(
              color: Colors.white,
              child: ProfilePanel(
                stateManager: stateManager,
                onClose: _toggleProfilePanel,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== CONNECTION STATUS =====================
  Widget _buildConnectionStatus() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.signal_wifi_off, color: Colors.red[700], size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'انٹرنیٹ کنکشن نہیں ہے',
                  style: TextStyle(
                    color: Color(0xFF9A0000),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== MODE SELECTOR =====================
  Widget _buildModeSelector() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Card container with glass effect
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 46,
                        height: 5,
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'AI کا انداز منتخب کریں',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F5F4F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Consumer<ChatStateManager>(
                        builder: (context, stateManager, child) {
                          return Column(
                            children: AIService.getAvailableModes().entries.map((entry) {
                              final isSelected = entry.key == stateManager.currentMode;
                              return GestureDetector(
                                onTap: () {
                                  stateManager.changeMode(entry.key);
                                  Navigator.pop(context);
                                  HapticFeedback.selectionClick();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2E7D63).withOpacity(0.10)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2E7D63)
                                          : Colors.black.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(entry.value['emoji'] ?? '🤖',
                                          style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          entry.value['name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF1F5F4F)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF2E7D63),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
