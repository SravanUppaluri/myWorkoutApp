import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises({String? search}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
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
          data = [];
        }
        if (!mounted) return;
        setState(() {
          _exercises = data.map((e) => Exercise.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Failed to load exercises: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildExercisesList() {
    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_gymnastics,
              size: 80,
              color: AppColors.darkGray.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Text('No exercises found.', style: AppTextStyles.bodyText1),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: _exercises.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.marginMedium),
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
            title: Text(exercise.name, style: AppTextStyles.headline3),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category: ${exercise.category}',
                  style: AppTextStyles.bodyText2,
                ),
                Text(
                  'Difficulty: ${exercise.difficulty}',
                  style: AppTextStyles.bodyText2,
                ),
                Text(
                  'Equipment: ${exercise.equipment.join(", ")}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Primary Muscles: ${exercise.primaryMuscles.join(", ")}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Secondary Muscles: ${exercise.secondaryMuscles.join(", ")}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Target Region: ${exercise.targetRegion.join(", ")}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Movement Type: ${exercise.movementType}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Grip Type: ${exercise.gripType}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Range of Motion: ${exercise.rangeOfMotion}',
                  style: AppTextStyles.caption,
                ),
                Text('Tempo: ${exercise.tempo}', style: AppTextStyles.caption),
                Text(
                  'Muscle Group: ${exercise.muscleGroup}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                  tooltip: 'Add to workout',
                  onPressed: () {
                    // TODO: Implement add to workout logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${exercise.name} to workout!'),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Icon(Icons.fitness_center, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              color: AppColors.lightGray,
              child: Row(
                children: [
                  const Text(
                    'Filter by muscle group:',
                    style: AppTextStyles.bodyText1,
                  ),
                  const SizedBox(width: AppDimensions.marginMedium),
                  // You can re-enable muscle group filtering here if needed
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _buildExercisesList(),
            ),
            // Search Bar at the bottom
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              color: AppColors.lightGray,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search exercises...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _fetchExercises(search: _searchController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
