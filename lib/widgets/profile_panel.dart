import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import '../chat_state_manager.dart';
import '../services/ai_service.dart';

class ProfilePanel extends StatefulWidget {
  final ChatStateManager stateManager;
  final VoidCallback? onClose;
  
  const ProfilePanel({
    Key? key, 
    required this.stateManager,
    this.onClose,
  }) : super(key: key);
  
  @override
  _ProfilePanelState createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  String _lastAction = '';
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _setLoading(bool loading, [String action = '']) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        _lastAction = action;
      });
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red[400] : Colors.green[400],
          duration: Duration(seconds: isError ? 4 : 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(-5, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading 
                      ? _buildLoadingState()
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D63).withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline,
            color: Color(0xFF2E7D63),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'پروفائل',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D63),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onClose?.call();
            },
            icon: const Icon(
              Icons.close,
              color: Color(0xFF2E7D63),
            ),
            tooltip: 'بند کریں',
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D63)),
          ),
          const SizedBox(height: 16),
          Text(
            _lastAction.isNotEmpty ? _lastAction : 'لوڈ ہو رہا ہے...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 30),
          _buildQuickActions(),
          const SizedBox(height: 30),
          _buildStatistics(),
          const SizedBox(height: 30),
          _buildMoodSection(),
          const SizedBox(height: 30),
          _buildSettings(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    final profile = widget.stateManager.userProfile;
    final name = profile['name'] ?? profile['user_name'] ?? 'آپ کا نام';
    final city = profile['city'] ?? profile['user_city'] ?? '';
    final age = profile['age'] ?? profile['user_age'] ?? 0;
    final profilePic = profile['profilePic'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E7D63).withOpacity(0.1),
            const Color(0xFF2E7D63).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D63).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Profile picture with edit overlay
          Stack(
            children: [
              GestureDetector(
                onTap: _showProfilePictureOptions,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image: profilePic.isNotEmpty
                        ? DecorationImage(
                            image: FileImage(File(profilePic)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(
                      color: const Color(0xFF2E7D63).withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: profilePic.isEmpty
                      ? Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 50,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D63),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D63),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showEditProfileDialog,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D63).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF2E7D63),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Location and age info
          if (city.isNotEmpty || age > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (city.isNotEmpty) ...[
                  Icon(
                    Icons.location_on,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    city,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (city.isNotEmpty && age > 0) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (age > 0) ...[
                  Icon(
                    Icons.cake,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$age سال',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('پروفائل میں تبدیلی'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D63),
                side: const BorderSide(color: Color(0xFF2E7D63)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flash_on,
              color: Color(0xFF2E7D63),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'فوری کارروائیاں',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        _buildActionButton(
          icon: Icons.mood,
          title: 'موڈ ٹریکر',
          subtitle: 'اپنا آج کا موڈ اپڈیٹ کریں',
          onTap: _showMoodTracker,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        
        _buildActionButton(
          icon: Icons.history,
          title: 'پرانی گفتگو',
          subtitle: 'گزشتہ بات چیت کا خلاصہ دیکھیں',
          onTap: _showConversationHistory,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        
        _buildActionButton(
          icon: Icons.refresh,
          title: 'نئی گفتگو',
          subtitle: 'نئی بات چیت شروع کریں',
          onTap: _startNewChat,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        
        _buildActionButton(
          icon: Icons.psychology,
          title: 'AI کا انداز',
          subtitle: 'تھراپسٹ، دوست یا بزرگ',
          onTap: _showModeSelector,
          color: Colors.purple,
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatistics() {
    final stats = widget.stateManager.getAppStatistics();
    final profile = widget.stateManager.userProfile;
    final joinDate = profile['joinDate'] ?? profile['join_date'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.analytics,
              color: Color(0xFF2E7D63),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'آپ کی سرگرمی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D63).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2E7D63).withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _buildStatItem(
                'کل پیغامات', 
                '${stats['total_messages'] ?? 0}', 
                Icons.chat_bubble_outline,
              ),
              const Divider(height: 24),
              _buildStatItem(
                'گفتگو کی تعداد', 
                '${stats['total_chats'] ?? 0}', 
                Icons.forum,
              ),
              const Divider(height: 24),
              _buildStatItem(
                'موڈ ٹریک', 
                '${stats['mood_logs'] ?? 0}', 
                Icons.trending_up,
              ),
              const Divider(height: 24),
              _buildStatItem(
                'رکنیت', 
                _formatJoinDate(joinDate), 
                Icons.calendar_today,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D63).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon, 
            color: const Color(0xFF2E7D63), 
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D63),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMoodSection() {
    final profile = widget.stateManager.userProfile;
    final currentMood = profile['currentMood'] ?? '😐';
    final stressLevel = profile['stressLevel'] ?? 5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.sentiment_satisfied,
              color: Color(0xFF2E7D63),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'موجودہ حال',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Text(
                currentMood,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'آج کا موڈ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'تناؤ:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: stressLevel / 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              stressLevel <= 3 ? Colors.green :
                              stressLevel <= 6 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$stressLevel/10',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.orange,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.settings,
              color: Color(0xFF2E7D63),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'ترتیبات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        _buildSettingsItem(
          icon: Icons.privacy_tip,
          title: 'رازداری کی پالیسی',
          onTap: _showPrivacyInfo,
        ),
        
        _buildSettingsItem(
          icon: Icons.help_outline,
          title: 'مدد اور سپورٹ',
          onTap: _showHelpInfo,
        ),
        
        _buildSettingsItem(
          icon: Icons.info_outline,
          title: 'راستہ کے بارے میں',
          onTap: _showAboutInfo,
        ),
        
        _buildSettingsItem(
          icon: Icons.code,
          title: 'ڈیولپر کے بارے میں',
          onTap: _showDeveloperInfo,
        ),
        
        _buildSettingsItem(
          icon: Icons.delete_outline,
          title: 'تمام ڈیٹا صاف کریں',
          onTap: _showClearDataDialog,
          color: Colors.red,
          showDivider: false,
        ),
      ],
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color ?? const Color(0xFF2E7D63),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color ?? Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Colors.grey[300],
            indent: 36,
          ),
      ],
    );
  }
  
  // Helper methods
  String _formatJoinDate(String date) {
    if (date.isEmpty) return 'نیا صارف';
    try {
      final DateTime joinDate = DateTime.parse(date);
      final DateTime now = DateTime.now();
      final int days = now.difference(joinDate).inDays;
      
      if (days == 0) return 'آج';
      if (days == 1) return 'کل';
      if (days < 7) return '$days دن';
      if (days < 30) return '${(days / 7).round()} ہفتے';
      if (days < 365) return '${(days / 30).round()} ماہ';
      return '${(days / 365).round()} سال';
    } catch (e) {
      return 'نیا صارف';
    }
  }
  
  // Action methods
  void _showProfilePictureOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'تصویر منتخب کریں',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D63),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D63).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt, 
                    color: Color(0xFF2E7D63),
                  ),
                ),
                title: const Text(
                  'کیمرہ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('نئی تصویر کھینچیں'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D63).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library, 
                    color: Color(0xFF2E7D63),
                  ),
                ),
                title: const Text(
                  'گیلری',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('موجودہ تصویر منتخب کریں'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  void _pickImage(ImageSource source) async {
    _setLoading(true, 'تصویر لوڈ ہو رہی ہے...');
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        final updatedProfile = Map<String, dynamic>.from(
          widget.stateManager.userProfile
        );
        updatedProfile['profilePic'] = image.path;
        
        await widget.stateManager.updateUserProfile(updatedProfile);
        _showSnackBar('تصویر کامیابی سے اپڈیٹ ہو گئی');
      }
    } catch (e) {
      _showSnackBar('تصویر اپڈیٹ کرنے میں خرابی ہوئی', isError: true);
    } finally {
      _setLoading(false);
    }
  }
  
  void _showEditProfileDialog() {
    final profile = widget.stateManager.userProfile;
    final nameController = TextEditingController(
      text: profile['name'] ?? profile['user_name'] ?? ''
    );
    final ageController = TextEditingController(
      text: (profile['age'] ?? profile['user_age'] ?? '').toString()
    );
    String selectedCity = profile['city'] ?? profile['user_city'] ?? '';
    
    final pakistaniCities = [
      'کراچی',
      'لاہور', 
      'اسلام آباد',
      'راولپنڈی',
      'فیصل آباد',
      'ملتان',
      'حیدرآباد',
      'گجرانوالہ',
      'پشاور',
      'کوئٹہ',
      'سیالکوٹ',
      'بہاولپور',
      'سرگودھا',
      'شیخوپورہ',
      'جھنگ',
      'گجرات',
      'قصور',
      'رحیم یار خان',
      'ساہیوال',
      'ٹوبہ ٹیک سنگھ',
      'اوکاڑہ',
      'وزیرآباد',
      'جہلم',
      'شجاع آباد',
      'میانوالی',
      'اٹک',
      'چکوال',
      'بھکر',
      'خوشاب',
      'حافظ آباد',
      'مردان',
      'مٹھیمیتلو',
      'لاڑکانہ',
      'نواب شاہ',
      'میرپور خاص',
      'کوٹڑی',
      'عمر کوٹ',
      'بادین',
      'ٹٹو',
      'اور'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'پروفائل میں تبدیلی',
          style: TextStyle(
            color: Color(0xFF2E7D63),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'نام',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(
                    labelText: 'عمر',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCity.isNotEmpty ? selectedCity : null,
                  decoration: const InputDecoration(
                    labelText: 'شہر',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  hint: const Text('اپنا شہر منتخب کریں'),
                  isExpanded: true,
                  items: pakistaniCities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCity = newValue ?? '';
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('منسوخ'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveProfileWithCity(nameController, ageController, selectedCity);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D63),
            ),
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveProfile(
    TextEditingController nameController,
    TextEditingController ageController,
    TextEditingController cityController,
  ) async {
    _setLoading(true, 'پروفائل اپڈیٹ ہو رہا ہے...');
    
    try {
      final updatedProfile = Map<String, dynamic>.from(
        widget.stateManager.userProfile
      );
      
      final name = nameController.text.trim();
      final ageText = ageController.text.trim();
      final city = cityController.text.trim();
      
      if (name.isNotEmpty) {
        updatedProfile['name'] = name;
        updatedProfile['user_name'] = name;
      }
      
      if (ageText.isNotEmpty) {
        final age = int.tryParse(ageText);
        if (age != null && age > 0 && age < 150) {
          updatedProfile['age'] = age;
          updatedProfile['user_age'] = age;
        }
      }
      
      if (city.isNotEmpty) {
        updatedProfile['city'] = city;
        updatedProfile['user_city'] = city;
      }
      
      await widget.stateManager.updateUserProfile(updatedProfile);
      _showSnackBar('پروفائل کامیابی سے اپڈیٹ ہو گیا');
      
    } catch (e) {
      _showSnackBar('پروفائل اپڈیٹ کرنے میں خرابی ہوئی', isError: true);
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> _saveProfileWithCity(
    TextEditingController nameController,
    TextEditingController ageController,
    String selectedCity,
  ) async {
    _setLoading(true, 'پروفائل اپڈیٹ ہو رہا ہے...');
    
    try {
      final updatedProfile = Map<String, dynamic>.from(
        widget.stateManager.userProfile
      );
      
      final name = nameController.text.trim();
      final ageText = ageController.text.trim();
      
      if (name.isNotEmpty) {
        updatedProfile['name'] = name;
        updatedProfile['user_name'] = name;
      }
      
      if (ageText.isNotEmpty) {
        final age = int.tryParse(ageText);
        if (age != null && age > 0 && age < 150) {
          updatedProfile['age'] = age;
          updatedProfile['user_age'] = age;
        }
      }
      
      if (selectedCity.isNotEmpty) {
        updatedProfile['city'] = selectedCity;
        updatedProfile['user_city'] = selectedCity;
      }
      
      await widget.stateManager.updateUserProfile(updatedProfile);
      _showSnackBar('پروفائل کامیابی سے اپڈیٹ ہو گیا');
      
    } catch (e) {
      _showSnackBar('پروفائل اپڈیٹ کرنے میں خرابی ہوئی', isError: true);
    } finally {
      _setLoading(false);
    }
  }
  
  void _showMoodTracker() {
    final profile = widget.stateManager.userProfile;
    String selectedMood = profile['currentMood'] ?? '😐';
    double stressLevel = (profile['stressLevel'] ?? 5).toDouble();
    
    final moods = [
      {'emoji': '😢', 'label': 'بہت اداس', 'value': 'sad'},
      {'emoji': '😔', 'label': 'اداس', 'value': 'down'},
      {'emoji': '😐', 'label': 'عام', 'value': 'neutral'},
      {'emoji': '🙂', 'label': 'خوش', 'value': 'happy'},
      {'emoji': '😄', 'label': 'بہت خوش', 'value': 'very_happy'},
      {'emoji': '😰', 'label': 'پریشان', 'value': 'anxious'},
      {'emoji': '😴', 'label': 'تھکا ہوا', 'value': 'tired'},
      {'emoji': '😡', 'label': 'غصے میں', 'value': 'angry'},
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'آج آپ کیسا محسوس کر رہے ہیں؟',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D63),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Mood selection
                  const Text(
                    'اپنا موڈ منتخب کریں:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: moods.map((mood) {
                      final isSelected = mood['emoji'] == selectedMood;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => selectedMood = mood['emoji']!);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, 
                            vertical: 8
                          ),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF2E7D63).withOpacity(0.1) 
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFF2E7D63) 
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mood['emoji']!, 
                                style: const TextStyle(fontSize: 20)
                              ),
                              const SizedBox(width: 6),
                              Text(
                                mood['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected 
                                      ? const Color(0xFF2E7D63) 
                                      : Colors.black87,
                                  fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Stress level
                  const Text(
                    'تناؤ کی سطح (1-10):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      const Text('کم', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: stressLevel,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: stressLevel.round().toString(),
                          activeColor: const Color(0xFF2E7D63),
                          onChanged: (value) => setState(() => stressLevel = value),
                        ),
                      ),
                      const Text('زیادہ', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _saveMood(selectedMood, stressLevel.round());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D63),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'محفوظ کریں',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveMood(String mood, int stressLevel) async {
    _setLoading(true, 'موڈ اپڈیٹ ہو رہا ہے...');
    
    try {
      await widget.stateManager.updateUserMood(mood, stressLevel);
      _showSnackBar('موڈ کامیابی سے اپڈیٹ ہو گیا');
    } catch (e) {
      _showSnackBar('موڈ اپڈیٹ کرنے میں خرابی ہوئی', isError: true);
    } finally {
      _setLoading(false);
    }
  }
  
  void _showConversationHistory() {
    final summaries = widget.stateManager.conversationSummaries;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 20),
                    const Text(
                      'پرانی گفتگو کا خلاصہ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D63),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: summaries.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ابھی کوئی گفتگو محفوظ نہیں ہے',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'جب آپ لمبی گفتگو کریں گے تو یہاں خلاصہ نظر آئے گا',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: summaries.length,
                        itemBuilder: (context, index) {
                          final summary = summaries[index];
                          return _buildConversationItem(summary);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildConversationItem(Map<String, dynamic> summary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary['day'] ?? ''} • ${summary['time'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2E7D63),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                summary['date'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary['summary'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  void _startNewChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'نئی گفتگو',
          style: TextStyle(
            color: Color(0xFF2E7D63),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'کیا آپ واقعی نئی گفتگو شروع کرنا چاہتے ہیں؟ موجودہ گفتگو محفوظ ہو جائے گی۔',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('منسوخ'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performNewChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D63),
            ),
            child: const Text('ہاں، شروع کریں'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performNewChat() async {
    _setLoading(true, 'نئی گفتگو شروع ہو رہی ہے...');
    
    try {
      await widget.stateManager.startNewChat();
      _showSnackBar('نئی گفتگو شروع ہو گئی');
      widget.onClose?.call();
    } catch (e) {
      _showSnackBar('نئی گفتگو شروع کرنے میں خرابی ہوئی', isError: true);
    } finally {
      _setLoading(false);
    }
  }
  
  void _showModeSelector() {
    final currentMode = widget.stateManager.currentMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'AI کا انداز منتخب کریں',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D63),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Mode options
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: AIService.getAvailableModes().entries.map((entry) {
                final isSelected = entry.key == currentMode;
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _changeMode(entry.key);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF2E7D63).withOpacity(0.1) 
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF2E7D63) 
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          entry.value['emoji']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.value['name']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected 
                                  ? FontWeight.w600 
                                  : FontWeight.w500,
                              color: isSelected 
                                  ? const Color(0xFF2E7D63) 
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
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _changeMode(String newMode) async {
    _setLoading(true, 'AI کا انداز تبدیل ہو رہا ہے...');
    
    try {
      await widget.stateManager.changeMode(newMode);
      final modes = AIService.getAvailableModes();
      final modeName = modes[newMode]?['name'] ?? newMode;
      _showSnackBar('AI کا انداز $modeName میں تبدیل ہو گیا');
    } catch (e) {
      _showSnackBar('AI کا انداز تبدیل کرنے میں خرابی ہوئی', isError: true);
    } finally {
      _setLoading(false);
    }
  }
  
  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'رازداری کی پالیسی',
          style: TextStyle(
            color: Color(0xFF2E7D63),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '🔒 آپ کی رازداری ہماری اولیت ہے:\n\n'
            '• آپ کی تمام گفتگو آپ کے فون میں محفوظ ہے\n'
            '• ہم آپ کا ڈیٹا کسی کے ساتھ شیئر نہیں کرتے\n'
            '• صرف OpenAI کی API استعمال ہوتی ہے جوابات کے لیے\n'
            '• آپ جب چاہیں اپنا ڈیٹا حذف کر سکتے ہیں\n'
            '• کوئی اشتہارات یا ٹریکنگ نہیں\n\n'
            '📱 مقامی ڈیٹا:\n'
            '• تمام پیغامات آپ کے ڈیوائس میں ہیں\n'
            '• موڈ ٹریکنگ مقامی طور پر محفوظ ہے\n'
            '• پروفائل کی معلومات محفوظ ہیں\n\n'
            'اگر آپ کے کوئی سوالات ہیں تو مدد سیکشن دیکھیں۔',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('سمجھ گیا'),
          ),
        ],
      ),
    );
  }
  
  void _showHelpInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'مدد اور سپورٹ',
          style: TextStyle(
            color: Color(0xFF2E7D63),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '🤖 راستہ کیا ہے؟\n'
            'راستہ آپ کا AI ساتھی ہے جو آپ کی ذہنی صحت میں مدد کرتا ہے۔\n\n'
            '✨ خصوصیات:\n'
            '• مختلف انداز میں بات کر سکتا ہے (تھراپسٹ، دوست، بزرگ)\n'
            '• CBT تکنیکیں سکھاتا ہے\n'
            '• آپ کے موڈ کو ٹریک کرتا ہے\n'
            '• آواز سن اور بول سکتا ہے\n'
            '• گفتگو کا خلاصہ محفوظ کرتا ہے\n\n'
            '🎯 CBT تکنیکیں:\n'
            '• Pomodoro Technique - بہتر توجہ\n'
            '• Deep Breathing - تناؤ کم کرنا\n'
            '• Self-talk Reframes - مثبت سوچ\n'
            '• Impulse Control - غصے پر قابو\n'
            '• Grounding - anxiety کم کرنا\n\n'
            '⚠️ اہم نوٹ:\n'
            'یہ پیشہ ورانہ علاج کا متبادل نہیں ہے۔ سنگین مسائل کے لیے ڈاکٹر سے رابطہ کریں۔',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ٹھیک ہے'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'راستہ کے بارے میں',
          style: TextStyle(
            color: Color(0xFF2E7D63),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '🌟 راستہ - آپ کا AI تھراپسٹ\n\n'
            '📱 ورژن: 1.0.0\n'
            '🏗️ بنایا گیا: Flutter میں\n'
            '🤖 AI: OpenAI GPT\n'
            '🗣️ زبان: اردو\n\n'
            '🎯 مقصد:\n'
            'پاکستانی طلباء اور نوجوانوں کو ذہنی صحت میں مدد فراہم کرنا۔\n\n'
            '💡 خصوصی بات:\n'
            '• مکمل اردو میں\n'
            '• پاکستانی ثقافت کے مطابق\n'
            '• سائنسی CBT تکنیکیں\n'
            '• مکمل رازداری\n\n'
            '🙏 شکریہ:\n'
            'راستہ استعمال کرنے کے لیے آپ کا شکریہ۔ ہم امید کرتے ہیں یہ آپ کی مدد کرے گا۔\n\n'
            '📧 رابطہ:\n'
            'اگر کوئی مسئلہ ہو تو مدد سیکشن دیکھیں۔',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بہترین!'),
          ),
        ],
      ),
    );
  }
  
  void _showDeveloperInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ڈیولپر کے بارے میں',
          style: TextStyle(
            color: Color(0xFF2E7D63),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Developer name
              const Text(
                'Saad Nizami',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D63),
                ),
              ),
              const SizedBox(height: 16),
              
              // About section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Text(
                  'I am a passionate Flutter developer dedicated to creating meaningful applications that help people. With a focus on mental health and well-being, I strive to build technology that makes a positive impact in people\'s lives. I believe in the power of technology to bridge gaps and provide support where it\'s needed most.\n\nSpecializing in cross-platform mobile development, UI/UX design, and AI integration, I enjoy turning ideas into reality through clean, efficient code.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              
              // Contact buttons
              const Text(
                'رابطہ کریں:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D63),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContactButton(
                    icon: Icons.code,
                    label: 'GitHub',
                    color: Colors.black87,
                    onTap: () => _launchURL('https://github.com/saadnizami'),
                  ),
                  _buildContactButton(
                    icon: Icons.work,
                    label: 'LinkedIn',
                    color: const Color(0xFF0077B5),
                    onTap: () => _launchURL('https://linkedin.com/in/saadnizami'),
                  ),
                  _buildContactButton(
                    icon: Icons.email,
                    label: 'Gmail',
                    color: const Color(0xFFDB4437),
                    onTap: () => _launchURL('mailto:saadnizami.dev@gmail.com'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بند کریں'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _launchURL(String url) async {
    try {
      // For now, just show a message since url_launcher needs to be properly configured
      _showSnackBar('رابطہ: $url');
    } catch (e) {
      _showSnackBar('رابطہ کھولنے میں خرابی ہوئی', isError: true);
    }
  }
  
  void _showClearDataDialog() {
    final TextEditingController _confirmationController = TextEditingController();
    bool _isConfirmationValid = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'تمام ڈیٹا صاف کریں',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ خبردار!\n\n'
                  'اس سے یہ تمام ڈیٹا مستقل طور پر حذف ہو جائے گا:\n\n'
                  '• تمام پیغامات\n'
                  '• پروفائل کی معلومات\n'
                  '• موڈ ٹریکنگ\n'
                  '• گفتگو کے خلاصے\n'
                  '• تصاویر\n\n'
                  'یہ عمل واپس نہیں ہو سکتا۔',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'تصدیق کے لیے یہ ٹیکسٹ ٹائپ کریں:\n"I agree to delete this account"',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmationController,
                  decoration: InputDecoration(
                    hintText: 'یہاں تصدیقی ٹیکسٹ لکھیں...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _isConfirmationValid ? Colors.red : Colors.grey,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (text) {
                    setState(() {
                      _isConfirmationValid = text.trim() == "I agree to delete this account";
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('منسوخ'),
            ),
            ElevatedButton(
              onPressed: _isConfirmationValid
                  ? () async {
                      Navigator.pop(context);
                      await _performClearData();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConfirmationValid ? Colors.red : Colors.grey,
              ),
              child: const Text('اکاؤنٹ حذف کریں'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _performClearData() async {
    _setLoading(true, 'تمام ڈیٹا صاف ہو رہا ہے...');
    
    try {
      await widget.stateManager.clearAllData();
      _showSnackBar('تمام ڈیٹا کامیابی سے صاف ہو گیا - ایپ بند ہو رہی ہے');
      
      // Close profile panel and exit app after clearing data
      Future.delayed(const Duration(seconds: 2), () {
        widget.onClose?.call();
        // Exit the app
        SystemNavigator.pop();
      });
      
    } catch (e) {
      _showSnackBar('ڈیٹا صاف کرنے میں خرابی ہوئی', isError: true);
    } finally {
      _setLoading(false);
    }
  }
}