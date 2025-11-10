import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../services/calorie_service.dart';
import '../services/ai_workout_service.dart';
import '../models/workout_session.dart';
import '../models/workout.dart';
import 'workouts_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import 'create_workout_screen.dart';
import 'improved_ai_workout_screen.dart';
import 'workout_review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isFabExpanded = false;

  final List<Widget> _screens = [
    const DashboardTab(),
    const WorkoutsScreen(),
    const StatisticsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? Column(
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
                    heroTag: 'ai_workout',
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
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateWorkoutScreen(),
                        ),
                      );

                      if (result != null && result is Workout) {
                        // Get the necessary providers
                        final workoutProvider = Provider.of<WorkoutProvider>(
                          context,
                          listen: false,
                        );
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );

                        if (authProvider.user != null) {
                          final userId = authProvider.user!.id;

                          try {
                            final savedId = await workoutProvider.saveWorkout(
                              result,
                              userId,
                            );

                            if (savedId != null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Workout "${result.name}" saved successfully!',
                                    ),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to save workout. Please try again.',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          } catch (error) {
                            if (context.mounted) {
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to save workouts'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      } else {
                        // No workout returned
                      }
                    },
                    heroTag: 'manual_workout',
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
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDarkMode
            ? AppColors.darkOnSurface.withValues(alpha: 0.6)
            : AppColors.onSurface.withValues(alpha: 0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: AppStrings.workouts,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // AI Workout Generation options
  int _selectedDuration = 45; // Default duration
  final List<int> _durationOptions = [30, 45, 60];
  bool _isSmartGenerationAvailable = false;
  int _recentWorkoutsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );

      if (authProvider.user != null) {
        final userId = authProvider.user!.id;
        workoutProvider.loadUserWorkoutSessions(userId).then((_) {
          _checkSmartGenerationAvailability();
        });
      }
    });
  }

  void _checkSmartGenerationAvailability() {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    // Get workouts from the past 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentWorkouts = workoutProvider.workoutSessions
        .where((session) => session.completedAt.isAfter(sevenDaysAgo))
        .toList();

    setState(() {
      _recentWorkoutsCount = recentWorkouts.length;
      _isSmartGenerationAvailable = recentWorkouts.length >= 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, WorkoutProvider>(
      builder: (context, authProvider, workoutProvider, child) {
        // Check smart generation availability whenever provider updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          final recentWorkouts = workoutProvider.workoutSessions
              .where((session) => session.completedAt.isAfter(sevenDaysAgo))
              .toList();

          if (_recentWorkoutsCount != recentWorkouts.length) {
            setState(() {
              _recentWorkoutsCount = recentWorkouts.length;
              _isSmartGenerationAvailable = recentWorkouts.length >= 4;
            });
          }
        });

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        // Get all sessions data
        final todaySessions = _getTodaySessions(
          workoutProvider.workoutSessions,
        );
        final weekSessions = _getWeekSessions(workoutProvider.workoutSessions);
        final monthSessions = _getMonthSessions(
          workoutProvider.workoutSessions,
        );

        // Get user weight for calorie calculations
        final userWeight = CalorieService.getUserWeight(
          authProvider.user?.goalData,
        );

        // Calculate stats
        final todayStats = _calculateDayStats(todaySessions, userWeight);
        final weekStats = _calculateWeekStats(weekSessions, userWeight);
        final monthStats = _calculateMonthStats(monthSessions, userWeight);

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadDashboardData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.marginLarge),

                  // Welcome message
                  _buildWelcomeSection(authProvider),
                  const SizedBox(height: AppDimensions.marginLarge),

                  // Streak Section (show if streak > 2)
                  _buildStreakSection(
                    workoutProvider.workoutSessions,
                    isDarkMode,
                  ),

                  // Monthly Bar Chart
                  _buildMonthlyChart(monthSessions, isDarkMode),
                  const SizedBox(height: AppDimensions.marginLarge),

                  // Weekly Analytics Charts
                  _buildWeeklyTwinBarChart(
                    weekSessions,
                    userWeight,
                    isDarkMode,
                  ),
                  const SizedBox(height: AppDimensions.marginLarge),

                  // Today's Progress
                  _buildProgressSection(
                    title: "Today's Progress",
                    icon: Icons.today,
                    stats: todayStats,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(height: AppDimensions.marginLarge),

                  // Weekly Progress
                  _buildProgressSection(
                    title: "This Week's Progress",
                    icon: Icons.calendar_view_week,
                    stats: weekStats,
                    color: AppColors.steelBlue,
                  ),
                  const SizedBox(height: AppDimensions.marginLarge),

                  // Monthly Progress
                  _buildProgressSection(
                    title: "This Month's Progress",
                    icon: Icons.calendar_month,
                    stats: monthStats,
                    color: AppColors.purple,
                  ),
                  const SizedBox(height: AppDimensions.marginLarge),

                  // Recent Activity
                  if (todaySessions.isNotEmpty) ...[
                    _buildRecentActivity(todaySessions, userWeight, isDarkMode),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper methods for data processing
  List<WorkoutSession> _getTodaySessions(List<WorkoutSession> allSessions) {
    final today = DateTime.now();
    return allSessions.where((session) {
      final sessionDate = session.completedAt;
      return sessionDate.year == today.year &&
          sessionDate.month == today.month &&
          sessionDate.day == today.day;
    }).toList();
  }

  List<WorkoutSession> _getWeekSessions(List<WorkoutSession> allSessions) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return allSessions.where((session) {
      final sessionDate = session.completedAt;
      return sessionDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          sessionDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  List<WorkoutSession> _getMonthSessions(List<WorkoutSession> allSessions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return allSessions.where((session) {
      final sessionDate = session.completedAt;
      return sessionDate.isAfter(
            monthStart.subtract(const Duration(days: 1)),
          ) &&
          sessionDate.isBefore(monthEnd.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> _calculateDayStats(
    List<WorkoutSession> sessions,
    double userWeight,
  ) {
    final totalDuration = sessions.fold(
      0,
      (total, session) => total + session.duration,
    );
    final calories = CalorieService.calculateTodayCalories(
      todaySessions: sessions,
      userWeightKg: userWeight,
    );

    return {
      'workouts': sessions.length,
      'duration': totalDuration,
      'calories': calories.round(),
      'minutes': (totalDuration / 60).round(),
    };
  }

  Map<String, dynamic> _calculateWeekStats(
    List<WorkoutSession> sessions,
    double userWeight,
  ) {
    final totalDuration = sessions.fold(
      0,
      (total, session) => total + session.duration,
    );
    final calories = CalorieService.calculateWeeklyCalories(
      weeklySessions: sessions,
      userWeightKg: userWeight,
    );

    return {
      'workouts': sessions.length,
      'duration': totalDuration,
      'calories': calories.round(),
      'minutes': (totalDuration / 60).round(),
    };
  }

  Map<String, dynamic> _calculateMonthStats(
    List<WorkoutSession> sessions,
    double userWeight,
  ) {
    final totalDuration = sessions.fold(
      0,
      (total, session) => total + session.duration,
    );
    final calories = sessions.fold(0.0, (total, session) {
      return total +
          CalorieService.calculateSessionCalories(
            session: session,
            userWeightKg: userWeight,
          );
    });

    return {
      'workouts': sessions.length,
      'duration': totalDuration,
      'calories': calories.round(),
      'minutes': (totalDuration / 60).round(),
    };
  }

  // UI Helper methods
  Widget _buildWelcomeSection(AuthProvider authProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.user;
    final now = DateTime.now();
    final hour = now.hour;

    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting!',
          style: AppTextStyles.headline2.copyWith(color: AppColors.primary),
        ),
        if (user != null) ...[
          Text(
            user.displayName,
            style: AppTextStyles.headline1.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready for your workout?',
            style: AppTextStyles.bodyText1.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.darkGray,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection({
    required String title,
    required IconData icon,
    required Map<String, dynamic> stats,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: isDarkMode
            ? Border.all(color: AppColors.darkGray.withOpacity(0.3))
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.headline3.copyWith(
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.fitness_center,
                  title: 'Workouts',
                  value: '${stats['workouts']}',
                  color: color,
                ),
              ),
              const SizedBox(width: AppDimensions.marginSmall),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Calories',
                  value: '${stats['calories']}',
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer,
                  title: 'Minutes',
                  value: '${stats['minutes']}',
                  color: AppColors.steelBlue,
                ),
              ),
              const SizedBox(width: AppDimensions.marginSmall),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  title: 'Duration',
                  value: _formatDuration(stats['duration']),
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkBackground.withOpacity(0.5)
            : AppColors.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface.withOpacity(0.7)
                        : AppColors.darkGray,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headline3.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTwinBarChart(
    List<WorkoutSession> weekSessions,
    double userWeight,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: isDarkMode
            ? Border.all(color: AppColors.darkGray.withOpacity(0.3))
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.steelBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  color: AppColors.steelBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Analytics',
                style: AppTextStyles.headline3.copyWith(
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.steelBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Minutes',
                style: AppTextStyles.caption.copyWith(
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.darkGray,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Calories',
                style: AppTextStyles.caption.copyWith(
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          SizedBox(
            height: 200,
            child: _buildTwinBarChart(weekSessions, userWeight, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildTwinBarChart(
    List<WorkoutSession> sessions,
    double userWeight,
    bool isDarkMode,
  ) {
    // Group sessions by day of week
    final weekData = <int, Map<String, double>>{};
    for (int i = 1; i <= 7; i++) {
      weekData[i] = {'minutes': 0.0, 'calories': 0.0};
    }

    // Calculate daily totals
    for (final session in sessions) {
      final dayOfWeek = session.completedAt.weekday;
      weekData[dayOfWeek]!['minutes'] =
          weekData[dayOfWeek]!['minutes']! + (session.duration / 60);

      final sessionCalories = CalorieService.calculateSessionCalories(
        session: session,
        userWeightKg: userWeight,
      );
      weekData[dayOfWeek]!['calories'] =
          weekData[dayOfWeek]!['calories']! + sessionCalories;
    }

    // Create bar groups for twin bars
    final barGroups = <BarChartGroupData>[];
    final maxMinutes = weekData.values
        .map((v) => v['minutes']!)
        .reduce((a, b) => a > b ? a : b);
    final maxCalories = weekData.values
        .map((v) => v['calories']!)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxMinutes > (maxCalories / 10)
        ? maxMinutes
        : (maxCalories / 10);

    for (int day = 1; day <= 7; day++) {
      final dayData = weekData[day]!;
      barGroups.add(
        BarChartGroupData(
          x: day - 1,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: dayData['minutes']!,
              color: AppColors.steelBlue,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: dayData['calories']! / 10, // Scale calories down for display
              color: AppColors.orange,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY + 10,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.darkGray,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.darkGray,
                      fontSize: 12,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode
                  ? AppColors.darkGray.withOpacity(0.2)
                  : AppColors.lightGray.withOpacity(0.5),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(
    List<WorkoutSession> monthSessions,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: isDarkMode
            ? Border.all(color: AppColors.darkGray.withOpacity(0.3))
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Activity',
                style: AppTextStyles.headline3.copyWith(
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          SizedBox(
            height: 200,
            child: _buildWorkoutBarChart(monthSessions, isDarkMode),
          ),
          const SizedBox(height: AppDimensions.marginMedium),

          // AI Workout Generation Options
          _buildWorkoutGenerationOptions(isDarkMode),
          const SizedBox(height: AppDimensions.marginMedium),

          _buildTodaysWorkoutButton(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildWorkoutBarChart(List<WorkoutSession> sessions, bool isDarkMode) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Create a set to track days with workouts (regardless of how many)
    final daysWithWorkouts = <int>{};

    // Mark days that have at least one workout
    for (final session in sessions) {
      final day = session.completedAt.day;
      daysWithWorkouts.add(day);
    }

    // Create bar chart data - group by weeks
    final barGroups = <BarChartGroupData>[];
    final weeks = (daysInMonth / 7).ceil();

    for (int week = 0; week < weeks; week++) {
      final startDay = week * 7 + 1;
      final endDay = (week + 1) * 7;

      final weekDays = <int>[];
      for (int day = startDay; day <= endDay && day <= daysInMonth; day++) {
        weekDays.add(day);
      }

      // Calculate number of days with workouts in this week (max 7)
      final workoutDaysInWeek = weekDays
          .where((day) => daysWithWorkouts.contains(day))
          .length;

      // Determine bar color based on workout frequency
      Color barColor;
      if (workoutDaysInWeek == 0) {
        barColor = AppColors.lightGray; // No workouts
      } else if (workoutDaysInWeek >= 4) {
        barColor = AppColors.forestGreen; // Good consistency (4+ days)
      } else {
        barColor = Colors.redAccent.withOpacity(0.7); // Below target (< 4 days)
      }

      barGroups.add(
        BarChartGroupData(
          x: week,
          barRods: [
            BarChartRodData(
              toY: workoutDaysInWeek.toDouble(),
              color: barColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: 7, // Maximum 7 days per week
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1, // Show every number (1, 2, 3, 4, 5, 6, 7)
              getTitlesWidget: (value, meta) {
                // Only show labels for whole numbers from 1 to 7
                if (value % 1 == 0 && value >= 1 && value <= 7) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.darkGray,
                      fontSize: 12,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final week = value.toInt() + 1;
                return Text(
                  'W$week',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.darkGray,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode
                  ? AppColors.darkGray.withOpacity(0.2)
                  : AppColors.lightGray.withOpacity(0.5),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    List<WorkoutSession> sessions,
    double userWeight,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: isDarkMode
            ? Border.all(color: AppColors.darkGray.withOpacity(0.3))
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
                  color: AppColors.forestGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: AppTextStyles.headline3.copyWith(
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          ...sessions
              .take(3)
              .map(
                (session) =>
                    _buildRecentWorkoutCard(session, userWeight, isDarkMode),
              ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkoutCard(
    WorkoutSession session,
    double userWeight,
    bool isDarkMode,
  ) {
    final sessionCalories = CalorieService.calculateSessionCalories(
      session: session,
      userWeightKg: userWeight,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkBackground.withOpacity(0.5)
            : AppColors.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.fitness_center,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Session',
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDuration(session.duration)} • ${sessionCalories.round()} cal',
                  style: AppTextStyles.caption.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface.withOpacity(0.7)
                        : AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(session.completedAt),
            style: AppTextStyles.caption.copyWith(
              color: isDarkMode
                  ? AppColors.darkOnSurface.withOpacity(0.5)
                  : AppColors.darkGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // ==================== STREAK FUNCTIONALITY ====================

  /// Calculate the current workout streak in weeks
  /// A week is considered "complete" if user worked out 3+ days in that week
  int _calculateCurrentStreak(List<WorkoutSession> allSessions) {
    if (allSessions.isEmpty) return 0;

    final now = DateTime.now();
    int streakWeeks = 0;

    // Start from current week and go backwards
    for (int weekOffset = 0; weekOffset < 52; weekOffset++) {
      // Calculate the start and end of the week we're checking
      final weekStart = now.subtract(
        Duration(days: now.weekday - 1 + (weekOffset * 7)),
      );
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Normalize to start of day for accurate comparison
      final weekStartNormalized = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );
      final weekEndNormalized = DateTime(
        weekEnd.year,
        weekEnd.month,
        weekEnd.day,
        23,
        59,
        59,
      );

      // Count workout days in this week
      final workoutDaysInWeek = <String>{};

      for (final session in allSessions) {
        final sessionDate = session.completedAt;
        if (sessionDate.isAfter(weekStartNormalized) &&
            sessionDate.isBefore(weekEndNormalized)) {
          // Add the date (year-month-day) to the set to count unique days
          final dayKey =
              '${sessionDate.year}-${sessionDate.month}-${sessionDate.day}';
          workoutDaysInWeek.add(dayKey);
        }
      }

      // Check if this week meets the streak criteria (3+ workout days)
      if (workoutDaysInWeek.length >= 3) {
        streakWeeks++;
      } else {
        // Streak is broken, stop counting
        break;
      }
    }

    return streakWeeks;
  }

  /// Get workout days for current week
  int _getCurrentWeekWorkoutDays(List<WorkoutSession> allSessions) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartNormalized = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    final workoutDaysThisWeek = <String>{};

    for (final session in allSessions) {
      final sessionDate = session.completedAt;
      if (sessionDate.isAfter(weekStartNormalized) &&
          sessionDate.isBefore(now)) {
        final dayKey =
            '${sessionDate.year}-${sessionDate.month}-${sessionDate.day}';
        workoutDaysThisWeek.add(dayKey);
      }
    }

    return workoutDaysThisWeek.length;
  }

  /// Build the streak section widget
  Widget _buildStreakSection(
    List<WorkoutSession> allSessions,
    bool isDarkMode,
  ) {
    final currentStreak = _calculateCurrentStreak(allSessions);
    final currentWeekDays = _getCurrentWeekWorkoutDays(allSessions);

    // Only show streak if it's 3 or more weeks, or if current week has 2+ days
    if (currentStreak < 3 && currentWeekDays < 2) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginLarge),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
            const Color(0xFFFF6B35), // Orange-red for "burning"
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Icon(
                  currentStreak >= 3
                      ? Icons.local_fire_department
                      : Icons.whatshot,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStreak >= 3
                          ? '🔥 STREAK ON FIRE!'
                          : '💪 BUILDING MOMENTUM',
                      style: AppTextStyles.headline3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentStreak >= 3
                          ? '$currentStreak consecutive weeks strong!'
                          : '$currentWeekDays days this week - keep going!',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar for current week
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'This Week Progress',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$currentWeekDays/3 days',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                child: LinearProgressIndicator(
                  value: (currentWeekDays / 3).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    currentWeekDays >= 3 ? Colors.greenAccent : Colors.white,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentWeekDays >= 3
                    ? '🎉 Week goal achieved! Keep the streak alive!'
                    : 'Need ${3 - currentWeekDays} more day${3 - currentWeekDays != 1 ? 's' : ''} to maintain streak',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutGenerationOptions(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isDarkMode
              ? AppColors.darkOnSurface.withOpacity(0.3)
              : AppColors.lightGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Smart Generation from History',
                style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isSmartGenerationAvailable
                ? 'Based on your past workouts and preferences ($_recentWorkoutsCount workouts found)'
                : 'Requires 4+ workouts in past 7 days ($_recentWorkoutsCount/4)',
            style: AppTextStyles.caption.copyWith(
              color: _isSmartGenerationAvailable
                  ? (isDarkMode
                        ? AppColors.darkOnSurface.withOpacity(0.7)
                        : AppColors.onSurface.withOpacity(0.7))
                  : (isDarkMode
                        ? AppColors.darkOnSurface.withOpacity(0.5)
                        : AppColors.onSurface.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: AppDimensions.marginMedium),

          // Duration selection
          Text(
            'Duration (minutes)',
            style: AppTextStyles.bodyText2.copyWith(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Row(
            children: _durationOptions.map((duration) {
              final isSelected = _selectedDuration == duration;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDuration = duration),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDarkMode
                                  ? AppColors.darkBackground
                                  : AppColors.background),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDarkMode
                                    ? AppColors.darkOnSurface.withOpacity(0.3)
                                    : AppColors.lightGray),
                        ),
                      ),
                      child: Text(
                        '$duration min',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyText2.copyWith(
                          color: isSelected
                              ? AppColors.onPrimary
                              : (isDarkMode
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysWorkoutButton(bool isDarkMode) {
    return Column(
      children: [
        // Information text about smart generation requirements
        if (!_isSmartGenerationAvailable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkSurface.withOpacity(0.5)
                  : AppColors.lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode
                    ? AppColors.darkOnSurface.withOpacity(0.2)
                    : AppColors.lightGray.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDarkMode
                      ? AppColors.darkOnSurface.withOpacity(0.7)
                      : AppColors.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Smart generation needs 4+ workouts in the past 7 days. You currently have $_recentWorkoutsCount.',
                    style: AppTextStyles.caption.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.7)
                          : AppColors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // The actual button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSmartGenerationAvailable
                ? () => _generateTodaysWorkout(context)
                : null,
            icon: Icon(
              Icons.auto_awesome,
              size: 18,
              color: _isSmartGenerationAvailable
                  ? AppColors.onPrimary
                  : (isDarkMode
                        ? AppColors.darkOnSurface.withOpacity(0.5)
                        : AppColors.onSurface.withOpacity(0.5)),
            ),
            label: Text(
              _isSmartGenerationAvailable
                  ? "Generate Smart Workout (${_selectedDuration}min)"
                  : "Smart Generation Unavailable (${_selectedDuration}min)",
              style: AppTextStyles.bodyText1.copyWith(
                color: _isSmartGenerationAvailable
                    ? AppColors.onPrimary
                    : (isDarkMode
                          ? AppColors.darkOnSurface.withOpacity(0.5)
                          : AppColors.onSurface.withOpacity(0.5)),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSmartGenerationAvailable
                  ? AppColors.primary
                  : (isDarkMode
                        ? AppColors.darkSurface.withOpacity(0.3)
                        : AppColors.lightGray.withOpacity(0.3)),
              foregroundColor: _isSmartGenerationAvailable
                  ? AppColors.onPrimary
                  : (isDarkMode
                        ? AppColors.darkOnSurface.withOpacity(0.5)
                        : AppColors.onSurface.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: _isSmartGenerationAvailable ? 2 : 0,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateTodaysWorkout(BuildContext context) async {
    // Safety check - this shouldn't be called if smart generation is not available
    if (!_isSmartGenerationAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Smart generation requires 4+ workouts in the past 7 days. You currently have $_recentWorkoutsCount.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to generate workouts')),
        );
        return;
      }

      final userId = authProvider.user!.id;

      // Get recent workout sessions (last 7 days or last 4 sessions)
      await workoutProvider.loadUserWorkoutSessions(userId);
      final recentSessions = workoutProvider.workoutSessions
          .where((session) {
            final daysDifference = DateTime.now()
                .difference(session.completedAt)
                .inDays;
            return daysDifference <= 7;
          })
          .take(4)
          .toList();

      // Extract recent exercise names from recent sessions (prefer session data)
      // Use a set to deduplicate across multiple sessions
      final recentExerciseNamesSet = <String>{};
      for (final session in recentSessions) {
        try {
          for (final completed in session.completedExercises) {
            final name = completed.exerciseName.toString().trim();
            if (name.isNotEmpty) recentExerciseNamesSet.add(name);
          }
        } catch (e) {
          // Failed to extract exercises from session, skip
        }
      }

      final recentExerciseNames = recentExerciseNamesSet.toList();

      // Create flattened smart workout parameters for better token efficiency
      final flattenedParams = <String, dynamic>{
        'duration': _selectedDuration,
        'recentExerciseNames': recentExerciseNames,
        'excludeWarmup': false, // Could make this configurable later
      };

      // Generate the workout using AI with enhanced MCP context
      final aiWorkoutService = AIWorkoutService();

      // Try the smart workout method first (designed for MCP)
      Workout? generatedWorkout;
      try {
        generatedWorkout = await aiWorkoutService.generateSmartWorkout(
          userId: userId,
          preferences: flattenedParams,
        );
        print('✅ Smart workout generation with MCP successful');
      } catch (e) {
        print(
          '⚠️ Smart workout failed, falling back to regular generation: $e',
        );
        // Add required goal parameter for fallback method
        final fallbackParams = Map<String, dynamic>.from(flattenedParams);
        fallbackParams['goal'] =
            'Build muscle and improve fitness'; // Default goal
        fallbackParams['fitnessLevel'] =
            'intermediate'; // Default fitness level
        fallbackParams['workoutType'] = 'full-body'; // Default workout type

        generatedWorkout = await aiWorkoutService.generateWorkout(
          fallbackParams,
        );
      }

      Navigator.of(context).pop(); // Close loading dialog

      if (generatedWorkout != null) {
        // Persist the generated workout to Firestore so it shows up in Workouts
        final savedId = await workoutProvider.saveWorkout(
          generatedWorkout,
          userId,
        );

        if (savedId == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save generated workout.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return; // Don't continue if we couldn't save the workout
        }

        // Ensure the workout we pass forward has the real saved ID
        final savedWorkout = generatedWorkout.copyWith(id: savedId);

        // Navigate to workout review screen first
        if (context.mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutReviewScreen(workout: savedWorkout),
            ),
          );

          // If workout was completed, refresh the dashboard
          if (result == true && context.mounted) {
            setState(() {
              // This will trigger a rebuild and refresh the data
            });
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate workout. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Error generating today\'s workout: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating workout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
