import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state_manager.dart';
import '../../utils/theme.dart';
import '../../utils/localization.dart';
import '../../utils/constants.dart';

class PersonalInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic> userData;

  const PersonalInfoScreen({
    super.key,
    required this.onDataChanged,
    required this.userData,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  String _selectedGender = '';
  String _selectedProvince = '';
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadExistingData();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _loadExistingData() {
    _nameController.text = widget.userData['name'] ?? '';
    _ageController.text = widget.userData['age']?.toString() ?? '';
    _selectedGender = widget.userData['gender'] ?? '';
    _selectedProvince = widget.userData['province'] ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _updateData() {
    final data = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _selectedGender,
      'province': _selectedProvince,
    };
    widget.onDataChanged(data);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        final isUrdu = appState.currentLanguage == 'ur';
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildSectionHeader(
                      AppLocalizations.translate('personal_info', appState.currentLanguage),
                      isUrdu,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Name field
                    _buildTextField(
                      controller: _nameController,
                      label: AppLocalizations.translate('your_name', appState.currentLanguage),
                      hint: isUrdu ? 'آپ کا نام درج کریں' : 'Enter your name',
                      isUrdu: isUrdu,
                      onChanged: (_) => _updateData(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Age field
                    _buildTextField(
                      controller: _ageController,
                      label: AppLocalizations.translate('your_age', appState.currentLanguage),
                      hint: isUrdu ? 'عمر درج کریں' : 'Enter your age',
                      isUrdu: isUrdu,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateData(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Gender selection
                    _buildSelectionField(
                      label: AppLocalizations.translate('your_gender', appState.currentLanguage),
                      options: [
                        AppLocalizations.translate('male', appState.currentLanguage),
                        AppLocalizations.translate('female', appState.currentLanguage),
                        AppLocalizations.translate('prefer_not_to_say', appState.currentLanguage),
                      ],
                      selectedValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                        _updateData();
                      },
                      isUrdu: isUrdu,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Province selection
                    _buildSelectionField(
                      label: AppLocalizations.translate('your_province', appState.currentLanguage),
                      options: AppLocalizations.getProvinces(appState.currentLanguage),
                      selectedValue: _selectedProvince,
                      onChanged: (value) {
                        setState(() {
                          _selectedProvince = value;
                        });
                        _updateData();
                      },
                      isUrdu: isUrdu,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Progress indicator
                    _buildProgressInfo(appState.currentLanguage, isUrdu),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '1/4',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: isUrdu 
              ? AppTheme.urduHeading.copyWith(fontSize: 24)
              : AppTheme.lightTheme.textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isUrdu 
              ? 'آئیے آپ کے بارے میں کچھ بنیادی معلومات جانتے ہیں'
              : 'Let\'s learn some basic information about you',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(color: AppTheme.textSecondary)
              : AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isUrdu,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: isUrdu 
              ? AppTheme.urduBody 
              : AppTheme.lightTheme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: isUrdu 
                ? AppTheme.urduBody.copyWith(color: AppTheme.textTertiary)
                : AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.accentColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionField({
    required String label,
    required List<String> options,
    required String selectedValue,
    required Function(String) onChanged,
    required bool isUrdu,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.accentColor 
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.accentColor 
                        : AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: isUrdu 
                      ? AppTheme.urduBody.copyWith(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        )
                      : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressInfo(String language, bool isUrdu) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isUrdu 
                  ? 'یہ معلومات آپ کے لیے بہترین مطالعہ شیڈول بنانے میں مدد کریں گی'
                  : 'This information will help us create the best study schedule for you',
              style: isUrdu 
                  ? AppTheme.urduBody.copyWith(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    )
                  : AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}