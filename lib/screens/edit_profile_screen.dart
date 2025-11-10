import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  // Form values
  String _selectedFitnessLevel = 'Beginner';
  List<String> _selectedGoals = [];
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';

  bool _isLoading = false;

  // Fitness level options
  final List<String> _fitnessLevels = [
    'Complete beginner',
    'Some experience (under 1 year)',
    'Intermediate (1-3 years)',
    'Advanced (3+ years)',
    'Expert/Professional',
  ];

  // Goal options
  final List<String> _goalOptions = [
    'Weight Loss',
    'Muscle Gain',
    'Strength Training',
    'Endurance',
    'Flexibility',
    'General Fitness',
    'Sports Performance',
    'Rehabilitation',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;

    _nameController = TextEditingController(text: user.displayName);
    _ageController = TextEditingController(
      text: user.age > 0 ? user.age.toString() : '',
    );
    _weightController = TextEditingController(
      text: user.weight > 0 ? user.weight.toStringAsFixed(1) : '',
    );
    _heightController = TextEditingController(
      text: user.height > 0 ? user.height.toStringAsFixed(0) : '',
    );

    _selectedFitnessLevel =
        user.fitnessLevel.isNotEmpty &&
            _fitnessLevels.contains(user.fitnessLevel)
        ? user.fitnessLevel
        : _mapLegacyFitnessLevel(user.fitnessLevel);
    _selectedGoals = List.from(user.goals);
  }

  String _mapLegacyFitnessLevel(String legacyLevel) {
    // Map old fitness level values to new ones
    switch (legacyLevel.toLowerCase()) {
      case 'beginner':
        return 'Complete beginner';
      case 'intermediate':
        return 'Intermediate (1-3 years)';
      case 'advanced':
        return 'Advanced (3+ years)';
      case 'professional':
        return 'Expert/Professional';
      default:
        return 'Complete beginner'; // Default fallback
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                _buildProfilePictureSection(),

                const SizedBox(height: AppDimensions.marginLarge),

                // Basic Information
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: AppDimensions.marginMedium),
                _buildBasicInfoSection(),

                const SizedBox(height: AppDimensions.marginLarge),

                // Physical Metrics
                _buildSectionTitle('Physical Metrics'),
                const SizedBox(height: AppDimensions.marginMedium),
                _buildPhysicalMetricsSection(),

                const SizedBox(height: AppDimensions.marginLarge),

                // Fitness Information
                _buildSectionTitle('Fitness Information'),
                const SizedBox(height: AppDimensions.marginMedium),
                _buildFitnessInfoSection(),

                const SizedBox(height: AppDimensions.marginLarge),

                // Fitness Goals
                _buildSectionTitle('Fitness Goals'),
                const SizedBox(height: AppDimensions.marginMedium),
                _buildGoalsSection(),

                const SizedBox(height: AppDimensions.marginXLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headline3.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.headlineSmall?.color,
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user!;

        return Center(
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
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
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: AppColors.onPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          // TODO: Implement image picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Photo upload coming soon!'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.marginSmall),
              Text(
                'Tap camera to change photo',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake),
                suffixText: 'years',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 120) {
                    return 'Please enter a valid age (13-120)';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalMetricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          children: [
            // Weight input
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 1000) {
                          return 'Please enter a valid weight';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.marginSmall),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedWeightUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: ['kg', 'lbs'].map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWeightUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            // Height input
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final height = double.tryParse(value);
                        if (height == null || height <= 0 || height > 300) {
                          return 'Please enter a valid height';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.marginSmall),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedHeightUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: ['cm', 'ft'].map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHeightUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fitness Level',
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.marginSmall),
            DropdownButtonFormField<String>(
              value: _selectedFitnessLevel,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.fitness_center),
              ),
              items: _fitnessLevels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(
                    level,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFitnessLevel = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your fitness goals (multiple selection allowed)',
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalOptions.map((goal) {
                final isSelected = _selectedGoals.contains(goal);
                return FilterChip(
                  label: Text(goal),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGoals.add(goal);
                      } else {
                        _selectedGoals.remove(goal);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user!;

      // Convert weight and height to metric if needed
      double? weight;
      double? height;

      if (_weightController.text.isNotEmpty) {
        weight = double.parse(_weightController.text);
        if (_selectedWeightUnit == 'lbs') {
          weight = weight * 0.453592; // Convert lbs to kg
        }
      }

      if (_heightController.text.isNotEmpty) {
        height = double.parse(_heightController.text);
        if (_selectedHeightUnit == 'ft') {
          height = height * 30.48; // Convert ft to cm
        }
      }

      // Create updated user
      final updatedUser = currentUser.copyWith(
        displayName: _nameController.text.trim(),
        age: _ageController.text.isNotEmpty
            ? int.parse(_ageController.text)
            : 0,
        weight: weight ?? 0.0,
        height: height ?? 0.0,
        fitnessLevel: _selectedFitnessLevel,
        goals: _selectedGoals,
      );

      // Debug: Print selected goals to verify they're being saved
      print('Saving fitness goals: $_selectedGoals');

      // Update user profile
      await authProvider.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
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
}
