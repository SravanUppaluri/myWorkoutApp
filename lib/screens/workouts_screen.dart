import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import 'create_workout_screen.dart';
import 'workout_detail_screen.dart';
import 'exercise_selection_screen.dart';
import 'improved_ai_workout_screen.dart';
import 'workout_session_screen.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen>
    with SingleTickerProviderStateMixin {
  String? _currentUserId;
  bool _isFabExpanded = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkouts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadWorkouts() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    // Use Firebase UID for proper Firestore security rule matching
    _currentUserId = authProvider.user?.id ?? 'dummy_user_id';

    // Load workouts for the current user
    workoutProvider.loadUserWorkouts(_currentUserId!);
  }

  Widget _buildWorkoutsTab(List<Workout> workouts) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Workouts Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'My Workouts',
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${workouts.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Workouts List
        workouts.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkSurface.withValues(alpha: 0.5)
                          : AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      border: Border.all(
                        color: isDarkMode
                            ? AppColors.darkOnSurface.withValues(alpha: 0.1)
                            : AppColors.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: isDarkMode
                                ? AppColors.darkOnSurface.withValues(alpha: 0.5)
                                : AppColors.onSurface.withValues(alpha: 0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No workouts yet',
                            style: AppTextStyles.bodyText1.copyWith(
                              color: isDarkMode
                                  ? AppColors.darkOnSurface.withValues(
                                      alpha: 0.6,
                                    )
                                  : AppColors.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first workout or generate one with AI',
                            style: AppTextStyles.bodyText2.copyWith(
                              color: isDarkMode
                                  ? AppColors.darkOnSurface.withValues(
                                      alpha: 0.5,
                                    )
                                  : AppColors.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildWorkoutCard(workouts[index]),
                  childCount: workouts.length,
                ),
              ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTemplatesTab(List<Map<String, dynamic>> templates) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Templates Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              children: [
                Icon(Icons.dynamic_form, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Workout Templates',
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${templates.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (templates.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'P',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Templates List
        templates.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.orange,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No workout templates yet',
                          style: AppTextStyles.bodyText1.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Templates are multi-day workout programs with progressive unlocking. Generate them using AI workout splits!',
                          style: AppTextStyles.bodyText2.copyWith(
                            color: Colors.orange.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTemplateCard(
                    templates[index]['template'] as Workout,
                    templates[index]['isUnlocked'] as bool,
                    templates[index]['dayNumber'] as int,
                  ),
                  childCount: templates.length,
                ),
              ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.workouts,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : AppColors.surface,
        iconTheme: IconThemeData(
          color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseSelectionScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.sports_gymnastics,
              size: 28,
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
            tooltip: 'Exercise Library',
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
            Tab(icon: Icon(Icons.dynamic_form), text: 'Templates'),
          ],
          labelColor: isDarkMode
              ? AppColors.darkOnSurface
              : AppColors.onSurface,
          unselectedLabelColor: isDarkMode
              ? AppColors.darkOnSurface.withValues(alpha: 0.6)
              : AppColors.onSurface.withValues(alpha: 0.6),
          indicatorColor: AppColors.primary,
        ),
      ),
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          if (workoutProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (workoutProvider.errorMessage != null) {
            return _buildErrorState(workoutProvider.errorMessage!);
          }

          final allWorkouts = workoutProvider.workouts;
          final regularWorkouts = allWorkouts
              .where((w) => !w.isTemplate)
              .toList();

          // Filter out completed templates and sort by name (Day 1, Day 2, etc.)
          final allTemplates =
              allWorkouts
                  .where(
                    (w) => w.isTemplate && w.exercises.isNotEmpty,
                  ) // Filter out completed templates
                  .toList()
                ..sort((a, b) {
                  // Sort by day number in workout name (e.g., "Day 1", "Day 2")
                  final aMatch = RegExp(r'Day (\d+)').firstMatch(a.name);
                  final bMatch = RegExp(r'Day (\d+)').firstMatch(b.name);

                  if (aMatch != null && bMatch != null) {
                    final aDay = int.parse(aMatch.group(1)!);
                    final bDay = int.parse(bMatch.group(1)!);
                    return aDay.compareTo(bDay);
                  }

                  // Fallback to alphabetical sorting
                  return a.name.compareTo(b.name);
                });

          // Determine which templates should be unlocked
          final templates = _addUnlockStatus(allTemplates);

          if (allWorkouts.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildWorkoutsTab(regularWorkouts),
              _buildTemplatesTab(templates),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI Workout Generation FAB
          if (_isFabExpanded) ...[
            FloatingActionButton.extended(
              onPressed: () async {
                setState(() => _isFabExpanded = false);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImprovedAIWorkoutScreen(),
                  ),
                );
              },
              heroTag: 'ai_workout_workouts',
              backgroundColor: AppColors.primary.withValues(alpha: 0.9),
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI Workout'),
            ),
            const SizedBox(height: 16),
            // Manual Workout Creation FAB
            FloatingActionButton.extended(
              onPressed: () async {
                setState(() => _isFabExpanded = false);
                await _showCreateWorkoutDialog();
              },
              heroTag: 'manual_workout_workouts',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(Icons.edit),
              label: const Text('Manual'),
            ),
            const SizedBox(height: 16),
          ],
          // Main FAB
          FloatingActionButton(
            onPressed: () {
              setState(() => _isFabExpanded = !_isFabExpanded);
            },
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            child: AnimatedRotation(
              turns: _isFabExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(_isFabExpanded ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: AppDimensions.marginMedium),
          Text(
            'Something went wrong',
            style: AppTextStyles.headline3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Text(
            errorMessage,
            style: AppTextStyles.bodyText1.copyWith(
              color: isDarkMode
                  ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                  : AppColors.darkGray.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          ElevatedButton.icon(
            onPressed: () {
              _loadWorkouts();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: isDarkMode
                ? AppColors.darkOnSurface.withValues(alpha: 0.5)
                : AppColors.darkGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Text(
            AppStrings.noWorkouts,
            style: AppTextStyles.headline3.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.darkGray,
            ),
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Text(
            'Create your first workout to get started!',
            style: AppTextStyles.bodyText1.copyWith(
              color: isDarkMode
                  ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                  : AppColors.darkGray.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          ElevatedButton.icon(
            onPressed: () async {
              await _showCreateWorkoutDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.createWorkout),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: 4,
      ),
      child: Card(
        elevation: 2,
        color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getDifficultyColor(workout.difficulty),
            child: Text(
              workout.difficulty.isNotEmpty
                  ? workout.difficulty[0].toUpperCase()
                  : 'W', // Default to 'W' for Workout if difficulty is empty
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            workout.name,
            style: AppTextStyles.bodyText1.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${workout.exercises.length} exercises • ${workout.estimatedDuration} min',
                style: AppTextStyles.bodyText2.copyWith(
                  color: isDarkMode
                      ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                      : AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (workout.description.isNotEmpty)
                Text(
                  workout.description,
                  style: AppTextStyles.caption.copyWith(
                    color: isDarkMode ? AppColors.darkGray : AppColors.darkGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: PopupMenuButton(
            iconColor: isDarkMode
                ? AppColors.darkOnSurface
                : AppColors.onSurface,
            color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'start',
                child: Row(
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.startWorkout,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkOnSurface
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.edit,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkOnSurface
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.delete,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkOnSurface
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              _handleWorkoutAction(value.toString(), workout);
            },
          ),
          onTap: () {
            _showWorkoutDetails(workout);
          },
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Workout template, bool isUnlocked, int dayNumber) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentExercise = template.currentExercise;
    final totalExercises = template.exercises.length;
    final completedCount = template.completedExercisesCount;

    if (currentExercise == null || template.exercises.isEmpty) {
      // Template is completed, this shouldn't normally show
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: 4,
      ),
      child: Card(
        elevation: isUnlocked ? 3 : 1,
        color: isUnlocked
            ? (isDarkMode ? AppColors.darkSurface : AppColors.surface)
            : (isDarkMode
                  ? AppColors.darkSurface.withValues(alpha: 0.7)
                  : AppColors.surface.withValues(alpha: 0.7)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnlocked
                ? Colors.orange.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isUnlocked ? Icons.dynamic_form : Icons.lock,
                      color: isUnlocked ? Colors.orange : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? (isDarkMode
                                      ? AppColors.darkOnSurface
                                      : AppColors.onSurface)
                                : Colors.grey,
                          ),
                        ),
                        Text(
                          isUnlocked
                              ? 'Template • $completedCount of $totalExercises completed'
                              : 'Template • Day $dayNumber (Locked)',
                          style: AppTextStyles.caption.copyWith(
                            color: isUnlocked ? Colors.orange : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    iconColor: Colors.orange,
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Template',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _handleTemplateAction('delete', template);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress indicator
              if (isUnlocked)
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completedCount / totalExercises,
                        backgroundColor: Colors.orange.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${((completedCount / totalExercises) * 100).round()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // All exercises list with progression
              Column(
                children: [
                  for (int i = 0; i < template.exercises.length; i++)
                    _buildExerciseItem(
                      template.exercises[i],
                      i,
                      template.currentExerciseIndex,
                      isDarkMode,
                      isUnlocked,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Lock warning message
              if (!isUnlocked) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, size: 20, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete Day ${dayNumber - 1} to unlock this workout',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isUnlocked
                          ? () => _startTemplateExercise(template)
                          : null,
                      icon: Icon(isUnlocked ? Icons.play_arrow : Icons.lock),
                      label: Text(isUnlocked ? 'Start Exercise' : 'Locked'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUnlocked
                            ? Colors.orange
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: isUnlocked
                        ? () => _completeTemplateExercise(template)
                        : null,
                    icon: Icon(isUnlocked ? Icons.check : Icons.lock),
                    label: Text(isUnlocked ? 'Complete' : 'Locked'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnlocked ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),

              // Remaining exercises hint
              if (template.remainingExercisesCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${template.remainingExercisesCount} more exercises remaining',
                    style: AppTextStyles.caption.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withValues(alpha: 0.6)
                          : AppColors.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(
    WorkoutExercise exercise,
    int index,
    int currentIndex,
    bool isDarkMode,
    bool isTemplateUnlocked,
  ) {
    final isCurrent = exercise.isCurrentExercise;
    final isCompleted = index < currentIndex && currentIndex != -1;
    final isLocked = index > currentIndex || !isTemplateUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: !isTemplateUnlocked
            ? Colors.grey.withValues(alpha: 0.05)
            : isCurrent
            ? Colors.orange.withValues(alpha: 0.1)
            : isCompleted
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: !isTemplateUnlocked
              ? Colors.grey.withValues(alpha: 0.2)
              : isCurrent
              ? Colors.orange.withValues(alpha: 0.5)
              : isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
          width: isCurrent && isTemplateUnlocked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !isTemplateUnlocked
                  ? Colors.grey.withValues(alpha: 0.5)
                  : isCurrent
                  ? Colors.orange
                  : isCompleted
                  ? Colors.green
                  : Colors.grey.withValues(alpha: 0.3),
            ),
            child: Icon(
              !isTemplateUnlocked
                  ? Icons.lock
                  : isCurrent
                  ? Icons.play_arrow
                  : isCompleted
                  ? Icons.check
                  : Icons.lock,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exercise.name,
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: isCurrent && isTemplateUnlocked
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: (!isTemplateUnlocked || isLocked)
                        ? (isDarkMode
                              ? AppColors.darkOnSurface.withValues(alpha: 0.4)
                              : AppColors.onSurface.withValues(alpha: 0.4))
                        : (isDarkMode
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.sets} sets × ${exercise.reps} reps',
                  style: AppTextStyles.caption.copyWith(
                    color: (!isTemplateUnlocked || isLocked)
                        ? (isDarkMode
                              ? AppColors.darkOnSurface.withValues(alpha: 0.3)
                              : AppColors.onSurface.withValues(alpha: 0.3))
                        : (isDarkMode
                              ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                              : AppColors.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          if (!isTemplateUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LOCKED',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            )
          else if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CURRENT',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            )
          else if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'DONE',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LOCKED',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.forestGreen;
      case 'intermediate':
        return AppColors.steelBlue;
      case 'advanced':
        return AppColors.cardinalRed;
      default:
        return AppColors.primary;
    }
  }

  // Progressive unlocking logic for templates
  List<Map<String, dynamic>> _addUnlockStatus(List<Workout> templates) {
    final templatesWithStatus = <Map<String, dynamic>>[];

    for (int i = 0; i < templates.length; i++) {
      final template = templates[i];
      final dayMatch = RegExp(r'Day (\d+)').firstMatch(template.name);

      if (dayMatch != null) {
        final dayNumber = int.parse(dayMatch.group(1)!);
        // Day 1 is always unlocked, subsequent days are unlocked if previous day is completed
        final isUnlocked =
            dayNumber == 1 || _isPreviousDayCompleted(templates, dayNumber);

        templatesWithStatus.add({
          'template': template,
          'isUnlocked': isUnlocked,
          'dayNumber': dayNumber,
        });
      } else {
        // Non-day templates are always unlocked
        templatesWithStatus.add({
          'template': template,
          'isUnlocked': true,
          'dayNumber': 0,
        });
      }
    }

    return templatesWithStatus;
  }

  bool _isPreviousDayCompleted(List<Workout> templates, int currentDay) {
    // Check if the previous day (currentDay - 1) exists in the templates list
    // If it doesn't exist, it means it was completed and deleted
    final previousDayExists = templates.any((template) {
      final dayMatch = RegExp(r'Day (\d+)').firstMatch(template.name);
      if (dayMatch != null) {
        final dayNumber = int.parse(dayMatch.group(1)!);
        return dayNumber == currentDay - 1;
      }
      return false;
    });

    // If previous day doesn't exist in templates, it means it was completed
    return !previousDayExists;
  }

  // Template-specific methods
  void _handleTemplateAction(String action, Workout template) async {
    if (action == 'delete') {
      final confirmed = await _showDeleteTemplateDialog(template);
      if (confirmed == true) {
        await _deleteTemplate(template);
      }
    }
  }

  Future<bool?> _showDeleteTemplateDialog(Workout template) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete the template "${template.name}"?\n\nThis will permanently remove the template and all remaining exercises.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(Workout template) async {
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      final success = await workoutProvider.deleteWorkout(template.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "${template.name}" deleted successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTemplateExercise(Workout template) {
    final currentExercise = template.currentExercise;
    if (currentExercise == null) return;

    // Navigate to the full template workout session
    // Keep the original template ID so the workout session can update the correct template
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          workout:
              template, // Use the original template, don't create a copy with new ID
        ),
      ),
    ).then((result) {
      // Template progression is now handled automatically by the workout session
      // No need for manual template updates here
    });
  }

  void _completeTemplateExercise(Workout template) async {
    final confirmed = await _showCompleteExerciseDialog(template);
    if (confirmed == true) {
      await _markExerciseComplete(template);
    }
  }

  Future<bool?> _showCompleteExerciseDialog(Workout template) {
    final currentExercise = template.currentExercise;
    if (currentExercise == null) return Future.value(false);

    final isLastExercise =
        template.currentExerciseIndex >= template.exercises.length - 1;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark "${currentExercise.exercise.name}" as completed?'),
            const SizedBox(height: 8),
            if (isLastExercise)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is the last exercise! The template will be completed.',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Next: ${template.exercises[template.currentExerciseIndex + 1].exercise.name}',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _markExerciseComplete(Workout template) async {
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );

      // Update the template to move to the next exercise
      final updatedTemplate = template.completeCurrentExercise();

      if (updatedTemplate.exercises.isEmpty) {
        // Template is completed, delete it
        await workoutProvider.deleteWorkout(template.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Template "${template.name}" completed! Well done!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Update the template with the next exercise
        await workoutProvider.updateWorkout(updatedTemplate);

        if (mounted) {
          final nextExercise = updatedTemplate.currentExercise;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Exercise completed! Next: ${nextExercise?.exercise.name ?? 'None'}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleWorkoutAction(String action, Workout workout) {
    logger.e(
      '🎯 WORKOUTS SCREEN: User selected action "$action" for workout "${workout.name}"',
    );
    logger.e('📊 Workout ID: ${workout.id}');
    logger.e('📊 Action Time: ${DateTime.now()}');

    switch (action) {
      case 'start':
        logger.e('🚀 NAVIGATING TO: WorkoutDetailScreen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailScreen(workout: workout),
          ),
        ).then((result) {
          if (result == true && mounted) {
            logger.e('✅ RETURNED FROM DETAIL: Workout was deleted');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted "${workout.name}"')),
            );
          } else {
            logger.e('↩️ RETURNED FROM DETAIL: No deletion');
          }
        });
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateWorkoutScreen(existingWorkout: workout),
          ),
        ).then((result) {
          if (result != null && result is Workout) {
            // Update handled by WorkoutProvider stream automatically
            final workoutProvider = Provider.of<WorkoutProvider>(
              context,
              listen: false,
            );
            workoutProvider.saveWorkout(result, _currentUserId!);
          }
        });
        break;
      case 'delete':
        _showDeleteConfirmation(workout);
        break;
    }
  }

  Future<void> _showCreateWorkoutDialog() async {
    logger.e('DEBUG: Opening CreateWorkoutScreen');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateWorkoutScreen()),
    );

    logger.e('DEBUG: CreateWorkoutScreen returned: $result');

    if (result != null && result is Workout) {
      logger.e(
        'DEBUG: Saving workout: ${result.name} with ${result.exercises.length} exercises',
      );

      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );

      logger.e('DEBUG: Current user ID: $_currentUserId');

      try {
        final savedId = await workoutProvider.saveWorkout(
          result,
          _currentUserId!,
        );
        logger.e('DEBUG: Workout saved with ID: $savedId');

        if (savedId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workout "${result.name}" saved successfully!'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save workout. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (error) {
        logger.e('DEBUG: Error saving workout: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving workout: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      logger.e('DEBUG: No workout returned from CreateWorkoutScreen');
    }
  }

  void _showWorkoutDetails(Workout workout) {
    logger.e(
      '🎯 WORKOUTS SCREEN: Showing workout details for "${workout.name}"',
    );
    logger.e('📊 Workout ID: ${workout.id}');
    logger.e('📊 Details Time: ${DateTime.now()}');
    logger.e('🚀 NAVIGATING TO: WorkoutDetailScreen (via _showWorkoutDetails)');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workout: workout),
      ),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted "${workout.name}"')));
      }
    });
  }

  void _showDeleteConfirmation(Workout workout) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Delete Workout',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${workout.name}"?',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkOnSurface
                    : AppColors.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final workoutProvider = Provider.of<WorkoutProvider>(
                context,
                listen: false,
              );
              final success = await workoutProvider.deleteWorkout(workout.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${workout.name}"')),
                );
              } else {
                final error = workoutProvider.errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error != null && error.isNotEmpty
                          ? 'Failed to delete workout: $error'
                          : 'Failed to delete workout',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
