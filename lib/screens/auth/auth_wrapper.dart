import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../home_screen.dart';
import '../../utils/constants.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        logger.e('AuthWrapper: Current status = ${authProvider.status}');
        logger.e('AuthWrapper: User = ${authProvider.user?.email ?? 'null'}');

        switch (authProvider.status) {
          case AuthStatus.loading:
          case AuthStatus.initial:
            logger.e('AuthWrapper: Showing loading screen');
            return const LoadingScreen();

          case AuthStatus.authenticated:
            logger.e('AuthWrapper: User authenticated, showing home screen');
            return const HomeScreen();

          case AuthStatus.unauthenticated:
            logger.e(
              'AuthWrapper: User not authenticated, showing login screen',
            );
            return const LoginScreen();
        }
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: const BoxDecoration(
                color: AppColors.onPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.marginXLarge),
            Text(
              AppStrings.appName,
              style: AppTextStyles.headline1.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Text(
              'Loading your workout data...',
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
