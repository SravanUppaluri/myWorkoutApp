import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FitnessAssessmentScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const FitnessAssessmentScreen({super.key, required this.onComplete});

  @override
  State<FitnessAssessmentScreen> createState() =>
      _FitnessAssessmentScreenState();
}

class _FitnessAssessmentScreenState extends State<FitnessAssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Assessment data
  final Map<String, dynamic> _assessmentData = {
    'activityLevel': '',
    'workoutFrequency': '',
    'experienceLevel': '',
    'primaryGoal': '',
    'preferredWorkoutTypes': <String>[],
    'availableTime': '',
    'equipment': <String>[],
    'limitations': <String>[],
  };

  final List<String> _activityLevels = [
    'Sedentary (little to no exercise)',
    'Lightly active (light exercise 1-3 days/week)',
    'Moderately active (moderate exercise 3-5 days/week)',
    'Very active (hard exercise 6-7 days/week)',
    'Extremely active (very hard exercise, physical job)',
  ];

  final List<String> _workoutFrequencies = [
    '1-2 times per week',
    '3-4 times per week',
    '5-6 times per week',
    'Daily',
  ];

  final List<String> _experienceLevels = [
    'Complete beginner',
    'Some experience (under 1 year)',
    'Intermediate (1-3 years)',
    'Advanced (3+ years)',
    'Expert/Professional',
  ];

  final List<String> _primaryGoals = [
    'Lose weight',
    'Build muscle',
    'Increase strength',
    'Improve endurance',
    'Get toned',
    'Improve flexibility',
    'General fitness',
    'Sport-specific training',
  ];

  final List<String> _workoutTypes = [
    'Weightlifting',
    'Cardio',
    'HIIT',
    'Yoga',
    'Pilates',
    'Swimming',
    'Running',
    'Cycling',
    'Bodyweight exercises',
    'Functional training',
  ];

  final List<String> _timeOptions = [
    '15-30 minutes',
    '30-45 minutes',
    '45-60 minutes',
    '60+ minutes',
  ];

  final List<String> _equipmentOptions = [
    'No equipment (bodyweight only)',
    'Dumbbells',
    'Resistance bands',
    'Pull-up bar',
    'Full gym access',
    'Home gym setup',
    'Yoga mat',
    'Kettlebells',
  ];

  final List<String> _limitationOptions = [
    'No limitations',
    'Back problems',
    'Knee problems',
    'Shoulder problems',
    'Heart condition',
    'Pregnancy',
    'Recent injury',
    'Mobility issues',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Assessment'), elevation: 0),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildActivityLevelPage(),
                _buildWorkoutFrequencyPage(),
                _buildExperienceLevelPage(),
                _buildPrimaryGoalPage(),
                _buildWorkoutTypesPage(),
                _buildTimeAvailabilityPage(),
                _buildEquipmentPage(),
                _buildLimitationsPage(),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox.shrink(),

                ElevatedButton(
                  onPressed: _canProceed()
                      ? () {
                          if (_currentPage < 7) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            widget.onComplete(_assessmentData);
                          }
                        }
                      : null,
                  child: Text(_currentPage < 7 ? 'Next' : 'Complete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevelPage() {
    return _buildSelectionPage(
      title: 'What\'s your current activity level?',
      subtitle: 'Help us understand your starting point',
      options: _activityLevels,
      selectedValue: _assessmentData['activityLevel'],
      onChanged: (value) {
        setState(() {
          _assessmentData['activityLevel'] = value;
        });
      },
    );
  }

  Widget _buildWorkoutFrequencyPage() {
    return _buildSelectionPage(
      title: 'How often do you want to work out?',
      subtitle: 'Be realistic about what you can commit to',
      options: _workoutFrequencies,
      selectedValue: _assessmentData['workoutFrequency'],
      onChanged: (value) {
        setState(() {
          _assessmentData['workoutFrequency'] = value;
        });
      },
    );
  }

  Widget _buildExperienceLevelPage() {
    return _buildSelectionPage(
      title: 'What\'s your fitness experience?',
      subtitle: 'This helps us recommend appropriate exercises',
      options: _experienceLevels,
      selectedValue: _assessmentData['experienceLevel'],
      onChanged: (value) {
        setState(() {
          _assessmentData['experienceLevel'] = value;
        });
      },
    );
  }

  Widget _buildPrimaryGoalPage() {
    return _buildSelectionPage(
      title: 'What\'s your primary fitness goal?',
      subtitle: 'Choose the one that matters most to you',
      options: _primaryGoals,
      selectedValue: _assessmentData['primaryGoal'],
      onChanged: (value) {
        setState(() {
          _assessmentData['primaryGoal'] = value;
        });
      },
    );
  }

  Widget _buildWorkoutTypesPage() {
    return _buildMultiSelectionPage(
      title: 'What types of workouts interest you?',
      subtitle: 'Select all that apply',
      options: _workoutTypes,
      selectedValues: _assessmentData['preferredWorkoutTypes'] as List<String>,
      onChanged: (values) {
        setState(() {
          _assessmentData['preferredWorkoutTypes'] = values;
        });
      },
    );
  }

  Widget _buildTimeAvailabilityPage() {
    return _buildSelectionPage(
      title: 'How much time can you dedicate per workout?',
      subtitle: 'Choose what works best for your schedule',
      options: _timeOptions,
      selectedValue: _assessmentData['availableTime'],
      onChanged: (value) {
        setState(() {
          _assessmentData['availableTime'] = value;
        });
      },
    );
  }

  Widget _buildEquipmentPage() {
    return _buildMultiSelectionPage(
      title: 'What equipment do you have access to?',
      subtitle: 'Select all that apply',
      options: _equipmentOptions,
      selectedValues: _assessmentData['equipment'] as List<String>,
      onChanged: (values) {
        setState(() {
          _assessmentData['equipment'] = values;
        });
      },
    );
  }

  Widget _buildLimitationsPage() {
    return _buildMultiSelectionPage(
      title: 'Do you have any physical limitations?',
      subtitle: 'This helps us recommend safe exercises',
      options: _limitationOptions,
      selectedValues: _assessmentData['limitations'] as List<String>,
      onChanged: (values) {
        setState(() {
          _assessmentData['limitations'] = values;
        });
      },
    );
  }

  Widget _buildSelectionPage({
    required String title,
    required String subtitle,
    required List<String> options,
    required String selectedValue,
    required Function(String) onChanged,
  }) {
    return Column(
      children: [
        // Header section with fixed height
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headline2.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodyText1.copyWith(
                  color: AppColors.darkGray,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Scrollable content
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedValue == option;

              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  title: Text(option, style: const TextStyle(fontSize: 12)),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 16,
                        )
                      : const Icon(Icons.radio_button_unchecked, size: 16),
                  onTap: () => onChanged(option),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectionPage({
    required String title,
    required String subtitle,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      children: [
        // Header section with fixed height
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headline2.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodyText1.copyWith(
                  color: AppColors.darkGray,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Scrollable content
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedValues.contains(option);

              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  title: Text(option, style: const TextStyle(fontSize: 12)),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_box,
                          color: AppColors.primary,
                          size: 16,
                        )
                      : const Icon(Icons.check_box_outline_blank, size: 16),
                  onTap: () {
                    final newValues = List<String>.from(selectedValues);
                    if (isSelected) {
                      newValues.remove(option);
                    } else {
                      newValues.add(option);
                    }
                    onChanged(newValues);
                  },
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _assessmentData['activityLevel'].toString().isNotEmpty;
      case 1:
        return _assessmentData['workoutFrequency'].toString().isNotEmpty;
      case 2:
        return _assessmentData['experienceLevel'].toString().isNotEmpty;
      case 3:
        return _assessmentData['primaryGoal'].toString().isNotEmpty;
      case 4:
        return (_assessmentData['preferredWorkoutTypes'] as List<String>)
            .isNotEmpty;
      case 5:
        return _assessmentData['availableTime'].toString().isNotEmpty;
      case 6:
        return (_assessmentData['equipment'] as List<String>).isNotEmpty;
      case 7:
        return (_assessmentData['limitations'] as List<String>).isNotEmpty;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
