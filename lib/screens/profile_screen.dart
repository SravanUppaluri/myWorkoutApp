import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/theme_manager.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'goal_setting_form_screen.dart';
import 'progress_photos_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        // Debug: Print current user data
        if (user != null) {
          print('Profile screen - Current user goalData: ${user.goalData}');
          print('Profile screen - Current user goals: ${user.goals}');
          print('Profile screen - Current user motivation: ${user.motivation}');
        }

        if (user == null) {
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 64,
                    color: AppColors.darkGray,
                  ),
                  const SizedBox(height: AppDimensions.marginMedium),
                  Text(
                    'No user information available',
                    style: AppTextStyles.headline3.copyWith(
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(height: AppDimensions.marginMedium),

                      // User Name
                      Text(
                        user.displayName,
                        style: AppTextStyles.headline2.copyWith(
                          color: isDarkMode
                              ? AppColors.darkOnBackground
                              : AppColors.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppDimensions.marginSmall),

                      // User Email
                      Text(
                        user.email,
                        style: AppTextStyles.bodyText1.copyWith(
                          color: isDarkMode
                              ? AppColors.darkOnBackground.withOpacity(0.7)
                              : AppColors.darkGray,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppDimensions.marginSmall),

                      // User Info Chips
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.fitnessLevel.isNotEmpty)
                            Chip(
                              label: Text(user.fitnessLevel),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              labelStyle: const TextStyle(
                                color: AppColors.primary,
                              ),
                            ),
                          if (user.age > 0)
                            Chip(
                              label: Text('${user.age} years'),
                              backgroundColor: AppColors.secondary.withOpacity(
                                0.1,
                              ),
                              labelStyle: const TextStyle(
                                color: AppColors.secondary,
                              ),
                            ),
                          if (user.weight > 0)
                            Chip(
                              label: Text(
                                '${user.weight.toStringAsFixed(1)} kg',
                              ),
                              backgroundColor: AppColors.secondary.withOpacity(
                                0.1,
                              ),
                              labelStyle: const TextStyle(
                                color: AppColors.secondary,
                              ),
                            ),
                        ],
                      ),

                      // Member since
                      const SizedBox(height: AppDimensions.marginSmall),
                      Text(
                        'Member since ${_formatDate(user.createdAt)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.darkGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Fitness Goals Section (if user has goals)
                if (user.goals.isNotEmpty) ...[
                  _buildSectionTitle('Fitness Goals'),
                  const SizedBox(height: AppDimensions.marginMedium),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppDimensions.paddingMedium,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.goals
                            .map(
                              (goal) => Chip(
                                label: Text(goal),
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                labelStyle: const TextStyle(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.marginLarge),
                ],

                // Settings Section
                _buildSectionTitle('Settings'),
                const SizedBox(height: AppDimensions.marginMedium),

                // Theme Toggle
                Consumer<ThemeManager>(
                  builder: (context, themeManager, child) {
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          themeManager.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          'Dark Mode ${themeManager.isDarkMode ? '(On)' : '(Off)'}',
                        ),
                        trailing: Switch(
                          value: themeManager.isDarkMode,
                          onChanged: (value) {
                            // Simple toggle between light and dark mode
                            themeManager.setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.marginSmall),

                // Notifications Setting
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: AppColors.primary,
                    ),
                    title: const Text('Notifications'),
                    trailing: Switch(
                      value: true, // This would come from user preferences
                      onChanged: (value) {
                        // Handle notification toggle
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings coming soon!'),
                          ),
                        );
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Account Section
                _buildSectionTitle('Account'),
                const SizedBox(height: AppDimensions.marginMedium),

                // Edit Profile
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.marginSmall),

                // Fitness Assessment
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.flag,
                      color: AppColors.forestGreen,
                    ),
                    title: const Text('Fitness Goals'),
                    subtitle: Text(
                      (user.hasCompletedOnboarding || user.goalData != null)
                          ? 'Update your fitness goals'
                          : 'Set your fitness goals',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to goal setting form
                      print('User goal data being passed: ${user.goalData}');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GoalSettingFormScreen(
                            assessmentData:
                                const {}, // Empty since no assessment
                            existingGoalData:
                                user.goalData, // Pass existing goal data
                            onComplete: (goalData) async {
                              print('Goal data received from form: $goalData');
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              final currentUser = authProvider.user!;

                              final updatedUser = currentUser.copyWith(
                                goalData: goalData,
                                motivation: goalData['motivation'],
                                goals:
                                    goalData['specificGoals'] as List<String>?,
                                hasCompletedOnboarding: true,
                              );

                              print(
                                'Updating user with: goalData=${updatedUser.goalData}, goals=${updatedUser.goals}',
                              );
                              await authProvider.updateUserProfile(updatedUser);

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      user.goalData != null
                                          ? 'Goals updated successfully!'
                                          : 'Goals set successfully!',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.marginSmall),

                // Progress Photos
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.photo_camera,
                      color: AppColors.steelBlue,
                    ),
                    title: const Text('Progress Photos'),
                    subtitle: const Text('Track your transformation'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProgressPhotosScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.marginSmall),

                // Privacy Policy
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.privacy_tip,
                      color: AppColors.primary,
                    ),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy policy coming soon!'),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.marginSmall),

                // Terms of Service
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.description,
                      color: AppColors.primary,
                    ),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to terms of service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terms of service coming soon!'),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Logout Button
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sign Out'),
                    onTap: () {
                      _showLogoutDialog(context, authProvider);
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // App Version
                Text(
                  'App Version 1.0.0',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                authProvider.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
