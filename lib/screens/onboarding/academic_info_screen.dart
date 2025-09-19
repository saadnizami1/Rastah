import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state_manager.dart';
import '../../models/subject.dart';
import '../../utils/theme.dart';
import '../../utils/localization.dart';

class AcademicInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic> userData;

  const AcademicInfoScreen({
    super.key,
    required this.onDataChanged,
    required this.userData,
  });

  @override
  State<AcademicInfoScreen> createState() => _AcademicInfoScreenState();
}

class _AcademicInfoScreenState extends State<AcademicInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedClass = '';
  List<String> _selectedSubjects = [];
  List<Subject> _availableSubjects = [];
  
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
    _selectedClass = widget.userData['classLevel'] ?? '';
    _selectedSubjects = List<String>.from(widget.userData['subjects'] ?? []);
    
    if (_selectedClass.isNotEmpty) {
      _loadSubjectsForClass(_selectedClass);
    }
  }

  void _loadSubjectsForClass(String classLevel) {
    setState(() {
      _availableSubjects = Subject.getSubjectsForClass(classLevel);
      // Remove subjects that are no longer available
      _selectedSubjects.removeWhere((subject) => 
        !_availableSubjects.any((s) => s.id == subject));
    });
    _updateData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateData() {
    final data = {
      'classLevel': _selectedClass,
      'subjects': _selectedSubjects,
    };
    widget.onDataChanged(data);
  }

  void _toggleSubject(String subjectId) {
    setState(() {
      if (_selectedSubjects.contains(subjectId)) {
        _selectedSubjects.remove(subjectId);
      } else {
        _selectedSubjects.add(subjectId);
      }
    });
    _updateData();
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
                      AppLocalizations.translate('academic_info', appState.currentLanguage),
                      isUrdu,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Class selection
                    _buildClassSelection(appState.currentLanguage, isUrdu),
                    
                    const SizedBox(height: 32),
                    
                    // Subjects selection
                    if (_selectedClass.isNotEmpty) ...[
                      _buildSubjectsSelection(appState.currentLanguage, isUrdu),
                      
                      const SizedBox(height: 32),
                      
                      // Selected subjects summary
                      if (_selectedSubjects.isNotEmpty)
                        _buildSelectedSummary(appState.currentLanguage, isUrdu),
                    ],
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
            '2/4',
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
              ? 'آپ کی تعلیمی معلومات ہمیں بہتر شیڈول بنانے میں مدد کریں گی'
              : 'Your academic information helps us create a better schedule',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(color: AppTheme.textSecondary)
              : AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
        ),
      ],
    );
  }

  Widget _buildClassSelection(String language, bool isUrdu) {
    final classLevels = AppLocalizations.getClassLevels(language);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.translate('your_class', language),
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: classLevels.length,
          itemBuilder: (context, index) {
            final classLevel = classLevels[index];
            final isSelected = classLevel == _selectedClass;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedClass = classLevel;
                  _selectedSubjects.clear(); // Reset subjects when class changes
                });
                _loadSubjectsForClass(classLevel);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.accentColor 
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.accentColor 
                        : AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    classLevel,
                    style: isUrdu 
                        ? AppTheme.urduBody.copyWith(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          )
                        : AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubjectsSelection(String language, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.translate('your_subjects', language),
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.lightTheme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isUrdu 
              ? 'آپ جو مضامین پڑھتے ہیں انہیں منتخب کریں'
              : 'Select the subjects you study',
          style: isUrdu 
              ? AppTheme.urduBody.copyWith(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                )
              : AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _availableSubjects.length,
          itemBuilder: (context, index) {
            final subject = _availableSubjects[index];
            final isSelected = _selectedSubjects.contains(subject.id);
            
            return GestureDetector(
              onTap: () => _toggleSubject(subject.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Color(int.parse(subject.color.replaceFirst('#', '0xFF')))
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Color(int.parse(subject.color.replaceFirst('#', '0xFF')))
                        : AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subject.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUrdu ? subject.nameUrdu : subject.name,
                      style: isUrdu 
                          ? AppTheme.urduBody.copyWith(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 12,
                            )
                          : AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedSummary(String language, bool isUrdu) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isUrdu 
                    ? 'منتخب شدہ مضامین (${_selectedSubjects.length})'
                    : 'Selected Subjects (${_selectedSubjects.length})',
                style: isUrdu 
                    ? AppTheme.urduBody.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      )
                    : AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.successColor,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSubjects.map((subjectId) {
              final subject = _availableSubjects.firstWhere(
                (s) => s.id == subjectId,
                orElse: () => _availableSubjects.first,
              );
              
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.successColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUrdu ? subject.nameUrdu : subject.name,
                      style: isUrdu 
                          ? AppTheme.urduBody.copyWith(
                              fontSize: 12,
                              color: AppTheme.successColor,
                            )
                          : AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.successColor,
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}