import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state_manager.dart';
import '../../models/study_session.dart';
import '../../utils/theme.dart';
import '../../utils/localization.dart';

class FloatingTutor extends StatefulWidget {
  final VoidCallback onClose;
  final StudySession? session;

  const FloatingTutor({
    super.key,
    required this.onClose,
    this.session,
  });

  @override
  State<FloatingTutor> createState() => _FloatingTutorState();
}

class _FloatingTutorState extends State<FloatingTutor>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isExpanded = false;
  bool _isFullScreen = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _slideController.forward();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _messageController.clear();
    
    final appState = Provider.of<AppStateManager>(context, listen: false);
    await appState.sendChatMessage(message);
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _close() async {
    await _slideController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        final isUrdu = appState.currentLanguage == 'ur';
        
        return SlideTransition(
          position: _slideAnimation,
          child: _isFullScreen 
              ? _buildFullScreenTutor(appState, isUrdu)
              : _buildFloatingTutor(appState, isUrdu),
        );
      },
    );
  }

  Widget _buildFloatingTutor(AppStateManager appState, bool isUrdu) {
    return Positioned(
      top: 100,
      right: 16,
      bottom: 120,
      width: _isExpanded ? 320 : 60,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(_isExpanded ? 16 : 30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _isExpanded 
            ? _buildExpandedTutor(appState, isUrdu)
            : _buildMinimizedTutor(isUrdu),
      ),
    );
  }

  Widget _buildMinimizedTutor(bool isUrdu) {
  return Consumer<AppStateManager>(
    builder: (context, appState, child) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentColor,
                  AppTheme.accentColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 28,
                ),
                
                // Notification dot if there are new messages
                if (appState.chatMessages.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
  Widget _buildExpandedTutor(AppStateManager appState, bool isUrdu) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.translate('ai_tutor', isUrdu ? 'ur' : 'en'),
                        style: isUrdu 
                            ? AppTheme.urduBody.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentColor,
                              )
                            : AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                color: AppTheme.accentColor,
                              ),
                      ),
                      Text(
                        isUrdu ? 'آن لائن' : 'Online',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _toggleFullScreen,
                      icon: Icon(
                        Icons.fullscreen,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleExpanded,
                      icon: Icon(
                        Icons.minimize,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: _close,
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Chat area
          Expanded(
            child: _buildChatArea(appState, isUrdu),
          ),
          
          // Input area
          _buildInputArea(appState, isUrdu),
        ],
      ),
    );
  }

  Widget _buildFullScreenTutor(AppStateManager appState, bool isUrdu) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _toggleFullScreen,
                      icon: Icon(
                        Icons.fullscreen_exit,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.translate('ai_tutor', isUrdu ? 'ur' : 'en'),
                            style: isUrdu 
                                ? AppTheme.urduBody.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  )
                                : AppTheme.lightTheme.textTheme.titleMedium,
                          ),
                          if (widget.session != null)
                            Text(
                              isUrdu 
                                  ? '${widget.session!.subjectNameUrdu} میں مدد'
                                  : 'Helping with ${widget.session!.subjectName}',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    IconButton(
                      onPressed: _close,
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat area
              Expanded(
                child: _buildChatArea(appState, isUrdu),
              ),
              
              // Input area
              _buildInputArea(appState, isUrdu),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea(AppStateManager appState, bool isUrdu) {
    final messages = appState.chatMessages;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: messages.isEmpty 
          ? _buildWelcomeMessage(isUrdu)
          : ListView.builder(
              controller: _chatScrollController,
              itemCount: messages.length + (appState.isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return _buildTypingIndicator();
                }
                
                final message = messages[index];
                final isUser = message['role'] == 'user';
                
                return _buildChatBubble(
                  message['content'] ?? '',
                  isUser,
                  isUrdu,
                );
              },
            ),
    );
  }

  Widget _buildWelcomeMessage(bool isUrdu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppTheme.accentColor,
                size: 30,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              AppLocalizations.translate('tutor_greeting', isUrdu ? 'ur' : 'en'),
              style: isUrdu 
                  ? AppTheme.urduBody.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    )
                  : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String message, bool isUser, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppTheme.accentColor 
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: !isUser 
                    ? Border.all(color: AppTheme.borderColor)
                    : null,
              ),
              child: Text(
                message,
                style: isUrdu 
                    ? AppTheme.urduBody.copyWith(
                        color: isUser ? Colors.white : AppTheme.textPrimary,
                        fontSize: 14,
                      )
                    : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: isUser ? Colors.white : AppTheme.textPrimary,
                      ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 14,
            ),
          ),
          
          const SizedBox(width: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Typing...',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppStateManager appState, bool isUrdu) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: AppLocalizations.translate('ask_question', isUrdu ? 'ur' : 'en'),
                hintStyle: isUrdu 
                    ? AppTheme.urduBody.copyWith(color: AppTheme.textTertiary)
                    : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.accentColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: isUrdu 
                  ? AppTheme.urduBody 
                  : AppTheme.lightTheme.textTheme.bodyMedium,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          const SizedBox(width: 8),
          
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: appState.isAiTyping ? null : _sendMessage,
                borderRadius: BorderRadius.circular(22),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}