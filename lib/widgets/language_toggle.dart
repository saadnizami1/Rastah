import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state_manager.dart';
import '../utils/theme.dart';

class LanguageToggle extends StatefulWidget {
  final bool showLabels;
  final double size;
  
  const LanguageToggle({
    super.key,
    this.showLabels = true,
    this.size = 40.0,
  });

  @override
  State<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    
    // Start animation
    _controller.forward().then((_) {
      _controller.reverse();
    });
    
    // Toggle language
    appState.toggleLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        final isUrdu = appState.currentLanguage == 'ur';
        
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTap: _toggleLanguage,
                child: Container(
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    border: Border.all(
                      color: AppTheme.borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: widget.showLabels 
                      ? _buildWithLabels(isUrdu)
                      : _buildIconOnly(isUrdu),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWithLabels(bool isUrdu) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLanguageOption(
          text: 'EN',
          isSelected: !isUrdu,
          isLeft: true,
        ),
        _buildLanguageOption(
          text: 'اردو',
          isSelected: isUrdu,
          isLeft: false,
        ),
      ],
    );
  }

  Widget _buildIconOnly(bool isUrdu) {
    return Container(
      width: widget.size,
      height: widget.size,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          isUrdu ? 'اردو' : 'EN',
          style: TextStyle(
            fontSize: widget.size * 0.3,
            fontWeight: FontWeight.w600,
            color: AppTheme.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String text,
    required bool isSelected,
    required bool isLeft,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentColor : Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLeft ? widget.size / 2 : 0),
          bottomLeft: Radius.circular(isLeft ? widget.size / 2 : 0),
          topRight: Radius.circular(!isLeft ? widget.size / 2 : 0),
          bottomRight: Radius.circular(!isLeft ? widget.size / 2 : 0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
    );
  }
}