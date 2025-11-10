import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../utils/superset_utils.dart';
import '../utils/constants.dart';

class SupersetCreationDialog extends StatefulWidget {
  final List<WorkoutExercise> availableExercises;
  final Function(List<WorkoutExercise>) onSupersetCreated;

  const SupersetCreationDialog({
    super.key,
    required this.availableExercises,
    required this.onSupersetCreated,
  });

  @override
  State<SupersetCreationDialog> createState() => _SupersetCreationDialogState();
}

class _SupersetCreationDialogState extends State<SupersetCreationDialog> {
  final List<WorkoutExercise> selectedExercises = [];
  late List<WorkoutExercise> availableExercises;

  @override
  void initState() {
    super.initState();
    // Only show exercises that are not already in a superset
    availableExercises = widget.availableExercises
        .where((exercise) => !exercise.isInSuperset)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final warnings = SupersetUtils.validateSuperset(selectedExercises);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.link, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Create Superset'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Select 2-4 exercises to group into a superset. Exercises will be performed back-to-back with rest only after completing all exercises in the superset.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Selected exercises
            if (selectedExercises.isNotEmpty) ...[
              const Text(
                'Selected Exercises:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: selectedExercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    final label = SupersetUtils.generateSupersetLabel(0, index);

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(exercise.exercise.name),
                      subtitle: Text(
                        '${exercise.sets} sets × ${exercise.reps} reps',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedExercises.removeAt(index);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Warnings
            if (warnings.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Recommendations:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ...warnings.map(
                      (warning) => Text(
                        '• $warning',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Available exercises
            const Text(
              'Available Exercises:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: availableExercises.length,
                itemBuilder: (context, index) {
                  final exercise = availableExercises[index];
                  final isSelected = selectedExercises.contains(exercise);

                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (selectedExercises.length < 4) {
                              selectedExercises.add(exercise);
                            }
                          } else {
                            selectedExercises.remove(exercise);
                          }
                        });
                      },
                    ),
                    title: Text(exercise.exercise.name),
                    subtitle: Text(
                      '${exercise.exercise.primaryMuscles.join(", ")} • ${exercise.sets} sets × ${exercise.reps} reps',
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedExercises.remove(exercise);
                        } else if (selectedExercises.length < 4) {
                          selectedExercises.add(exercise);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedExercises.length >= 2
              ? () {
                  final supersetId = DateTime.now().millisecondsSinceEpoch
                      .toString();
                  final supersetIndex = SupersetUtils.getNextSupersetIndex(
                    widget.availableExercises,
                  );
                  final superset = SupersetUtils.createSuperset(
                    selectedExercises,
                    supersetId,
                    supersetIndex,
                  );
                  widget.onSupersetCreated(superset);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Create Superset'),
        ),
      ],
    );
  }
}
