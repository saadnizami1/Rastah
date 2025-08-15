import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

// Utility class for chat animations and effects
class ChatAnimations {
  static Widget buildMessageBubbleWithAnimation({
    required Widget child,
    required AnimationController controller,
    required bool isUser,
    int delay = 0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        double animationValue = (controller.value - (delay * 0.1)).clamp(0.0, 1.0);
        
        return Transform.scale(
          scale: isUser 
              ? Curves.elasticOut.transform(animationValue)
              : Curves.bounceOut.transform(animationValue),
          child: Transform.translate(
            offset: Offset(
              isUser ? (1 - animationValue) * 100 : (1 - animationValue) * -100,
              0,
            ),
            child: Opacity(
              opacity: animationValue,
              child: child,
            ),
          ),
        );
      },
    );
  }

  static Widget buildPulsingDot({
    required Animation<double> animation,
    required Color color,
    double size = 8.0,
    double delay = 0.0,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double value = (animation.value - delay).clamp(0.0, 1.0);
        double scale = 0.5 + (math.sin(value * math.pi * 2) * 0.5);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3 + (scale * 0.7)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  static Widget buildShimmerLoading({
    required Widget child,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - animation.value, 0.0),
              end: Alignment(3.0 - animation.value, 0.0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

// Enhanced message bubble with more features
class EnhancedMessageBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final VoidCallback? onSpeak;
  final VoidCallback? onCopy;
  final bool isSpeaking;
  final DateTime timestamp;

  const EnhancedMessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.onSpeak,
    this.onCopy,
    this.isSpeaking = false,
    required this.timestamp,
  }) : super(key: key);

  @override
  _EnhancedMessageBubbleState createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    // Auto-show the bubble
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.lightImpact();
              setState(() => _showActions = !_showActions);
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Column(
                crossAxisAlignment: widget.isUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: widget.isUser 
                        ? MainAxisAlignment.end 
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!widget.isUser) ...[
                        _buildAvatar(false),
                        SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.isUser ? Color(0xFF2E7D63) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(widget.isUser ? 18 : 4),
                              bottomRight: Radius.circular(widget.isUser ? 4 : 18),
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
                                widget.message,
                                style: TextStyle(
                                  color: widget.isUser ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              if (_showActions) ...[
                                SizedBox(height: 8),
                                _buildActionButtons(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (widget.isUser) ...[
                        SizedBox(width: 8),
                        _buildAvatar(true),
                      ],
                    ],
                  ),
                  if (_showActions) 
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(widget.timestamp),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
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

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? Colors.grey[300] : Color(0xFF2E7D63),
      child: Icon(
        isUser ? Icons.person : Icons.psychology,
        color: isUser ? Colors.grey[600] : Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isUser && widget.onSpeak != null)
          _buildActionButton(
            icon: widget.isSpeaking ? Icons.volume_off : Icons.volume_up,
            onTap: widget.onSpeak!,
            tooltip: widget.isSpeaking ? 'بند کریں' : 'سنیں',
          ),
        if (widget.onCopy != null) ...[
          SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.copy,
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.message));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('کاپی ہو گیا'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'کاپی کریں',
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 18,
            color: widget.isUser ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'ابھی';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} منٹ پہلے';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} گھنٹے پہلے';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

// Loading states and empty states
class ChatLoadingStates {
  static Widget buildTypingIndicator() {
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
            child: _TypingAnimation(),
          ),
        ],
      ),
    );
  }

  static Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF2E7D63).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Color(0xFF2E7D63),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'گفتگو شروع کریں',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D63),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'نیچے پیغام لکھیں یا 🎤 دبا کر بولیں',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 15),
            Text(
              'خرابی ہوئی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text('دوبارہ کوشش کریں'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingAnimation extends StatefulWidget {
  @override
  _TypingAnimationState createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<_TypingAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimation();
  }

  void _startAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Timer(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -10 * _animations[index].value),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF2E7D63).withOpacity(0.7 + (0.3 * _animations[index].value)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

// Custom input field with enhanced features
class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onStartListening;
  final bool isListening;
  final bool isEnabled;

  const ChatInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onStartListening,
    this.isListening = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  _ChatInputFieldState createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _micController;
  late Animation<double> _micAnimation;
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _micController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _micAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _micController, curve: Curves.easeInOut),
    );
    _focusNode = FocusNode();
    
    widget.controller.addListener(_onTextChanged);
    
    if (widget.isListening) {
      _micController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ChatInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _micController.repeat(reverse: true);
      } else {
        _micController.stop();
        _micController.reset();
      }
    }
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _micController.dispose();
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Voice button
            AnimatedBuilder(
              animation: _micAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isListening ? _micAnimation.value : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isListening ? Colors.red : Color(0xFF2E7D63),
                      shape: BoxShape.circle,
                      boxShadow: widget.isListening ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: IconButton(
                      onPressed: widget.isEnabled ? widget.onStartListening : null,
                      icon: Icon(
                        widget.isListening ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                      tooltip: widget.isListening ? 'رکیں' : 'بولیں',
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(width: 12),
            
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _focusNode.hasFocus 
                        ? Color(0xFF2E7D63) 
                        : Colors.grey[300]!,
                    width: _focusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.isEnabled,
                  decoration: InputDecoration(
                    hintText: widget.isListening 
                        ? 'سن رہا ہوں...' 
                        : 'یہاں لکھیں...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    hintStyle: TextStyle(
                      color: widget.isListening ? Colors.red[300] : Colors.grey[500],
                    ),
                  ),
                  maxLines: null,
                  maxLength: 1000,
                  buildCounter: (context, {required currentLength, maxLength, required isFocused}) {
                    if (currentLength > 800) {
                      return Text(
                        '$currentLength/$maxLength',
                        style: TextStyle(
                          color: currentLength > 950 ? Colors.red : Colors.orange,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  },
                  textDirection: TextDirection.rtl,
                  onSubmitted: widget.isEnabled ? (_) => widget.onSend() : null,
                ),
              ),
            ),
            
            SizedBox(width: 12),
            
            // Send button
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _hasText && widget.isEnabled 
                    ? Color(0xFF2E7D63) 
                    : Colors.grey[400],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _hasText && widget.isEnabled ? widget.onSend : null,
                icon: Icon(Icons.send, color: Colors.white),
                tooltip: 'بھیجیں',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Connection status indicator
class ConnectionStatusIndicator extends StatefulWidget {
  final bool isConnected;
  final bool isLoading;

  const ConnectionStatusIndicator({
    Key? key,
    required this.isConnected,
    this.isLoading = false,
  }) : super(key: key);

  @override
  _ConnectionStatusIndicatorState createState() => _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
    
    if (widget.isLoading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ConnectionStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isConnected && !widget.isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 16, color: Colors.red),
            SizedBox(width: 4),
            Text(
              'آف لائن',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (widget.isLoading) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF2E7D63).withOpacity(0.1 * _animation.value),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF2E7D63).withOpacity(0.3 * _animation.value),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D63)),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'لوڈ ہو رہا',
                  style: TextStyle(color: Color(0xFF2E7D63), fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    }

    return SizedBox.shrink();
  }
}

