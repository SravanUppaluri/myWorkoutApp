import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class DatabaseMigrationHelper extends StatelessWidget {
  const DatabaseMigrationHelper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(AppDimensions.marginMedium),
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sync, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Database Migration Helper',
                    style: AppTextStyles.headline3.copyWith(
                      fontSize: 16,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'If you\'re not seeing the assessment flag in your database, click the button below to manually sync your data.',
                style: AppTextStyles.bodyText2.copyWith(
                  fontSize: 12,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goals Status:',
                          style: AppTextStyles.bodyText2.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.goalData != null
                              ? 'Goals Set ✓'
                              : 'Goals Not Set ✗',
                          style: AppTextStyles.bodyText2.copyWith(
                            fontSize: 11,
                            color: user.goalData != null
                                ? AppColors.forestGreen
                                : AppColors.cardinalRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _migrateUserData(context, user.id),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _migrateUserData(BuildContext context, String userId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call migration
      final authService = AuthService();
      await authService.migrateUserData(userId);

      // Refresh user data
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Give time for database update

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data migration completed successfully!'),
            backgroundColor: AppColors.forestGreen,
          ),
        );

        // Trigger a refresh of the user data
        // Force a rebuild by calling setState in parent if possible
        // Or just wait for the next auth state change
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: AppColors.cardinalRed,
          ),
        );
      }
    }
  }
}
