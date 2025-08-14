import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key, required void Function() onNext});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  int _currentQuestionIndex = 0;
  bool _isUrdu = true; // Language toggle
  
  // Data storage
  final Map<String, dynamic> _userData = {};
  
  // Questions data structure
  late List<QuestionData> _questions;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
  }

  void _initializeQuestions() {
    _questions = [
      // Block 1 - Identity (Required)
      QuestionData(
        id: 'name',
        urduText: 'آپ کا نام کیا ہے؟',
        englishText: 'What is your name?',
        type: QuestionType.textInput,
        isRequired: true,
        block: 'identity',
      ),
      QuestionData(
        id: 'age',
        urduText: 'آپ کی عمر؟',
        englishText: 'Your age?',
        type: QuestionType.numberPicker,
        isRequired: true,
        block: 'identity',
      ),
      QuestionData(
        id: 'gender',
        urduText: 'آپ کی جنس؟',
        englishText: 'Your gender?',
        type: QuestionType.chips,
        isRequired: true,
        block: 'identity',
        options: ['مرد', 'عورت', 'دوسرا', 'کہنا نہیں چاہتے'],
        englishOptions: ['Male', 'Female', 'Other', 'Prefer not to say'],
      ),
      
      // Block 2 - Daily Life (Skippable)
      QuestionData(
        id: 'occupation',
        urduText: 'زیادہ تر دنوں میں آپ کیا کرتے ہیں؟',
        englishText: 'What do you do most days?',
        type: QuestionType.chips,
        isRequired: false,
        block: 'daily_life',
        options: ['طالب علم', 'ملازم', 'گھریلو کام', 'ریٹائرڈ', 'اور'],
        englishOptions: ['Student', 'Employee', 'Homemaker', 'Retired', 'Other'],
      ),
      QuestionData(
        id: 'region',
        urduText: 'آپ کہاں رہتے ہیں؟',
        englishText: 'Where do you live?',
        type: QuestionType.dropdown,
        isRequired: false,
        block: 'daily_life',
        options: ['کراچی', 'لاہور', 'اسلام آباد', 'راولپنڈی', 'فیصل آباد', 'پشاور', 'کوئٹہ', 'ملتان', 'اور'],
        englishOptions: ['Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad', 'Peshawar', 'Quetta', 'Multan', 'Other'],
      ),
      QuestionData(
        id: 'preferred_time',
        urduText: 'آپ کے دن کا سب سے پسندیدہ وقت کون سا ہے؟',
        englishText: 'What is your favorite time of day?',
        type: QuestionType.chips,
        isRequired: false,
        block: 'daily_life',
        options: ['صبح', 'دوپہر', 'شام', 'رات'],
        englishOptions: ['Morning', 'Afternoon', 'Evening', 'Night'],
      ),
      
      // Block 3 - Mind & Mood (Skippable)
      QuestionData(
        id: 'current_mood',
        urduText: 'آج آپ کیسا محسوس کر رہے ہیں؟',
        englishText: 'How are you feeling today?',
        type: QuestionType.emojiPicker,
        isRequired: false,
        block: 'mood',
        emojis: ['😄', '😊', '😌', '😐', '😕', '😔', '😢', '😤', '😰'],
      ),
      QuestionData(
        id: 'stress_level',
        urduText: 'کیا آپ حال ہی میں زیادہ تناؤ محسوس کر رہے ہیں؟',
        englishText: 'Have you been feeling more stressed lately?',
        type: QuestionType.slider,
        isRequired: false,
        block: 'mood',
        sliderMin: 0,
        sliderMax: 10,
        sliderLabels: ['بالکل نہیں', 'بہت زیادہ'],
        englishSliderLabels: ['Not at all', 'Very much'],
      ),
      QuestionData(
        id: 'important_topics',
        urduText: 'کون سا موضوع آج کل زیادہ اہم ہے؟',
        englishText: 'Which topic is most important lately?',
        type: QuestionType.multiSelectChips,
        isRequired: false,
        block: 'mood',
        options: ['تناؤ', 'رشتے', 'کیریئر', 'صحت', 'خودی کا احترام', 'پیسہ', 'مطالعہ'],
        englishOptions: ['Stress', 'Relationships', 'Career', 'Health', 'Self-esteem', 'Money', 'Studies'],
      ),
      
      // Block 4 - Hobbies & Interests (Skippable)
      QuestionData(
        id: 'hobbies',
        urduText: 'آپ کو فارغ وقت میں کیا کرنا پسند ہے؟',
        englishText: 'What do you like to do in your free time?',
        type: QuestionType.multiSelectChips,
        isRequired: false,
        block: 'hobbies',
        options: ['پڑھنا', 'ٹی وی', 'کھانا بنانا', 'ٹہلنا', 'موسیقی', 'آرٹ', 'باغبانی', 'کھیل'],
        englishOptions: ['Reading', 'TV', 'Cooking', 'Walking', 'Music', 'Art', 'Gardening', 'Sports'],
      ),
      QuestionData(
        id: 'social_preference',
        urduText: 'کیا آپ زیادہ وقت اکیلے رہنا پسند کرتے ہیں یا دوسروں کے ساتھ؟',
        englishText: 'Do you prefer spending time alone or with others?',
        type: QuestionType.slider,
        isRequired: false,
        block: 'hobbies',
        sliderMin: 0,
        sliderMax: 10,
        sliderLabels: ['اکیلے', 'دوسروں کے ساتھ'],
        englishSliderLabels: ['Alone', 'With others'],
      ),
      
      // Block 5 - Therapy Style (Skippable)
      QuestionData(
        id: 'therapy_style',
        urduText: 'کیا آپ چاہیں گے کہ میں زیادہ سنوں یا زیادہ مشورہ دوں؟',
        englishText: 'Would you like me to listen more or give more advice?',
        type: QuestionType.largeBinaryChoice,
        isRequired: false,
        block: 'therapy',
        options: ['زیادہ سنوں', 'زیادہ مشورہ دوں'],
        englishOptions: ['Listen more', 'Give more advice'],
      ),
      QuestionData(
        id: 'communication_style',
        urduText: 'آپ کو سخت اور سیدھی بات پسند ہے یا نرم اور آہستہ؟',
        englishText: 'Do you prefer direct communication or gentle and soft?',
        type: QuestionType.slider,
        isRequired: false,
        block: 'therapy',
        sliderMin: 0,
        sliderMax: 10,
        sliderLabels: ['نرم اور آہستہ', 'سخت اور سیدھی'],
        englishSliderLabels: ['Gentle & soft', 'Direct & straight'],
      ),
      QuestionData(
        id: 'input_preference',
        urduText: 'کیا آپ کو اپنے مسائل اردو میں لکھنا آسان لگتا ہے یا بول کر؟',
        englishText: 'Do you find it easier to write or speak about your problems?',
        type: QuestionType.toggle,
        isRequired: false,
        block: 'therapy',
        options: ['لکھنا', 'بولنا'],
        englishOptions: ['Writing', 'Speaking'],
      ),
      
      // Block 6 - Wrap Up
      QuestionData(
        id: 'completion',
        urduText: 'شکریہ، میں نے سب یاد رکھ لیا۔ ہم جب بھی بات کریں گے، یہ سب ذہن میں رکھوں گی۔',
        englishText: 'Thank you, I have remembered everything. Whenever we talk, I will keep all this in mind.',
        type: QuestionType.completion,
        isRequired: false,
        block: 'completion',
      ),
    ];
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _saveDataAndProceed();
    }
  }

  void _saveAnswer(String questionId, dynamic value) {
    setState(() {
      _userData[questionId] = value;
    });
  }

  Future<void> _saveDataAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save each piece of data
    _userData.forEach((key, value) async {
      if (value is List) {
        await prefs.setStringList(key, value.cast<String>());
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    });
    
    // Mark personalization as complete
    await prefs.setBool('personalization_complete', true);
    
    // Navigate directly to chat screen
    if (mounted) {
      context.go('/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.cover,
            ),
          ),
          // Glass overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header with progress and language toggle
                _buildHeader(),
                
                // Question content
                Expanded(
                  child: _buildQuestionContent(currentQuestion),
                ),
                
                // Navigation buttons
                _buildNavigationButtons(currentQuestion),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Glass effect decoration
  BoxDecoration _glassDecoration({double opacity = 0.15}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: _glassDecoration(),
            child: Text(
              '${_currentQuestionIndex + 1} of ${_questions.length}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          
          // Language toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _isUrdu = !_isUrdu;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: _glassDecoration(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isUrdu ? 'اردو' : 'Eng',
                    style: GoogleFonts.notoNaskhArabic(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.language,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(QuestionData question) {
    // Special handling for completion screen - no question box
    if (question.type == QuestionType.completion) {
      return _buildQuestionInput(question);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _glassDecoration(),
            child: Text(
              _isUrdu ? question.urduText : question.englishText,
              style: GoogleFonts.notoNaskhArabic(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Question input widget
          Expanded(
            child: _buildQuestionInput(question),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(QuestionData question) {
    switch (question.type) {
      case QuestionType.textInput:
        return _buildTextInput(question);
      case QuestionType.numberPicker:
        return _buildNumberPicker(question);
      case QuestionType.chips:
        return _buildChips(question);
      case QuestionType.multiSelectChips:
        return _buildMultiSelectChips(question);
      case QuestionType.dropdown:
        return _buildDropdown(question);
      case QuestionType.emojiPicker:
        return _buildEmojiPicker(question);
      case QuestionType.slider:
        return _buildSlider(question);
      case QuestionType.largeBinaryChoice:
        return _buildLargeBinaryChoice(question);
      case QuestionType.toggle:
        return _buildToggle(question);
      case QuestionType.completion:
        return _buildCompletion(question);
    }
  }

  Widget _buildTextInput(QuestionData question) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 18,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: _isUrdu ? 'یہاں لکھیں...' : 'Type here...',
            hintStyle: GoogleFonts.notoNaskhArabic(
              color: Colors.white.withOpacity(0.7),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            _saveAnswer(question.id, value);
          },
        ),
      ),
    );
  }

  Widget _buildNumberPicker(QuestionData question) {
    int selectedAge = _userData[question.id] ?? 18;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _glassDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedAge.toString(),
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: selectedAge > 13 ? () {
                    setState(() {
                      selectedAge--;
                      _saveAnswer(question.id, selectedAge);
                    });
                  } : null,
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: 40,
                    color: selectedAge > 13 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  onPressed: selectedAge < 100 ? () {
                    setState(() {
                      selectedAge++;
                      _saveAnswer(question.id, selectedAge);
                    });
                  } : null,
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 40,
                    color: selectedAge < 100 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips(QuestionData question) {
    String? selectedValue = _userData[question.id];
    final options = _isUrdu ? question.options! : question.englishOptions!;
    
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: options.map((option) {
          final isSelected = selectedValue == option;
          return GestureDetector(
            onTap: () {
              _saveAnswer(question.id, option);
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected 
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Text(
                option,
                style: GoogleFonts.notoNaskhArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultiSelectChips(QuestionData question) {
    List<String> selectedValues = _userData[question.id] ?? [];
    final options = _isUrdu ? question.options! : question.englishOptions!;
    
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: options.map((option) {
          final isSelected = selectedValues.contains(option);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedValues.remove(option);
                } else {
                  selectedValues.add(option);
                }
                _saveAnswer(question.id, selectedValues);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected 
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    option,
                    style: GoogleFonts.notoNaskhArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdown(QuestionData question) {
    String? selectedValue = _userData[question.id];
    final options = _isUrdu ? question.options! : question.englishOptions!;
    
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _glassDecoration(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            hint: Text(
              _isUrdu ? 'انتخاب کریں' : 'Select',
              style: GoogleFonts.notoNaskhArabic(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            isExpanded: true,
            dropdownColor: Colors.black.withOpacity(0.8),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _saveAnswer(question.id, value);
                setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker(QuestionData question) {
    String? selectedEmoji = _userData[question.id];
    
    return Center(
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: question.emojis!.map((emoji) {
          final isSelected = selectedEmoji == emoji;
          return GestureDetector(
            onTap: () {
              _saveAnswer(question.id, emoji);
              setState(() {});
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlider(QuestionData question) {
    double currentValue = _userData[question.id]?.toDouble() ?? 5.0;
    final labels = _isUrdu ? question.sliderLabels! : question.englishSliderLabels!;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _glassDecoration(),
            child: Column(
              children: [
                Text(
                  currentValue.round().toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: currentValue,
                    min: question.sliderMin!.toDouble(),
                    max: question.sliderMax!.toDouble(),
                    divisions: question.sliderMax! - question.sliderMin!,
                    onChanged: (value) {
                      setState(() {
                        currentValue = value;
                        _saveAnswer(question.id, value.round());
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      labels[0],
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      labels[1],
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeBinaryChoice(QuestionData question) {
    String? selectedValue = _userData[question.id];
    final options = _isUrdu ? question.options! : question.englishOptions!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: options.map((option) {
          final isSelected = selectedValue == option;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onTap: () {
                _saveAnswer(question.id, option);
                setState(() {});
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggle(QuestionData question) {
    String? selectedValue = _userData[question.id];
    final options = _isUrdu ? question.options! : question.englishOptions!;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: _glassDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () {
                _saveAnswer(question.id, option);
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCompletion(QuestionData question) {
    String userName = _userData['name'] ?? (_isUrdu ? 'دوست' : 'friend');
    String completionText = _isUrdu 
      ? 'شکریہ ، میں نے سب یاد رکھ لیا۔ ہم جب بھی بات کریں گے، یہ سب ذہن میں رکھوں گی۔'
      : 'Thank you $userName, I have remembered everything. Whenever we talk, I will keep all this in mind.';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Welcome image in upper middle
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                height: 200,
                width: 200,
                child: Image.asset(
                  'assets/images/welcome_img.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // Completion message box (without heart icon)
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: _glassDecoration(),
                child: Text(
                  completionText,
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(QuestionData question) {
    final canProceed = question.isRequired 
      ? _userData.containsKey(question.id) && _userData[question.id] != null
      : true;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canProceed ? _nextQuestion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canProceed 
              ? Colors.greenAccent.withOpacity(0.8)
              : Colors.grey.withOpacity(0.5),
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: Text(
            question.type == QuestionType.completion
              ? (_isUrdu ? 'بات شروع کریں' : 'Start Chatting')
              : (_isUrdu ? 'اگلا' : 'Next'),
            style: GoogleFonts.notoNaskhArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Data classes
class QuestionData {
  final String id;
  final String urduText;
  final String englishText;
  final QuestionType type;
  final bool isRequired;
  final String block;
  final List<String>? options;
  final List<String>? englishOptions;
  final List<String>? emojis;
  final int? sliderMin;
  final int? sliderMax;
  final List<String>? sliderLabels;
  final List<String>? englishSliderLabels;

  QuestionData({
    required this.id,
    required this.urduText,
    required this.englishText,
    required this.type,
    required this.isRequired,
    required this.block,
    this.options,
    this.englishOptions,
    this.emojis,
    this.sliderMin,
    this.sliderMax,
    this.sliderLabels,
    this.englishSliderLabels,
  });
}

enum QuestionType {
  textInput,
  numberPicker,
  chips,
  multiSelectChips,
  dropdown,
  emojiPicker,
  slider,
  largeBinaryChoice,
  toggle,
  completion,
}