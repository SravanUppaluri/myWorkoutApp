import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(
        _nameController.text.trim(),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.marginLarge),

                // Logo or App Name
                const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: AppColors.primary,
                ),

                const SizedBox(height: AppDimensions.marginMedium),

                Text(
                  'Create Account',
                  style: AppTextStyles.headline1.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.marginSmall),

                Text(
                  'Join us and start your fitness journey today',
                  style: AppTextStyles.bodyText1.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface.withOpacity(0.7)
                        : AppColors.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.marginXLarge),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.darkGray,
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.darkGray,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.marginMedium),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.darkGray,
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.darkGray,
                    ),
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
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.darkGray,
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.darkGray,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: isDarkMode
                            ? AppColors.darkOnSurface.withOpacity(0.7)
                            : AppColors.darkGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.marginMedium),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.darkGray,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.darkGray,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: isDarkMode
                            ? AppColors.darkOnSurface.withOpacity(0.7)
                            : AppColors.darkGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: AppDimensions.marginLarge),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyText1.copyWith(
                        color: isDarkMode
                            ? AppColors.darkOnSurface
                            : AppColors.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(
                        'Sign In',
                        style: AppTextStyles.bodyText1.copyWith(
                          color: AppColors.primary,
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