// Utility functions for chat
class ChatUtils {
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'ابھی';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} منٹ پہلے';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} گھنٹے پہلے';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} دن پہلے';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static Color getMoodColor(String mood) {
    switch (mood) {
      case '😄':
      case '😊':
        return Colors.green;
      case '😐':
        return Colors.grey;
      case '😔':
      case '😰':
        return Colors.blue;
      case '😠':
        return Colors.red;
      case '😴':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static String getMoodDescription(String mood) {
    switch (mood) {
      case '😄':
        return 'بہت خوش';
      case '😊':
        return 'خوش';
      case '😐':
        return 'عام';
      case '😔':
        return 'اداس';
      case '😠':
        return 'ناراض';
      case '😰':
        return 'پریشان';
      case '😴':
        return 'تھکا ہوا';
      default:
        return 'نامعلوم';
    }
  }

  static Color getStressLevelColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }

  static String formatMessageLength(String message) {
    if (message.length <= 50) return 'مختصر';
    if (message.length <= 150) return 'درمیانہ';
    return 'تفصیلی';
  }

  static bool isUrduText(String text) {
    // Simple check for Urdu/Arabic characters
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  static TextDirection getTextDirection(String text) {
    return isUrduText(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  static List<String> extractKeywords(String text) {
    final urduKeywords = [
      'خوش', 'اداس', 'پریشان', 'غصہ', 'تناؤ', 'خوشی', 'غم',
      'ڈپریشن', 'anxiety', 'stress', 'happy', 'sad', 'angry'
    ];
    
    final foundKeywords = <String>[];
    final lowerText = text.toLowerCase();
    
    for (final keyword in urduKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        foundKeywords.add(keyword);
      }
    }
    
    return foundKeywords;
  }

  static Map<String, dynamic> analyzeMessage(String message) {
    return {
      'length': message.length,
      'wordCount': message.split(' ').length,
      'isUrdu': isUrduText(message),
      'keywords': extractKeywords(message),
      'sentiment': _analyzeSentiment(message),
      'hasEmojis': RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]', unicode: true).hasMatch(message),
    };
  }

  static String _analyzeSentiment(String text) {
    final positiveWords = ['خوش', 'اچھا', 'بہتر', 'شکر', 'happy', 'good', 'great', 'excellent'];
    final negativeWords = ['اداس', 'برا', 'پریشان', 'غصہ', 'sad', 'bad', 'angry', 'worried'];
    
    final lowerText = text.toLowerCase();
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      if (lowerText.contains(word)) positiveCount++;
    }
    
    for (final word in negativeWords) {
      if (lowerText.contains(word)) negativeCount++;
    }
    
    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }
}