import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/database_service.dart';
import '../services/exercise_ai_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  List<Exercise> _allExercises = []; // Store all exercises
  List<Exercise> _filteredExercises = []; // Store filtered exercises
  final List<WorkoutExercise> _selectedExercises = [];
  bool _isLoading = false;
  bool _isAISearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ExerciseAIService _aiService = ExerciseAIService();

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load all exercises from the database
      final QuerySnapshot snapshot = await DatabaseService.exercises.get();

      if (!mounted) return;

      final List<Exercise> exercises = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        try {
          // Safely extract muscle groups
          List<String> muscleGroups = [];
          if (data['muscleGroups'] != null) {
            if (data['muscleGroups'] is List) {
              muscleGroups = List<String>.from(
                (data['muscleGroups'] as List).map((e) => e.toString()),
              );
            } else if (data['muscleGroups'] is String) {
              muscleGroups = [data['muscleGroups'] as String];
            }
          }
          if (muscleGroups.isEmpty) muscleGroups = ['General'];

          // Safely extract equipment
          List<String> equipment = [];
          if (data['equipment'] != null) {
            if (data['equipment'] is List) {
              equipment = List<String>.from(
                (data['equipment'] as List).map((e) => e.toString()),
              );
            } else if (data['equipment'] is String) {
              equipment = [data['equipment'] as String];
            }
          }
          if (equipment.isEmpty) equipment = ['None'];

          // Create a basic exercise with default values for the complex model
          return Exercise(
            id: doc.id,
            name: (data['name'] ?? '').toString(),
            category: (data['category'] ?? 'Strength').toString(),
            equipment: equipment,
            targetRegion: muscleGroups,
            primaryMuscles: muscleGroups,
            secondaryMuscles: const [],
            difficulty: (data['difficulty'] ?? 'Beginner').toString(),
            movementType: 'Compound',
            movementPattern: 'Push',
            gripType: 'Standard',
            rangeOfMotion: 'Full',
            tempo: 'Controlled',
            muscleGroup: muscleGroups.isNotEmpty
                ? muscleGroups.first
                : 'Full Body',
            muscleInfo: MuscleInfo(
              scientificName: 'N/A',
              commonName: muscleGroups.isNotEmpty
                  ? muscleGroups.first
                  : 'Full Body',
              muscleRegions: const [],
              primaryFunction: 'Movement',
              location: 'Body',
              muscleFiberDirection: 'Mixed',
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } catch (e) {
          logger.e('Error creating exercise ${doc.id}: $e');
          // Return a default exercise if there's an error
          return Exercise(
            id: doc.id,
            name: 'Unknown Exercise',
            category: 'Strength',
            equipment: const ['None'],
            targetRegion: const ['General'],
            primaryMuscles: const ['General'],
            secondaryMuscles: const [],
            difficulty: 'Beginner',
            movementType: 'Compound',
            movementPattern: 'Push',
            gripType: 'Standard',
            rangeOfMotion: 'Full',
            tempo: 'Controlled',
            muscleGroup: 'General',
            muscleInfo: MuscleInfo(
              scientificName: 'N/A',
              commonName: 'General',
              muscleRegions: const [],
              primaryFunction: 'Movement',
              location: 'Body',
              muscleFiberDirection: 'Mixed',
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }).toList();

      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises; // Initially show all exercises
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading exercises: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredExercises = _allExercises;
      } else {
        // Client-side filtering for better search experience
        _filteredExercises = _allExercises.where((exercise) {
          final exerciseName = exercise.name.toLowerCase();
          final searchLower = query.toLowerCase();
          final muscleGroups = exercise.primaryMuscles.join(' ').toLowerCase();
          final category = exercise.category.toLowerCase();

          // Search in name, muscle groups, and category
          return exerciseName.contains(searchLower) ||
              muscleGroups.contains(searchLower) ||
              category.contains(searchLower);
        }).toList();
      }
    });
  }

  /// Check if the search query looks like gibberish
  bool _isLikelyGibberish(String query) {
    final trimmed = query.trim();

    // Short inputs
    if (trimmed.length < 2) return true;

    // All numbers
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return true;

    // All special characters
    if (RegExp(r'^[^a-zA-Z\s]+$').hasMatch(trimmed)) return true;

    // Repeated characters
    if (RegExp(r'^(.)\1{2,}$').hasMatch(trimmed)) return true;

    // Common gibberish patterns
    final gibberishPatterns = [
      r'^[qwerty]+$',
      r'^[asdf]+$',
      r'^[zxcv]+$',
      r'^(test|testing|abc|xyz|demo)$',
      r'^[a-z]{1,2}$',
    ];

    return gibberishPatterns.any(
      (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(trimmed),
    );
  }

  void _toggleExerciseSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.any((e) => e.exercise.id == exercise.id)) {
        // If already selected, remove it
        _selectedExercises.removeWhere((e) => e.exercise.id == exercise.id);
      } else {
        // If not selected, show configuration dialog
        _showExerciseConfigurationDialog(exercise);
      }
    });
  }

  void _showExerciseConfigurationDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseConfigurationDialog(
        exercise: exercise,
        onExerciseConfigured: (configuredExercise) {
          setState(() {
            _selectedExercises.add(configuredExercise);
          });
        },
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedExercises.clear();
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedExercises);
  }

  Future<void> _searchWithAI(String exerciseName) async {
    if (exerciseName.trim().isEmpty) return;

    setState(() {
      _isAISearching = true;
    });

    try {
      final exercise = await _aiService.searchExerciseWithAI(
        exerciseName.trim(),
      );

      if (exercise != null) {
        // Refresh the exercise list to include the newly saved exercise
        await _fetchExercises();

        // Search again in the updated list to show the exercise
        _onSearchChanged(_searchQuery);

        setState(() {
          _isAISearching = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Found "${exercise.name}" using AI and saved to database!',
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Great!',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isAISearching = false;
        });

        if (mounted) {
          // More specific error message for invalid inputs
          final message = _isLikelyGibberish(exerciseName.trim())
              ? 'Please enter a valid exercise name (e.g., "push ups", "squat", "bicep curl")'
              : 'Could not find this exercise with AI. Try a different search term or check spelling.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAISearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Exercises (${_selectedExercises.length})'),
        actions: [
          if (_selectedExercises.isNotEmpty)
            TextButton(onPressed: _clearSelection, child: const Text('Clear')),
          if (_selectedExercises.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            color: AppColors.lightGray,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Selected exercises count
          if (_selectedExercises.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: AppDimensions.iconSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedExercises.length} exercise${_selectedExercises.length != 1 ? 's' : ''} selected',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Exercises List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty
                ? _buildEmptyState()
                : _buildExercisesList(),
          ),
        ],
      ),
      floatingActionButton: _selectedExercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _confirmSelection,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(Icons.check),
              label: Text('Add ${_selectedExercises.length}'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      if (_isAISearching) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: AppDimensions.marginMedium),
              Text('Searching with AI...', style: AppTextStyles.headline3),
              const SizedBox(height: AppDimensions.marginSmall),
              Text(
                'Looking for "$_searchQuery" in our AI database',
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.darkGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Text('No exercises found', style: AppTextStyles.headline3),
            const SizedBox(height: AppDimensions.marginSmall),
            Text(
              'Try searching for exercise name, muscle group, or category',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            // AI Search Section
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
              ),
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppDimensions.marginSmall),
                      Expanded(
                        child: Text(
                          'Try AI Search',
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.marginSmall),
                  Text(
                    'Can\'t find "$_searchQuery"? Let our AI help you discover this exercise and add it to your database!',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.marginMedium),
                  ElevatedButton.icon(
                    onPressed: () => _searchWithAI(_searchQuery),
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: Text('Find & Save with AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLarge,
                        vertical: AppDimensions.paddingSmall,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: AppColors.darkGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Text('Loading exercises...', style: AppTextStyles.headline3),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index];
        final isSelected = _selectedExercises.any(
          (e) => e.exercise.id == exercise.id,
        );

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? (isDarkMode
                    ? AppColors.darkPrimary.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1))
              : (isDarkMode ? AppColors.darkSurface : null),
          margin: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? (isDarkMode ? AppColors.darkPrimary : AppColors.primary)
                  : (isDarkMode
                        ? AppColors.darkOnSurface.withValues(alpha: 0.3)
                        : AppColors.lightGray.withValues(alpha: 0.3)),
              child: Icon(
                isSelected ? Icons.check : Icons.fitness_center,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.darkGray),
                size: 20,
              ),
            ),
            title: Text(
              exercise.name,
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isDarkMode
                    ? AppColors.darkOnSurface
                    : AppColors.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (exercise.primaryMuscles.isNotEmpty)
                  Text(
                    'Muscles: ${exercise.primaryMuscles.join(', ')}',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withValues(alpha: 0.8)
                          : AppColors.onSurface.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (exercise.equipment.isNotEmpty)
                  Text(
                    'Equipment: ${exercise.equipment.join(', ')}',
                    style: AppTextStyles.caption.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                          : AppColors.darkGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _toggleExerciseSelection(exercise),
          ),
        );
      },
    );
  }
}

