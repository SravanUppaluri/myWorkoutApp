import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../screens/goal_setting_form_screen.dart';
import '../screens/edit_profile_screen.dart';

class OnboardingCoordinatorScreen extends StatefulWidget {
  final bool allowRetake;

  const OnboardingCoordinatorScreen({super.key, this.allowRetake = false});

  @override
  State<OnboardingCoordinatorScreen> createState() =>
      _OnboardingCoordinatorScreenState();
}

class _OnboardingCoordinatorScreenState
    extends State<OnboardingCoordinatorScreen> {
  int _currentStep = 0;
  final Map<String, dynamic> _collectedData = {};

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Profile Setup',
      description: 'Basic information about you',
      icon: Icons.person,
    ),
    OnboardingStep(
      title: 'Goal Setting',
      description: 'Define your fitness goals',
      icon: Icons.flag,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
    });
  }

  void _checkProfileCompletion() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      // If user has completed onboarding and this is not a retake, skip the entire flow
      if (user.hasCompletedOnboarding && !widget.allowRetake) {
        Navigator.of(context).pop(); // Go back to previous screen
        return;
      }

      // If profile is complete but onboarding isn't, skip to assessment
      if (_isProfileComplete(user)) {
        setState(() {
          _currentStep = 1; // Skip to fitness assessment
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Text(
                    'Welcome to Your Fitness Journey!',
                    style: AppTextStyles.headline1.copyWith(
                      fontSize: 20,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Let\'s set up your profile to personalize your experience',
                    style: AppTextStyles.bodyText1.copyWith(
                      fontSize: 12,
                      color: AppColors.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Progress Steps
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_steps.length, (index) {
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildStepIndicator(index)),
                        if (index < _steps.length - 1)
                          Container(
                            height: 2,
                            width: 20,
                            color: index < _currentStep
                                ? AppColors.primary
                                : Colors.grey[300],
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Current Step Content
            Expanded(child: _buildCurrentStepContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int index) {
    final step = _steps[index];
    final isCompleted = index < _currentStep;
    final isCurrent = index == _currentStep;

    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      backgroundColor = AppColors.primary;
      iconColor = Colors.white;
      textColor = AppColors.primary;
    } else if (isCurrent) {
      backgroundColor = AppColors.primary.withOpacity(0.2);
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    } else {
      backgroundColor = Colors.grey[300]!;
      iconColor = Colors.grey[600]!;
      textColor = Colors.grey[600]!;
    }

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : step.icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: AppDimensions.marginSmall),
        Text(
          step.title,
          style: AppTextStyles.caption.copyWith(
            color: textColor,
            fontWeight: isCurrent || isCompleted
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildProfileSetupStep();
      case 1:
        return GoalSettingFormScreen(
          assessmentData: const {}, // Empty since no assessment
          existingGoalData: null, // No existing data for new users
          onComplete: (completeData) {
            _completeOnboarding(completeData);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                children: [
                  Icon(Icons.person_add, size: 64, color: AppColors.primary),
                  const SizedBox(height: AppDimensions.marginMedium),
                  Text(
                    'Complete Your Profile',
                    style: AppTextStyles.headline2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.marginSmall),
                  Text(
                    'Add your basic information, physical metrics, and preferences to get started.',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: AppColors.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.marginLarge),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          )
                          .then((_) {
                            // Check if profile has been completed
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final user = authProvider.user;
                            if (user != null && _isProfileComplete(user)) {
                              setState(() {
                                _currentStep = 1;
                              });
                            }
                          });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLarge,
                        vertical: AppDimensions.paddingMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.marginMedium),

          // Skip option
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            child: Text(
              'Skip for now',
              style: TextStyle(color: AppColors.darkGray),
            ),
          ),
        ],
      ),
    );
  }

  bool _isProfileComplete(user) {
    return user.displayName.isNotEmpty &&
        user.age > 0 &&
        user.weight > 0 &&
        user.height > 0;
  }

  void _completeOnboarding(Map<String, dynamic> completeData) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user!;

      // Merge assessment data with goal data
      final allData = Map<String, dynamic>.from(_collectedData);
      allData.addAll(completeData);

      // Create enhanced user profile with goal data only
      final enhancedUser = currentUser.copyWith(
        goals:
            (completeData['specificGoals'] as List<String>?) ??
            currentUser.goals,
        hasCompletedOnboarding: true,
        goalData: completeData,
        motivation: completeData['motivation'],
      );

      await authProvider.updateUserProfile(enhancedUser);

      if (mounted) {
        // Show completion dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Setup Complete!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppDimensions.marginMedium),
                const Text(
                  'Your profile is all set up! You\'re ready to start your fitness journey.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to main app
                },
                child: const Text('Get Started!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
