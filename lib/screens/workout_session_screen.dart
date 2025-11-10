import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';
import '../utils/constants.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../services/database_service.dart';

enum WorkoutViewType { classic, enhanced }

class WorkoutSessionScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutSessionScreen({super.key, required this.workout});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int _currentExerciseIndex = 0;
  List<List<Map<String, dynamic>>> _exerciseLogs = [];
  bool _isResting = false;
  int _restTimeRemaining = 0;
  DateTime? _workoutStartTime;
  List<Map<String, dynamic>> _completedExercises = [];
  WorkoutViewType _viewType = WorkoutViewType.classic;
  String _workoutNotes = '';
  final TextEditingController _notesController = TextEditingController();

  // New variables for enhanced functionality
  Timer? _workoutTimer;
  Timer? _restTimer;
  bool _useRestTimer = false;
  String _currentWorkoutTime = '00:00';

  // Confetti controllers for multiple directions
  late ConfettiController _confettiControllerTop;
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;
  late ConfettiController _confettiControllerBottomLeft;
  late ConfettiController _confettiControllerBottomRight;

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now();

    // For templates, start from the current exercise index
    if (widget.workout.isTemplate) {
      _currentExerciseIndex = widget.workout.currentExerciseIndex;
      if (_currentExerciseIndex < 0) _currentExerciseIndex = 0;
    }

    // Initialize logs for each exercise
    _exerciseLogs = widget.workout.exercises.map<List<Map<String, dynamic>>>((
      exercise,
    ) {
      return List<Map<String, dynamic>>.generate(
        exercise.sets,
        (index) => Map<String, dynamic>.from({
          'reps': exercise.reps,
          'weight': exercise.weight,
          'completed': false,
        }),
      );
    }).toList();

    // Initialize notes with current date-time
    final dateTimeStr = DateTime.now().toString();
    final dotIndex = dateTimeStr.indexOf('.');
    _workoutNotes = dotIndex != -1
        ? dateTimeStr.substring(0, dotIndex)
        : dateTimeStr;
    _notesController.text = _workoutNotes;

    // Initialize confetti controllers for multiple directions
    _confettiControllerTop = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiControllerLeft = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiControllerRight = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiControllerBottomLeft = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiControllerBottomRight = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    // Start workout timer
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _confettiControllerTop.dispose();
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    _confettiControllerBottomLeft.dispose();
    _confettiControllerBottomRight.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentWorkoutTime = _formatWorkoutTime();
        });
      }
    });
  }

  void _completeSet(int setIndex, [int? exerciseIndex]) {
    final targetExerciseIndex = exerciseIndex ?? _currentExerciseIndex;

    setState(() {
      _exerciseLogs[targetExerciseIndex][setIndex]['completed'] = true;
    });

    // For supersets, check if all exercises in the superset have completed the current set
    if (_isCurrentExerciseInSuperset()) {
      final currentExerciseGroup = _getCurrentExerciseGroup();
      bool allSupersetExercisesCompletedSet = true;

      for (final exercise in currentExerciseGroup) {
        final exerciseIdx = widget.workout.exercises.indexOf(exercise);
        if (!_exerciseLogs[exerciseIdx][setIndex]['completed']) {
          allSupersetExercisesCompletedSet = false;
          break;
        }
      }

      // If all exercises in superset completed this set, check if all sets are done
      if (allSupersetExercisesCompletedSet) {
        bool allSupersetSetsCompleted = true;
        for (final exercise in currentExerciseGroup) {
          final exerciseIdx = widget.workout.exercises.indexOf(exercise);
          if (!_exerciseLogs[exerciseIdx].every(
            (set) => set['completed'] == true,
          )) {
            allSupersetSetsCompleted = false;
            break;
          }
        }

        if (allSupersetSetsCompleted) {
          _moveToNextExercise();
        } else if (_useRestTimer) {
          _startRest();
        }
      }
    } else {
      // Regular single exercise logic
      final allSetsCompleted = _exerciseLogs[targetExerciseIndex].every(
        (set) => set['completed'] == true,
      );

      if (allSetsCompleted) {
        _moveToNextExercise();
      } else if (_useRestTimer) {
        _startRest();
      }
    }
    // If rest timer is disabled, user can continue at their own pace
  }

  void _startRest() {
    if (!_useRestTimer) return; // Skip rest if disabled

    setState(() {
      _isResting = true;
      _restTimeRemaining =
          widget.workout.exercises[_currentExerciseIndex].restTime;
    });

    // Use proper timer instead of recursive Future.delayed
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 0) {
        setState(() {
          _restTimeRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isResting = false;
        });
      }
    });
  }

  void _playAllConfetti() {
    _confettiControllerTop.play();
    _confettiControllerLeft.play();
    _confettiControllerRight.play();
    _confettiControllerBottomLeft.play();
    _confettiControllerBottomRight.play();
  }

  void _moveToNextExercise() async {
    // Trigger small confetti for exercise completion
    _confettiControllerTop.play();

    // If this is a template workout, update the template progression
    if (widget.workout.isTemplate) {
      await _updateTemplateProgression();
    }

    final nextIndex = _getNextExerciseIndex();

    if (nextIndex < widget.workout.exercises.length) {
      setState(() {
        _currentExerciseIndex = nextIndex;
        _isResting = false;
      });
    } else {
      _completeWorkout();
    }
  }

  Future<void> _updateTemplateProgression() async {
    try {
      print(
        'DEBUG: Updating template progression for workout: ${widget.workout.id}',
      );
      print(
        'DEBUG: Current exercise index: ${widget.workout.currentExerciseIndex}',
      );
      print('DEBUG: Total exercises: ${widget.workout.exercises.length}');

      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );

      // Update the template to mark current exercise as completed and move to next
      final updatedTemplate = widget.workout.completeCurrentExercise();

      print(
        'DEBUG: Updated template exercises count: ${updatedTemplate.exercises.length}',
      );

      if (updatedTemplate.exercises.isEmpty) {
        // Template is completed, delete it
        print('DEBUG: Deleting completed template: ${widget.workout.id}');
        await workoutProvider.deleteWorkout(widget.workout.id);
      } else {
        // Update the template with the next exercise
        print('DEBUG: Updating template with next exercise');
        await workoutProvider.updateWorkout(updatedTemplate);
      }
    } catch (e) {
      print('Error updating template progression: $e');
    }
  }

  void _completeWorkout() async {
    // Calculate workout duration
    final duration = DateTime.now().difference(_workoutStartTime!).inSeconds;

    // Prepare completed exercises data
    _completedExercises = [];
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final workoutExercise = widget.workout.exercises[i];
      final sets = _exerciseLogs[i];

      _completedExercises.add({
        'exerciseId': workoutExercise.exercise.id,
        'exerciseName': workoutExercise.exercise.name,
        'sets': sets
            .map(
              (set) => {
                'reps': set['reps'],
                'weight': set['weight'],
                'completed': set['completed'],
              },
            )
            .toList(),
      });
    }

    try {
      // If this is a template workout, mark it as completed
      if (widget.workout.isTemplate) {
        print('DEBUG: Completing template workout: ${widget.workout.id}');
        print(
          'DEBUG: Template exercises count: ${widget.workout.exercises.length}',
        );
        final workoutProvider = Provider.of<WorkoutProvider>(
          context,
          listen: false,
        );
        await workoutProvider.deleteWorkout(widget.workout.id);
        print('DEBUG: Template deleted successfully');
      }

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? 'unknown_user';

      // Save workout session to database
      await DatabaseService.recordWorkoutSession(
        userId: userId,
        workoutId: widget.workout.id,
        duration: duration,
        completedExercises: _completedExercises,
        notes: _workoutNotes.isEmpty
            ? () {
                final dateTimeStr = DateTime.now().toString();
                final dotIndex = dateTimeStr.indexOf('.');
                return dotIndex != -1
                    ? dateTimeStr.substring(0, dotIndex)
                    : dateTimeStr;
              }()
            : _workoutNotes,
      );

      // Show success dialog
      if (mounted) {
        // Trigger massive confetti celebration from all sides
        _playAllConfetti();

        final stats = _calculateWorkoutStatistics();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Stack(
            children: [
              AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.celebration, color: AppColors.primary, size: 28),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Workout Complete!',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Congratulations on completing your workout!',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Primary Stats
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              Icons.timer,
                              'Duration',
                              _formatDuration(duration),
                            ),
                            const SizedBox(height: 8),
                            _buildStatRow(
                              Icons.fitness_center,
                              'Total Volume',
                              '${stats['totalVolume'].toStringAsFixed(0)} kg',
                            ),
                            const SizedBox(height: 8),
                            _buildStatRow(
                              Icons.check_circle,
                              'Sets Completed',
                              '${stats['completedSets']}/${stats['totalSets']}',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Detailed Stats
                      const Text(
                        'Workout Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildDetailStatRow(
                        'Total Reps',
                        '${stats['totalReps']}',
                      ),
                      _buildDetailStatRow(
                        'Exercises',
                        '${widget.workout.exercises.length}',
                      ),
                      _buildDetailStatRow(
                        'Completion Rate',
                        '${stats['completionPercentage'].toStringAsFixed(1)}%',
                      ),
                      if (stats['heaviestWeight'] > 0)
                        _buildDetailStatRow(
                          'Heaviest Weight',
                          '${stats['heaviestWeight'].toStringAsFixed(1)} kg',
                        ),

                      if (stats['topVolumeExercise'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Top Volume Exercise',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${stats['topVolumeExercise']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${stats['topVolume'].toStringAsFixed(0)} kg total volume',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Return to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Finish',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // Confetti overlays over the dialog
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      // Top center confetti over dialog
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiControllerTop,
                          blastDirection: 1.5708, // pi/2 - downward
                          particleDrag: 0.05,
                          emissionFrequency: 0.02,
                          numberOfParticles: 80,
                          gravity: 0.05,
                          shouldLoop: false,
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                            Colors.yellow,
                            Colors.orange,
                            Colors.pink,
                            Colors.purple,
                          ],
                          createParticlePath: (size) {
                            final path = Path();
                            path.addOval(
                              Rect.fromCircle(center: Offset.zero, radius: 6),
                            );
                            return path;
                          },
                        ),
                      ),
                      // Left side confetti over dialog
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ConfettiWidget(
                          confettiController: _confettiControllerLeft,
                          blastDirection: 0, // 0 - rightward
                          particleDrag: 0.05,
                          emissionFrequency: 0.02,
                          numberOfParticles: 50,
                          gravity: 0.05,
                          shouldLoop: false,
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                            Colors.yellow,
                            Colors.orange,
                            Colors.pink,
                            Colors.purple,
                          ],
                          createParticlePath: (size) {
                            final path = Path();
                            path.addOval(
                              Rect.fromCircle(center: Offset.zero, radius: 5),
                            );
                            return path;
                          },
                        ),
                      ),
                      // Right side confetti over dialog
                      Align(
                        alignment: Alignment.centerRight,
                        child: ConfettiWidget(
                          confettiController: _confettiControllerRight,
                          blastDirection: 3.14159, // pi - leftward
                          particleDrag: 0.05,
                          emissionFrequency: 0.02,
                          numberOfParticles: 50,
                          gravity: 0.05,
                          shouldLoop: false,
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                            Colors.yellow,
                            Colors.orange,
                            Colors.pink,
                            Colors.purple,
                          ],
                          createParticlePath: (size) {
                            final path = Path();
                            path.addOval(
                              Rect.fromCircle(center: Offset.zero, radius: 5),
                            );
                            return path;
                          },
                        ),
                      ),
                      // Bottom left corner confetti over dialog
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: ConfettiWidget(
                          confettiController: _confettiControllerBottomLeft,
                          blastDirection: -0.7854, // -pi/4 - up-right diagonal
                          particleDrag: 0.05,
                          emissionFrequency: 0.02,
                          numberOfParticles: 45,
                          gravity: 0.05,
                          shouldLoop: false,
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                            Colors.yellow,
                            Colors.orange,
                            Colors.pink,
                            Colors.purple,
                          ],
                          createParticlePath: (size) {
                            final path = Path();
                            path.addOval(
                              Rect.fromCircle(center: Offset.zero, radius: 5),
                            );
                            return path;
                          },
                        ),
                      ),
                      // Bottom right corner confetti over dialog
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ConfettiWidget(
                          confettiController: _confettiControllerBottomRight,
                          blastDirection: -2.3562, // -3*pi/4 - up-left diagonal
                          particleDrag: 0.05,
                          emissionFrequency: 0.02,
                          numberOfParticles: 45,
                          gravity: 0.05,
                          shouldLoop: false,
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                            Colors.yellow,
                            Colors.orange,
                            Colors.pink,
                            Colors.purple,
                          ],
                          createParticlePath: (size) {
                            final path = Path();
                            path.addOval(
                              Rect.fromCircle(center: Offset.zero, radius: 5),
                            );
                            return path;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save workout: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  Map<String, dynamic> _calculateWorkoutStatistics() {
    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;
    int completedSets = 0;
    double heaviestWeight = 0;
    Map<String, double> exerciseVolumes = {};
    Map<String, double> exerciseMaxWeights = {};

    for (int i = 0; i < _exerciseLogs.length; i++) {
      final exerciseName = widget.workout.exercises[i].exercise.name;
      double exerciseVolume = 0;
      double exerciseMaxWeight = 0;

      for (final setLog in _exerciseLogs[i]) {
        totalSets++;
        if (setLog['completed'] == true) {
          completedSets++;
          final weight = (setLog['weight'] as num).toDouble();
          final reps = (setLog['reps'] as num).toInt();
          final setVolume = weight * reps;

          totalVolume += setVolume;
          exerciseVolume += setVolume;
          totalReps += reps;

          if (weight > heaviestWeight) {
            heaviestWeight = weight;
          }
          if (weight > exerciseMaxWeight) {
            exerciseMaxWeight = weight;
          }
        }
      }

      if (exerciseVolume > 0) {
        exerciseVolumes[exerciseName] = exerciseVolume;
        exerciseMaxWeights[exerciseName] = exerciseMaxWeight;
      }
    }

    // Calculate completion percentage
    final completionPercentage = totalSets > 0
        ? (completedSets / totalSets * 100)
        : 0.0;

    // Find top volume exercise
    String topVolumeExercise = '';
    double topVolume = 0;
    exerciseVolumes.forEach((exercise, volume) {
      if (volume > topVolume) {
        topVolume = volume;
        topVolumeExercise = exercise;
      }
    });

    return {
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'completedSets': completedSets,
      'totalReps': totalReps,
      'heaviestWeight': heaviestWeight,
      'completionPercentage': completionPercentage,
      'topVolumeExercise': topVolumeExercise,
      'topVolume': topVolume,
      'exerciseVolumes': exerciseVolumes,
      'exerciseMaxWeights': exerciseMaxWeights,
    };
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDetailStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnSurface.withOpacity(0.8)
                  : AppColors.darkGray,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restTimeRemaining = 0;
    });
  }

  // Superset helper methods
  List<WorkoutExercise> _getCurrentExerciseGroup() {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];

    if (currentExercise.isInSuperset) {
      // Find all exercises in the same superset
      return widget.workout.exercises
          .where(
            (exercise) => exercise.supersetId == currentExercise.supersetId,
          )
          .toList();
    } else {
      // Return single exercise as a list
      return [currentExercise];
    }
  }

  bool _isCurrentExerciseInSuperset() {
    return widget.workout.exercises[_currentExerciseIndex].isInSuperset;
  }

  int _getNextExerciseIndex() {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];

    if (currentExercise.isInSuperset) {
      // Find the last exercise in the current superset and move past it
      final supersetId = currentExercise.supersetId!;
      int lastSupersetIndex = _currentExerciseIndex;

      for (
        int i = _currentExerciseIndex + 1;
        i < widget.workout.exercises.length;
        i++
      ) {
        if (widget.workout.exercises[i].supersetId == supersetId) {
          lastSupersetIndex = i;
        } else {
          break;
        }
      }

      return lastSupersetIndex + 1;
    } else {
      // Move to next single exercise
      return _currentExerciseIndex + 1;
    }
  }

  String _getSupersetLabel() {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    if (currentExercise.isInSuperset) {
      return currentExercise.supersetLabel ?? 'Superset';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Handle case where workout has no exercises
    if (widget.workout.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Session')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'No exercises found in this workout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'The AI was unable to generate exercises for this workout. Please try again.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          body: _isResting
              ? _buildRestScreen()
              : (_viewType == WorkoutViewType.classic
                    ? _buildClassicExerciseScreenWithCollapsible()
                    : _buildEnhancedExerciseScreen()),
        ),
        // Confetti overlays from all sides
        // Top center confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiControllerTop,
            blastDirection: 1.5708, // pi/2 - downward
            particleDrag: 0.05,
            emissionFrequency: 0.03,
            numberOfParticles: 60,
            gravity: 0.05,
            shouldLoop: false,
            colors: [
              AppColors.primary,
              AppColors.secondary,
              Colors.yellow,
              Colors.orange,
              Colors.pink,
              Colors.purple,
            ],
            createParticlePath: (size) {
              final path = Path();
              path.addOval(Rect.fromCircle(center: Offset.zero, radius: 5));
              return path;
            },
          ),
        ),
        // Left side confetti
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _confettiControllerLeft,
            blastDirection: 0, // 0 - rightward
            particleDrag: 0.05,
            emissionFrequency: 0.03,
            numberOfParticles: 40,
            gravity: 0.05,
            shouldLoop: false,
            colors: [
              AppColors.primary,
              AppColors.secondary,
              Colors.yellow,
              Colors.orange,
              Colors.pink,
              Colors.purple,
            ],
            createParticlePath: (size) {
              final path = Path();
              path.addOval(Rect.fromCircle(center: Offset.zero, radius: 4));
              return path;
            },
          ),
        ),
        // Right side confetti
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _confettiControllerRight,
            blastDirection: 3.14159, // pi - leftward
            particleDrag: 0.05,
            emissionFrequency: 0.03,
            numberOfParticles: 40,
            gravity: 0.05,
            shouldLoop: false,
            colors: [
              AppColors.primary,
              AppColors.secondary,
              Colors.yellow,
              Colors.orange,
              Colors.pink,
              Colors.purple,
            ],
            createParticlePath: (size) {
              final path = Path();
              path.addOval(Rect.fromCircle(center: Offset.zero, radius: 4));
              return path;
            },
          ),
        ),
        // Bottom left corner confetti
        Align(
          alignment: Alignment.bottomLeft,
          child: ConfettiWidget(
            confettiController: _confettiControllerBottomLeft,
            blastDirection: -0.7854, // -pi/4 - up-right diagonal
            particleDrag: 0.05,
            emissionFrequency: 0.03,
            numberOfParticles: 35,
            gravity: 0.05,
            shouldLoop: false,
            colors: [
              AppColors.primary,
              AppColors.secondary,
              Colors.yellow,
              Colors.orange,
              Colors.pink,
              Colors.purple,
            ],
            createParticlePath: (size) {
              final path = Path();
              path.addOval(Rect.fromCircle(center: Offset.zero, radius: 4));
              return path;
            },
          ),
        ),
        // Bottom right corner confetti
        Align(
          alignment: Alignment.bottomRight,
          child: ConfettiWidget(
            confettiController: _confettiControllerBottomRight,
            blastDirection: -2.3562, // -3*pi/4 - up-left diagonal
            particleDrag: 0.05,
            emissionFrequency: 0.03,
            numberOfParticles: 35,
            gravity: 0.05,
            shouldLoop: false,
            colors: [
              AppColors.primary,
              AppColors.secondary,
              Colors.yellow,
              Colors.orange,
              Colors.pink,
              Colors.purple,
            ],
            createParticlePath: (size) {
              final path = Path();
              path.addOval(Rect.fromCircle(center: Offset.zero, radius: 4));
              return path;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClassicExerciseScreenWithCollapsible() {
    final currentExerciseGroup = _getCurrentExerciseGroup();
    final isSuperset = _isCurrentExerciseInSuperset();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Collapsible Header
        SliverAppBar(
          expandedHeight: 220,
          floating: false,
          pinned: true,
          backgroundColor: isDarkMode
              ? AppColors.darkSurface
              : AppColors.surface,
          actions: [
            // View Toggle Button
            IconButton(
              onPressed: () {
                setState(() {
                  _viewType = _viewType == WorkoutViewType.classic
                      ? WorkoutViewType.enhanced
                      : WorkoutViewType.classic;
                });
              },
              icon: Icon(
                _viewType == WorkoutViewType.classic
                    ? Icons.view_list
                    : Icons.view_agenda,
              ),
              tooltip: _viewType == WorkoutViewType.classic
                  ? 'Switch to Enhanced View'
                  : 'Switch to Classic View',
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('End Workout'),
                    content: const Text(
                      'Are you sure you want to end this workout session?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Continue'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Return to previous screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('End'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('End'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDarkMode ? AppColors.darkSurface : AppColors.surface,
                    isDarkMode
                        ? AppColors.darkBackground
                        : AppColors.background,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Workout Name at the top
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: Text(
                          widget.workout.name,
                          style: AppTextStyles.headline1.copyWith(
                            color: isDarkMode
                                ? AppColors.darkOnSurface
                                : AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Progress Bar
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Exercise ${_currentExerciseIndex + 1} of ${widget.workout.exercises.length}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentWorkoutTime,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value:
                                  (_currentExerciseIndex + 1) /
                                  widget.workout.exercises.length,
                              backgroundColor: AppColors.lightGray,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              minHeight: 4,
                            ),
                          ],
                        ),
                      ),

                      // Exercise Info - Handle both single exercises and supersets
                      if (isSuperset) ...[
                        // Superset Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_work,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SUPERSET ${_getSupersetLabel()}',
                                    style: AppTextStyles.headline3.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Display all exercises in the superset
                              Column(
                                children: currentExerciseGroup.map((exercise) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              exercise.supersetLabel ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            exercise.exercise.name,
                                            style: AppTextStyles.bodyText1
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Single Exercise Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            currentExerciseGroup.first.exercise.name,
                            style: AppTextStyles.headline2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (currentExerciseGroup
                            .first
                            .exercise
                            .primaryMuscles
                            .isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.marginSmall),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.my_library_books,
                                size: 14,
                                color: AppColors.darkGray,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  currentExerciseGroup
                                      .first
                                      .exercise
                                      .primaryMuscles
                                      .join(', '),
                                  style: AppTextStyles.bodyText2.copyWith(
                                    color: AppColors.darkGray,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Exercise content - Handle both single exercises and supersets
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          sliver: isSuperset
              ? _buildSupersetContent(currentExerciseGroup)
              : _buildSingleExerciseContent(currentExerciseGroup.first),
        ),

        // Add Set Button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  final currentExercise =
                      widget.workout.exercises[_currentExerciseIndex];
                  final Map<String, dynamic> newSet =
                      Map<String, dynamic>.from({
                        'reps': currentExercise.reps,
                        'weight': currentExercise.weight,
                        'completed': false,
                      });
                  _exerciseLogs[_currentExerciseIndex].add(newSet);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
            ),
          ),
        ),

        // Exercise Navigation Buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              children: [
                if (_currentExerciseIndex > 0)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentExerciseIndex--;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightGray,
                        foregroundColor: AppColors.darkGray,
                      ),
                    ),
                  ),
                if (_currentExerciseIndex > 0) const SizedBox(width: 16),

                // Next/Finish button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_currentExerciseIndex <
                          widget.workout.exercises.length - 1) {
                        _moveToNextExercise();
                      } else {
                        _completeWorkout();
                      }
                    },
                    icon: Icon(
                      _currentExerciseIndex <
                              widget.workout.exercises.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                    label: Text(
                      _currentExerciseIndex <
                              widget.workout.exercises.length - 1
                          ? 'Next Exercise'
                          : 'Finish Workout',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Extra spacing to ensure scrollable content
        SliverToBoxAdapter(
          child: SizedBox(
            height: 500,
          ), // Add some height to make scrolling possible
        ),
      ],
    );
  }

  Widget _buildSingleExerciseContent(WorkoutExercise exercise) {
    final exerciseIndex = widget.workout.exercises.indexOf(exercise);
    final exerciseLogs = _exerciseLogs[exerciseIndex];

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, setIndex) {
        final setLog = exerciseLogs[setIndex];
        final isCompleted = setLog['completed'];

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.marginMedium),
          elevation: isCompleted ? 4 : 1,
          color: isCompleted ? AppColors.primary.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCompleted
                  ? AppColors.primary
                  : AppColors.lightGray,
              child: Text(
                '${setIndex + 1}',
                style: TextStyle(
                  color: isCompleted ? AppColors.onPrimary : AppColors.darkGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: setLog['reps'].toString(),
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isCompleted,
                    onChanged: (value) {
                      setLog['reps'] = int.tryParse(value) ?? setLog['reps'];
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.marginMedium),
                Expanded(
                  child: TextFormField(
                    initialValue: setLog['weight'].toString(),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isCompleted,
                    onChanged: (value) {
                      setLog['weight'] =
                          double.tryParse(value) ?? setLog['weight'];
                    },
                  ),
                ),
              ],
            ),
            trailing: isCompleted
                ? Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: AppDimensions.iconLarge,
                  )
                : ElevatedButton(
                    onPressed: () => _completeSet(setIndex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: const Text('Complete'),
                  ),
          ),
        );
      }, childCount: exerciseLogs.length),
    );
  }

  Widget _buildSupersetContent(List<WorkoutExercise> exercises) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, setIndex) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.marginLarge),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Set header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SET ${setIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.marginMedium),

                // Build each exercise in the superset
                ...exercises.map((exercise) {
                  final exerciseIndex = widget.workout.exercises.indexOf(
                    exercise,
                  );
                  final setLog = _exerciseLogs[exerciseIndex][setIndex];
                  final isCompleted = setLog['completed'];

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: AppDimensions.marginSmall,
                    ),
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.primary
                            : AppColors.lightGray,
                        width: isCompleted ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.primary
                                    : AppColors.lightGray,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  exercise.supersetLabel ?? '',
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Colors.white
                                        : AppColors.darkGray,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                exercise.exercise.name,
                                style: AppTextStyles.bodyText1.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted ? AppColors.primary : null,
                                ),
                              ),
                            ),
                            if (isCompleted)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.marginSmall),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: setLog['reps'].toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                enabled: !isCompleted,
                                onChanged: (value) {
                                  setLog['reps'] =
                                      int.tryParse(value) ?? setLog['reps'];
                                },
                              ),
                            ),
                            const SizedBox(width: AppDimensions.marginSmall),
                            Expanded(
                              child: TextFormField(
                                initialValue: setLog['weight'].toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                enabled: !isCompleted,
                                onChanged: (value) {
                                  setLog['weight'] =
                                      double.tryParse(value) ??
                                      setLog['weight'];
                                },
                              ),
                            ),
                            const SizedBox(width: AppDimensions.marginSmall),
                            if (!isCompleted)
                              ElevatedButton(
                                onPressed: () =>
                                    _completeSet(setIndex, exerciseIndex),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  minimumSize: const Size(60, 36),
                                ),
                                child: const Text('✓'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }, childCount: exercises.first.sets),
    );
  }

  Widget _buildRestScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rest Time'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('End Workout'),
                  content: const Text(
                    'Are you sure you want to end this workout session?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continue'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Return to previous screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('End'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('End'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, size: 100, color: AppColors.primary),
            const SizedBox(height: AppDimensions.marginLarge),
            Text('Rest Time', style: AppTextStyles.headline2),
            const SizedBox(height: AppDimensions.marginMedium),
            Text(
              _formatTime(_restTimeRemaining),
              style: AppTextStyles.headline1.copyWith(
                fontSize: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _skipRest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightGray,
                    foregroundColor: AppColors.darkGray,
                  ),
                  child: const Text('Skip Rest'),
                ),
                const SizedBox(width: AppDimensions.marginMedium),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _restTimeRemaining += 30;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text('+30s'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedExerciseScreen() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    final currentLogs = _exerciseLogs[_currentExerciseIndex];

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Timer and Finish Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Power/Back Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.power_settings_new,
                          color: isDarkMode
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface,
                        ),
                      ),
                      // Timer
                      Text(
                        _currentWorkoutTime,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface,
                        ),
                      ),
                      // Finish Button
                      ElevatedButton(
                        onPressed: _allExercisesCompleted()
                            ? _completeWorkout
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Finish'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Workout Title and More Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.workout.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface,
                              ),
                            ),
                            Text(
                              _currentWorkoutTime,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? AppColors.darkOnSurface.withOpacity(0.7)
                                    : AppColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // View toggle (Enhanced -> Classic)
                      IconButton(
                        tooltip: 'Switch to Classic View',
                        onPressed: () {
                          setState(() {
                            _viewType = WorkoutViewType.classic;
                          });
                        },
                        icon: Icon(
                          Icons.view_list,
                          color: isDarkMode
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface,
                        ),
                      ),
                      // More options
                      IconButton(
                        onPressed: _showWorkoutMoreOptions,
                        icon: Icon(
                          Icons.more_horiz,
                          color: isDarkMode
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Notes Section
                  TextField(
                    controller: _notesController,
                    onChanged: (value) {
                      _workoutNotes = value;
                    },
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add workout notes...',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkOnSurface.withOpacity(0.5)
                            : AppColors.darkGray.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: isDarkMode
                          ? AppColors.darkBackground
                          : AppColors.lightGray.withOpacity(0.3),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rest Timer Option
                  Row(
                    children: [
                      Checkbox(
                        value: _useRestTimer,
                        onChanged: (value) {
                          setState(() {
                            _useRestTimer = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Text(
                          'Enable rest timer between sets',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? AppColors.darkOnSurface
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Current Exercise Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentExercise.exercise.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.steelBlue,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showExerciseTip,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: AppColors.orange,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Watch back rounding',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? AppColors.darkOnSurface
                                                : AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.touch_app,
                                        color: AppColors.orange,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                // Show exercise details
                              },
                              icon: Icon(
                                Icons.info_outline,
                                color: AppColors.steelBlue,
                              ),
                            ),
                            IconButton(
                              onPressed: _showExerciseMoreOptions,
                              icon: Icon(
                                Icons.more_horiz,
                                color: isDarkMode
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sets Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.darkSurface
                            : AppColors.lightGray,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 40), // For set number
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'kg',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? AppColors.darkOnSurface
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Reps',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? AppColors.darkOnSurface
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40), // For checkmark
                        ],
                      ),
                    ),

                    // Sets List
                    ...currentLogs.asMap().entries.map((entry) {
                      final setIndex = entry.key;
                      final setLog = entry.value;
                      final isCompleted = setLog['completed'] as bool;

                      return Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.darkSurface
                              : Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: isDarkMode
                                  ? AppColors.darkOnSurface.withOpacity(0.1)
                                  : AppColors.lightGray,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Set Number
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${setIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? AppColors.darkOnSurface
                                        : AppColors.onSurface,
                                  ),
                                ),
                              ),
                              // Previous (placeholder)
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${setLog['weight']} kg × ${setLog['reps']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? AppColors.darkOnSurface.withOpacity(
                                            0.6,
                                          )
                                        : AppColors.darkGray,
                                  ),
                                ),
                              ),
                              // Weight Input
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextFormField(
                                    initialValue: setLog['weight'].toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? AppColors.darkOnSurface
                                          : AppColors.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: isDarkMode
                                              ? AppColors.darkOnSurface
                                                    .withOpacity(0.3)
                                              : AppColors.darkGray.withOpacity(
                                                  0.3,
                                                ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: isDarkMode
                                              ? AppColors.darkOnSurface
                                                    .withOpacity(0.3)
                                              : AppColors.darkGray.withOpacity(
                                                  0.3,
                                                ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: AppColors.steelBlue,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      fillColor: isDarkMode
                                          ? AppColors.darkBackground
                                          : Colors.white,
                                      filled: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    enabled: !isCompleted,
                                    onChanged: (value) {
                                      setLog['weight'] =
                                          double.tryParse(value) ??
                                          setLog['weight'];
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Reps Input
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextFormField(
                                    initialValue: setLog['reps'].toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? AppColors.darkOnSurface
                                          : AppColors.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: isDarkMode
                                              ? AppColors.darkOnSurface
                                                    .withOpacity(0.3)
                                              : AppColors.darkGray.withOpacity(
                                                  0.3,
                                                ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: isDarkMode
                                              ? AppColors.darkOnSurface
                                                    .withOpacity(0.3)
                                              : AppColors.darkGray.withOpacity(
                                                  0.3,
                                                ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: AppColors.steelBlue,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      fillColor: isDarkMode
                                          ? AppColors.darkBackground
                                          : Colors.white,
                                      filled: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    enabled: !isCompleted,
                                    onChanged: (value) {
                                      setLog['reps'] =
                                          int.tryParse(value) ?? setLog['reps'];
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Check Button
                              SizedBox(
                                width: 40,
                                child: IconButton(
                                  onPressed: isCompleted
                                      ? null
                                      : () => _completeSet(setIndex),
                                  icon: Icon(
                                    isCompleted
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                    color: isCompleted
                                        ? AppColors.forestGreen
                                        : AppColors.darkGray,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Add Set Button
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            final Map<String, dynamic> newSet =
                                Map<String, dynamic>.from({
                                  'reps': currentExercise.reps,
                                  'weight': currentExercise.weight,
                                  'completed': false,
                                });
                            _exerciseLogs[_currentExerciseIndex].add(newSet);
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Set'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.steelBlue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cancel Workout'),
                              content: const Text(
                                'Are you sure you want to cancel this workout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(
                                      context,
                                    ); // Return to previous screen
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Cancel Workout'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Cancel Workout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWorkoutTime() {
    if (_workoutStartTime == null) return '00:00';
    final duration = DateTime.now().difference(_workoutStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool _allExercisesCompleted() {
    return _exerciseLogs.every(
      (exerciseLog) => exerciseLog.any((set) => set['completed'] == true),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showAddExercisesDialog() {
    print('Showing add exercise dialog');
    try {
      showDialog(
        context: context,
        builder: (context) {
          print('Building _AddExerciseDialog');
          return _AddExerciseDialog(
            onExerciseAdded: (exercise, sets, weights, reps) {
              print(
                'Exercise added: $exercise, sets: $sets, weights: $weights, reps: $reps',
              );
              _addExerciseToWorkout(exercise, sets, weights, reps);
            },
          );
        },
      );
    } catch (e) {
      print('Error showing dialog: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _addExerciseToWorkout(
    dynamic exercise,
    int sets,
    List<double> weights,
    int reps,
  ) {
    setState(() {
      // Create a new workout exercise
      final newWorkoutExercise = WorkoutExercise(
        exercise: exercise,
        sets: sets,
        reps: reps,
        weight: weights.isNotEmpty ? weights[0] : 0.0,
        restTime: 60, // Default rest time
      );

      // Add to workout exercises list
      widget.workout.exercises.add(newWorkoutExercise);

      // Create exercise logs with individual weights
      final exerciseLogs = List<Map<String, dynamic>>.generate(
        sets,
        (index) => Map<String, dynamic>.from({
          'reps': reps,
          'weight': index < weights.length
              ? weights[index]
              : (weights.isNotEmpty ? weights[0] : 0.0),
          'completed': false,
        }),
      );

      // Add to exercise logs
      _exerciseLogs.add(exerciseLogs);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${exercise.name} to workout'),
          backgroundColor: AppColors.forestGreen,
        ),
      );
    });
  }

  void _showWorkoutMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Workout'),
              onTap: () {
                Navigator.pop(context);
                // Add edit workout functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Workout'),
              onTap: () {
                Navigator.pop(context);
                // Add share workout functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: Text(
                _useRestTimer ? 'Disable Rest Timer' : 'Enable Rest Timer',
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _useRestTimer = !_useRestTimer;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseMoreOptions() {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Exercise Information'),
              onTap: () {
                Navigator.pop(context);
                _showExerciseInfo(currentExercise);
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('Skip Exercise'),
              onTap: () {
                Navigator.pop(context);
                _skipExercise();
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Reset Sets'),
              onTap: () {
                Navigator.pop(context);
                _resetCurrentExerciseSets();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseInfo(dynamic currentExercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentExercise.exercise.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${currentExercise.exercise.primaryMuscle}'),
            const SizedBox(height: 8),
            const Text('Important Form Tips:'),
            const SizedBox(height: 4),
            const Text('• Watch back rounding'),
            const Text('• Keep core engaged'),
            const Text('• Control the weight'),
            const Text('• Focus on proper breathing'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _skipExercise() {
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      _completeWorkout();
    }
  }

  void _resetCurrentExerciseSets() {
    setState(() {
      final currentExercise = widget.workout.exercises[_currentExerciseIndex];
      _exerciseLogs[_currentExerciseIndex] =
          List<Map<String, dynamic>>.generate(
            currentExercise.sets,
            (index) => Map<String, dynamic>.from({
              'reps': currentExercise.reps,
              'weight': currentExercise.weight,
              'completed': false,
            }),
          );
    });
  }

  void _showExerciseTip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: AppColors.orange),
            SizedBox(width: 8),
            Text('Form Tip'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Watch Back Rounding:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Keep your spine in a neutral position'),
            Text('• Avoid excessive arching or rounding'),
            Text('• Engage your core throughout the movement'),
            Text('• If you feel back strain, reduce the weight'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Thanks'),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseDialog extends StatefulWidget {
  final Function(Exercise, int, List<double>, int) onExerciseAdded;

  const _AddExerciseDialog({required this.onExerciseAdded});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _setsController = TextEditingController(
    text: '3',
  );
  final TextEditingController _repsController = TextEditingController(
    text: '10',
  );
  final List<TextEditingController> _weightControllers = [];

  List<Exercise> _exercises = [];
  Exercise? _selectedExercise;
  bool _isLoading = false;
  int _numberOfSets = 3;

  @override
  void initState() {
    super.initState();
    _initializeWeightControllers();
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeWeightControllers() {
    _weightControllers.clear();
    for (int i = 0; i < _numberOfSets; i++) {
      _weightControllers.add(TextEditingController(text: '50'));
    }
  }

  void _updateWeightControllers(int newSets) {
    // Dispose old controllers
    for (var controller in _weightControllers) {
      controller.dispose();
    }

    setState(() {
      _numberOfSets = newSets;
      _initializeWeightControllers();
    });
  }

  Future<void> _fetchExercises({String? search}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      String url;
      if (search != null && search.trim().isNotEmpty) {
        url =
            'https://api-7ba4ub2p3a-uc.a.run.app/exercises/search/${Uri.encodeComponent(search.trim())}';
      } else {
        url = 'https://api-7ba4ub2p3a-uc.a.run.app/exercises/';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> data;
        if (decoded is Map && decoded.containsKey('data')) {
          data = decoded['data'];
        } else if (decoded is List) {
          data = decoded;
        } else {
          throw Exception('Unexpected response format');
        }

        final exercises = data.map((item) => Exercise.fromJson(item)).toList();
        if (mounted) {
          setState(() {
            _exercises = exercises;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showExerciseConfigurationDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseConfigurationDialog(
        exercise: exercise,
        onExerciseAdded: widget.onExerciseAdded,
      ),
    );
  }

  void _addExercise() {
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an exercise')),
      );
      return;
    }

    final reps = int.tryParse(_repsController.text) ?? 10;
    final weights = _weightControllers
        .map((controller) => double.tryParse(controller.text) ?? 50.0)
        .toList();

    widget.onExerciseAdded(_selectedExercise!, _numberOfSets, weights, reps);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    print('Building AddExerciseDialog');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Exercise',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.surface,
                filled: true,
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  _fetchExercises(search: value);
                } else if (value.isEmpty) {
                  _fetchExercises();
                }
              },
            ),

            const SizedBox(height: 16),

            // Exercise List
            const Text(
              'Select Exercise:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              flex: 2,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];

                          return ListTile(
                            title: Text(exercise.name),
                            subtitle: Text(exercise.primaryMuscles.join(', ')),
                            onTap: () {
                              // Close the current dialog and show exercise configuration
                              Navigator.of(context).pop();
                              _showExerciseConfigurationDialog(exercise);
                            },
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseConfigurationDialog extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise, int, List<double>, int) onExerciseAdded;

  const _ExerciseConfigurationDialog({
    required this.exercise,
    required this.onExerciseAdded,
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
  final List<TextEditingController> _weightControllers = [];

  int _numberOfSets = 3;

  @override
  void initState() {
    super.initState();
    _initializeWeightControllers();
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeWeightControllers() {
    _weightControllers.clear();
    for (int i = 0; i < _numberOfSets; i++) {
      _weightControllers.add(TextEditingController(text: '50'));
    }
  }

  void _updateWeightControllers(int newSets) {
    // Dispose old controllers
    for (var controller in _weightControllers) {
      controller.dispose();
    }

    setState(() {
      _numberOfSets = newSets;
      _initializeWeightControllers();
    });
  }

  void _addExercise() {
    final reps = int.tryParse(_repsController.text) ?? 10;
    final weights = _weightControllers
        .map((controller) => double.tryParse(controller.text) ?? 50.0)
        .toList();

    widget.onExerciseAdded(widget.exercise, _numberOfSets, weights, reps);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
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
                    ? AppColors.darkOnSurface.withOpacity(0.7)
                    : AppColors.darkGray,
              ),
            ),

            if (widget.exercise.secondaryMuscles.isNotEmpty)
              Text(
                'Secondary muscles: ${widget.exercise.secondaryMuscles.join(', ')}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? AppColors.darkOnSurface.withOpacity(0.7)
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
                                onChanged: (value) {
                                  final newSets = int.tryParse(value) ?? 3;
                                  if (newSets != _numberOfSets &&
                                      newSets > 0 &&
                                      newSets <= 10) {
                                    _updateWeightControllers(newSets);
                                  }
                                },
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

                    const SizedBox(height: 20),

                    // Weight Configuration
                    const Text(
                      'Weight per set (kg)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _numberOfSets,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Text(
                              'Set ${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: TextField(
                                controller: _weightControllers[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  fillColor: isDarkMode
                                      ? AppColors.darkSurface
                                      : AppColors.surface,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