class _ExerciseConfigurationDialog extends StatefulWidget {
  final Exercise exercise;
  final Function(WorkoutExercise) onExerciseConfigured;

  const _ExerciseConfigurationDialog({
    required this.exercise,
    required this.onExerciseConfigured,
  });

  @override
  State<_ExerciseConfigurationDialog> createState() =>
      _ExerciseConfigurationDialogState();
}

class _ExerciseConfigurationDialogState
    extends State<_ExerciseConfigurationDialog> {
  final TextEditingController _setsController = TextEditingController(
    text: '3',
  );
  final TextEditingController _repsController = TextEditingController(
    text: '10',
  );
  final TextEditingController _weightController = TextEditingController(
    text: '50',
  );
  final TextEditingController _restTimeController = TextEditingController(
    text: '60',
  );
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final sets = int.tryParse(_setsController.text) ?? 3;
    final reps = int.tryParse(_repsController.text) ?? 10;
    final weight = double.tryParse(_weightController.text) ?? 50.0;
    final restTime = int.tryParse(_restTimeController.text) ?? 60;
    final notes = _notesController.text;

    final workoutExercise = WorkoutExercise(
      exercise: widget.exercise,
      sets: sets,
      reps: reps,
      weight: weight,
      restTime: restTime,
      notes: notes,
    );

    widget.onExerciseConfigured(workoutExercise);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Exercise details
            Text(
              'Primary muscles: ${widget.exercise.primaryMuscles.join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                    : AppColors.darkGray,
              ),
            ),

            if (widget.exercise.secondaryMuscles.isNotEmpty)
              Text(
                'Secondary muscles: ${widget.exercise.secondaryMuscles.join(', ')}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                      : AppColors.darkGray,
                ),
              ),

            const SizedBox(height: 20),

            // Configuration Section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sets and Reps Configuration
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sets',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _setsController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  fillColor: isDarkMode
                                      ? AppColors.darkSurface
                                      : AppColors.surface,
                                  filled: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reps',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _repsController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  fillColor: isDarkMode
                                      ? AppColors.darkSurface
                                      : AppColors.surface,
                                  filled: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Weight and Rest Time Configuration
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Weight (kg)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _weightController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  fillColor: isDarkMode
                                      ? AppColors.darkSurface
                                      : AppColors.surface,
                                  filled: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rest Time (sec)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _restTimeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  fillColor: isDarkMode
                                      ? AppColors.darkSurface
                                      : AppColors.surface,
                                  filled: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Notes Configuration
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes (optional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add any notes for this exercise...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            fillColor: isDarkMode
                                ? AppColors.darkSurface
                                : AppColors.surface,
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Exercise'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
