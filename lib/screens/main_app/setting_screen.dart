import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app_state_manager.dart';
import '../../utils/theme.dart';
import '../../widgets/language_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showResetDialog(AppStateManager appState, bool isUrdu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          isUrdu ? 'تمام ڈیٹا صاف کریں؟' : 'Clear All Data?',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.errorColor,
                ),
        ),
        content: Text(
          isUrdu 
              ? 'یہ عمل آپ کا تمام شیڈول، چیٹ تاریخ، اور ترجیحات ہٹا دے گا۔ کیا آپ واقعی جاری رکھنا چاہتے ہیں؟'
              : 'This will remove all your schedule, chat history, and preferences. Are you sure you want to continue?',
          style: isUrdu 
              ? AppTheme.urduBody 
              : AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isUrdu ? 'منسوخ' : 'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetApp(appState);
            },
            child: Text(
              isUrdu ? 'صاف کریں' : 'Clear',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetApp(AppStateManager appState) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await appState.resetAppData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appState.currentLanguage == 'ur' 
                  ? 'تمام ڈیٹا صاف کر دیا گیا'
                  : 'All data has been cleared',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Navigate back to welcome
        context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _regenerateSchedule(AppStateManager appState) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await appState.generateTimetable();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appState.currentLanguage == 'ur' 
                  ? 'نیا شیڈول تیار کر دیا گیا'
                  : 'New schedule generated',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          final isUrdu = appState.currentLanguage == 'ur';
          final profile = appState.studentProfile;
          final stats = appState.getAppStatistics();
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(isUrdu),
                    
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile section
                            if (profile != null)
                              _buildProfileSection(profile, isUrdu),
                            
                            const SizedBox(height: 24),
                            
                            // App statistics
                            _buildStatsSection(stats, isUrdu),
                            
                            const SizedBox(height: 24),
                            
                            // Language settings
                            _buildLanguageSection(appState, isUrdu),
                            
                            const SizedBox(height: 24),
                            
                            // Schedule settings
                            _buildScheduleSection(appState, isUrdu),
                            
                            const SizedBox(height: 24),
                            
                            // Data management
                            _buildDataSection(appState, isUrdu),
                            
                            const SizedBox(height: 24),
                            
                            // About section
                            _buildAboutSection(isUrdu),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isUrdu) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/main'),
            icon: Icon(
              isUrdu ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(width: 8),
          
          Expanded(
            child: Text(
              isUrdu ? 'ترتیبات' : 'Settings',
              style: isUrdu 
                  ? AppTheme.urduHeading.copyWith(fontSize: 20)
                  : AppTheme.lightTheme.textTheme.titleLarge,
            ),
          ),
          
          LanguageToggle(size: 32, showLabels: false),
        ],
      ),
    );
  }

  Widget _buildProfileSection(dynamic profile, bool isUrdu) {
    return _buildSection(
      title: isUrdu ? 'پروفائل' : 'Profile',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: isUrdu 
                            ? AppTheme.urduBody.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              )
                            : AppTheme.lightTheme.textTheme.titleMedium,
                      ),
                      Text(
                        '${profile.age} ${isUrdu ? "سال" : "years old"} • ${profile.classLevel}',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildProfileStat(
                  icon: Icons.location_on,
                  value: profile.province,
                  isUrdu: isUrdu,
                ),
                const SizedBox(width: 16),
                _buildProfileStat(
                  icon: Icons.book,
                  value: '${profile.subjects.length} ${isUrdu ? "مضامین" : "subjects"}',
                  isUrdu: isUrdu,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat({
    required IconData icon,
    required String value,
    required bool isUrdu,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: isUrdu 
                    ? AppTheme.urduBody.copyWith(fontSize: 12)
                    : AppTheme.lightTheme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats, bool isUrdu) {
    return _buildSection(
      title: isUrdu ? 'شماریات' : 'Statistics',
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                icon: Icons.schedule,
                value: '${stats['total_weekly_hours']?.toStringAsFixed(1) ?? "0"}h',
                label: isUrdu ? 'ہفتہ وار' : 'Weekly',
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Icons.book,
                value: '${stats['subjects_count'] ?? 0}',
                label: isUrdu ? 'مضامین' : 'Subjects',
                color: AppTheme.successColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.check_circle,
                value: '${stats['completed'] ?? 0}',
                label: isUrdu ? 'مکمل' : 'Completed',
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Icons.chat,
                value: '${stats['total_chat_messages'] ?? 0}',
                label: isUrdu ? 'پیغامات' : 'Messages',
                color: AppTheme.warningColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(AppStateManager appState, bool isUrdu) {
    return _buildSection(
      title: isUrdu ? 'زبان' : 'Language',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language,
              color: AppTheme.accentColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrdu ? 'ایپ کی زبان' : 'App Language',
                    style: isUrdu 
                        ? AppTheme.urduBody.copyWith(fontWeight: FontWeight.w600)
                        : AppTheme.lightTheme.textTheme.titleSmall,
                  ),
                  Text(
                    isUrdu ? 'انٹرفیس کی زبان تبدیل کریں' : 'Change interface language',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            LanguageToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(AppStateManager appState, bool isUrdu) {
    return _buildSection(
      title: isUrdu ? 'شیڈول' : 'Schedule',
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.refresh,
            title: isUrdu ? 'نیا شیڈول بنائیں' : 'Generate New Schedule',
            subtitle: isUrdu ? 'اپ ٹو ڈیٹ شیڈول کے لیے' : 'For updated schedule',
            color: AppTheme.accentColor,
            onTap: () => _regenerateSchedule(appState),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 12),
          
          _buildActionTile(
            icon: Icons.chat_bubble_outline,
            title: isUrdu ? 'چیٹ صاف کریں' : 'Clear Chat History',
            subtitle: isUrdu ? 'AI ٹیوٹر کی گفتگو ہٹائیں' : 'Remove AI tutor conversations',
            color: AppTheme.warningColor,
            onTap: () {
              appState.clearChatHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isUrdu ? 'چیٹ صاف کر دی گئی' : 'Chat history cleared',
                  ),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(AppStateManager appState, bool isUrdu) {
    return _buildSection(
      title: isUrdu ? 'ڈیٹا' : 'Data',
      child: _buildActionTile(
        icon: Icons.delete_forever,
        title: isUrdu ? 'تمام ڈیٹا صاف کریں' : 'Clear All Data',
        subtitle: isUrdu ? 'شیڈول، چیٹ، اور ترجیحات' : 'Schedule, chat, and preferences',
        color: AppTheme.errorColor,
        onTap: () => _showResetDialog(appState, isUrdu),
        isDestructive: true,
      ),
    );
  }

  Widget _buildAboutSection(bool isUrdu) {
    return _buildSection(
      title: isUrdu ? 'ایپ کے بارے میں' : 'About',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accentColor,
                        AppTheme.accentColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? 'رستہ - AI مطالعہ ساتھی' : 'Rasta - AI Study Companion',
                        style: isUrdu 
                            ? AppTheme.urduBody.copyWith(fontWeight: FontWeight.w600)
                            : AppTheme.lightTheme.textTheme.titleSmall,
                      ),
                      Text(
                        'Version 1.0.0',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              isUrdu 
                  ? 'پاکستانی طلباء کے لیے خصوصی طور پر ڈیزائن کیا گیا ایک AI پاور مطالعہ ساتھی۔'
                  : 'An AI-powered study companion specially designed for Pakistani students.',
              style: isUrdu 
                  ? AppTheme.urduBody.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    )
                  : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isUrdu 
                      ? 'ڈیٹا ${16} دن بعد خودکار طور پر ڈیلیٹ ہو جاتا ہے'
                      : 'Data automatically deleted after ${16} days',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: isLoading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, color: color, size: 20),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: isDestructive ? color : AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!isLoading)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}