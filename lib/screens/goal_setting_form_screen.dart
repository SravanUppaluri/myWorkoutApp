import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GoalSettingFormScreen extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  final Function(Map<String, dynamic>) onComplete;
  final Map<String, dynamic>? existingGoalData;

  const GoalSettingFormScreen({
    super.key,
    required this.assessmentData,
    required this.onComplete,
    this.existingGoalData,
  });

  @override
  State<GoalSettingFormScreen> createState() => _GoalSettingFormScreenState();
}

class _GoalSettingFormScreenState extends State<GoalSettingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetWeightController = TextEditingController();
  final _motivationController = TextEditingController();

  // Goal data to collect
  String? _selectedWeightGoal;
  String? _selectedTimeframe;
  final List<String> _selectedSpecificGoals = [];

  // Predefined options
  final List<String> _weightGoals = [
    'Lose weight',
    'Gain weight',
    'Maintain current weight',
    'Not weight-focused',
  ];

  final List<String> _timeframes = [
    '1 month',
    '3 months',
    '6 months',
    '1 year',
    'Long-term (1+ years)',
  ];

  final List<String> _specificGoalOptions = [
    'Run a 5K',
    'Run a 10K',
    'Run a marathon',
    'Do 10 pull-ups',
    'Do 50 push-ups',
    'Hold a plank for 2 minutes',
    'Bench press bodyweight',
    'Squat my bodyweight',
    'Deadlift 1.5x bodyweight',
    'Touch my toes',
    'Learn a handstand',
    'Complete a triathlon',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with existing goal data if available
    _initializeExistingData();

    // Add listeners to text controllers to update button state
    _targetWeightController.addListener(() {
      setState(() {});
    });
    _motivationController.addListener(() {
      setState(() {});
    });
  }

  void _initializeExistingData() {
    if (widget.existingGoalData != null) {
      final existingData = widget.existingGoalData!;

      // Pre-populate weight goal
      if (existingData['weightGoal'] != null) {
        _selectedWeightGoal = existingData['weightGoal'];
      }

      // Pre-populate timeframe
      if (existingData['timeframe'] != null) {
        _selectedTimeframe = existingData['timeframe'];
      }

      // Pre-populate specific goals
      if (existingData['specificGoals'] != null) {
        _selectedSpecificGoals.clear();
        _selectedSpecificGoals.addAll(
          List<String>.from(existingData['specificGoals'] ?? []),
        );
      }

      // Pre-populate target weight
      if (existingData['targetWeight'] != null) {
        _targetWeightController.text = existingData['targetWeight'].toString();
      }

      // Pre-populate motivation
      if (existingData['motivation'] != null) {
        _motivationController.text = existingData['motivation'];
      }
    }
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingGoalData != null
              ? 'Update Fitness Goals'
              : 'Set Your Fitness Goals',
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                widget.existingGoalData != null
                    ? 'Update your fitness goals'
                    : 'Let\'s set your fitness goals',
                style: AppTextStyles.headline2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
              const SizedBox(height: AppDimensions.marginSmall),
              Text(
                widget.existingGoalData != null
                    ? 'Review and update your fitness goals as needed'
                    : 'Complete this form to personalize your workout experience',
                style: AppTextStyles.bodyText1.copyWith(
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: AppDimensions.marginLarge),

              // Weight Goal Section
              _buildSectionTitle('Weight Goal'),
              _buildWeightGoalSelection(),
              const SizedBox(height: AppDimensions.marginLarge),

              // Target Weight Section (conditional)
              if (_needsTargetWeight()) ...[
                _buildSectionTitle('Target Weight'),
                _buildTargetWeightInput(),
                const SizedBox(height: AppDimensions.marginLarge),
              ],

              // Timeframe Section
              _buildSectionTitle('Timeframe'),
              _buildTimeframeSelection(),
              const SizedBox(height: AppDimensions.marginLarge),

              // Specific Goals Section
              _buildSectionTitle('Specific Goals (Optional)'),
              Text(
                'Select any specific achievements you\'d like to work towards',
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: AppDimensions.marginSmall),
              _buildSpecificGoalsSelection(),
              const SizedBox(height: AppDimensions.marginLarge),

              // Motivation Section
              _buildSectionTitle('What Motivates You?'),
              _buildMotivationInput(),
              const SizedBox(height: AppDimensions.marginXLarge),

              // Complete Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canComplete() ? _completeGoalSetting : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                  ),
                  child: Text(
                    widget.existingGoalData != null
                        ? 'Update Goals'
                        : 'Complete Setup',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
      child: Text(
        title,
        style: AppTextStyles.headline3.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.headlineSmall?.color,
        ),
      ),
    );
  }

  Widget _buildWeightGoalSelection() {
    return Column(
      children: _weightGoals.map((goal) {
        final isSelected = _selectedWeightGoal == goal;
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
          child: Card(
            elevation: isSelected ? 2 : 1,
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
            child: ListTile(
              title: Text(goal),
              leading: Icon(
                _getWeightGoalIcon(goal),
                color: isSelected ? AppColors.primary : AppColors.darkGray,
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : const Icon(Icons.radio_button_unchecked),
              onTap: () {
                setState(() {
                  _selectedWeightGoal = goal;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetWeightInput() {
    return TextFormField(
      controller: _targetWeightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Target Weight (lbs)',
        hintText: 'Enter your target weight',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        prefixIcon: const Icon(Icons.monitor_weight),
        suffixText: 'lbs',
      ),
      validator: (value) {
        if (_needsTargetWeight() && (value == null || value.trim().isEmpty)) {
          return 'Please enter your target weight';
        }
        if (value != null && value.trim().isNotEmpty) {
          final weight = double.tryParse(value.trim());
          if (weight == null) {
            return 'Please enter a valid number';
          }
          if (weight <= 0 || weight > 1000) {
            return 'Please enter a realistic weight (1-1000 lbs)';
          }
        }
        return null;
      },
    );
  }

  Widget _buildTimeframeSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timeframes.map((timeframe) {
        final isSelected = _selectedTimeframe == timeframe;
        return FilterChip(
          label: Text(timeframe),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTimeframe = selected ? timeframe : null;
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildSpecificGoalsSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _specificGoalOptions.map((goal) {
        final isSelected = _selectedSpecificGoals.contains(goal);
        return FilterChip(
          label: Text(
            goal,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primary : null,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSpecificGoals.add(goal);
              } else {
                _selectedSpecificGoals.remove(goal);
              }
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          avatar: Icon(
            _getGoalIcon(goal),
            size: 16,
            color: isSelected ? AppColors.primary : AppColors.darkGray,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMotivationInput() {
    return TextFormField(
      controller: _motivationController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Your Motivation',
        hintText: 'What drives you to achieve your fitness goals?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        prefixIcon: const Icon(Icons.psychology),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please share what motivates you';
        }
        return null;
      },
    );
  }

  IconData _getWeightGoalIcon(String goal) {
    switch (goal) {
      case 'Lose weight':
        return Icons.trending_down;
      case 'Gain weight':
        return Icons.trending_up;
      case 'Maintain current weight':
        return Icons.trending_flat;
      default:
        return Icons.not_interested;
    }
  }

  IconData _getGoalIcon(String goal) {
    final goalLower = goal.toLowerCase();

    if (goalLower.contains('run')) return Icons.directions_run;
    if (goalLower.contains('pull-up') || goalLower.contains('push-up')) {
      return Icons.fitness_center;
    }
    if (goalLower.contains('plank') || goalLower.contains('handstand')) {
      return Icons.self_improvement;
    }
    if (goalLower.contains('triathlon')) return Icons.pool;
    if (goalLower.contains('bench') ||
        goalLower.contains('squat') ||
        goalLower.contains('deadlift')) {
      return Icons.fitness_center;
    }
    if (goalLower.contains('toes')) return Icons.accessibility_new;

    return Icons.flag;
  }

  bool _needsTargetWeight() {
    return _selectedWeightGoal == 'Lose weight' ||
        _selectedWeightGoal == 'Gain weight';
  }

  bool _canComplete() {
    final hasRequiredFields =
        _selectedWeightGoal != null &&
        _selectedTimeframe != null &&
        _motivationController.text.trim().isNotEmpty;

    if (!hasRequiredFields) return false;

    // Check target weight if needed
    if (_needsTargetWeight()) {
      final weightText = _targetWeightController.text.trim();
      if (weightText.isEmpty) return false;

      final weight = double.tryParse(weightText);
      if (weight == null || weight <= 0 || weight > 1000) return false;
    }

    return true;
  }

  void _completeGoalSetting() {
    if (!_formKey.currentState!.validate()) return;

    final goalData = {
      'weightGoal': _selectedWeightGoal,
      'timeframe': _selectedTimeframe,
      'specificGoals': List<String>.from(_selectedSpecificGoals),
      'motivation': _motivationController.text.trim(),
    };

    // Add target weight if needed and valid
    if (_needsTargetWeight() &&
        _targetWeightController.text.trim().isNotEmpty) {
      final targetWeight = double.tryParse(_targetWeightController.text.trim());
      if (targetWeight != null && targetWeight > 0) {
        goalData['targetWeight'] = targetWeight;
      }
    }

    // Combine with assessment data
    final completeData = {...widget.assessmentData, ...goalData};

    widget.onComplete(completeData);
  }
}
