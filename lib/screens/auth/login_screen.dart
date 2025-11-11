import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Navigation is handled by AuthWrapper when auth state changes
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.marginXLarge),

                // Logo or App Name
                Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                ),

                const SizedBox(height: AppDimensions.marginMedium),

                Text(
                  'Welcome Back',
                  style: AppTextStyles.headline1.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.marginSmall),

                Text(
                  'Sign in to continue your fitness journey',
                  style: AppTextStyles.bodyText1.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                        : AppColors.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.marginMedium),

                // Demo Credentials Info
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkPrimary.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    border: Border.all(
                      color: isDarkMode
                          ? AppColors.darkPrimary.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDarkMode
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimensions.marginSmall),
                          Text(
                            'Demo Credentials',
                            style: AppTextStyles.bodyText2.copyWith(
                              color: isDarkMode
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.marginSmall),
                      Text(
                        'Email: antinationalfornonindians@gmail.com\nPassword: 123456',
                        style: AppTextStyles.caption.copyWith(
                          color: isDarkMode
                              ? AppColors.darkOnBackground.withValues(
                                  alpha: 0.7,
                                )
                              : AppColors.darkGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.marginSmall),
                      TextButton(
                        onPressed: () {
                          _emailController.text =
                              'antinationalfornonindians@gmail.com';
                          _passwordController.text = '123456';
                        },
                        child: Text(
                          'Use Demo Credentials',
                          style: AppTextStyles.caption.copyWith(
                            color: isDarkMode
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.marginXLarge),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                          : AppColors.darkGray,
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color: isDarkMode
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? AppColors.darkOnBackground.withValues(alpha: 0.3)
                            : AppColors.darkGray.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? AppColors.darkError
                            : AppColors.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? AppColors.darkError
                            : AppColors.error,
                      ),
                    ),
                    fillColor: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.marginMedium),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                          : AppColors.darkGray,
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: isDarkMode
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: isDarkMode
                            ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                            : AppColors.darkGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? AppColors.darkOnBackground.withValues(alpha: 0.3)
                            : AppColors.darkGray.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? AppColors.darkError
                            : AppColors.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? AppColors.darkError
                            : AppColors.error,
                      ),
                    ),
                    fillColor: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? AppColors.darkPrimary
                        : AppColors.primary,
                    foregroundColor: isDarkMode
                        ? AppColors.darkOnPrimary
                        : AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode
                                  ? AppColors.darkOnPrimary
                                  : AppColors.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? AppColors.darkOnPrimary
                                : AppColors.onPrimary,
                          ),
                        ),
                ),

                const SizedBox(height: AppDimensions.marginMedium),

                // Forgot Password
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: isDarkMode
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyText1.copyWith(
                        color: isDarkMode
                            ? AppColors.darkOnBackground
                            : AppColors.onBackground,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.bodyText1.copyWith(
                          color: isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
