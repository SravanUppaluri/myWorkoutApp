import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  bool _isCalendarExpanded = false;
  DateTime _selectedWeek = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    // Load workout data and user stats when screen initializes
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user != null) {
      final userId = authProvider.user!.id;
      // Load both workouts and workout sessions
      workoutProvider.loadUserWorkouts(userId);
      workoutProvider.loadUserWorkoutSessions(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Statistics',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: isDarkMode ? Colors.black : AppColors.surface,
          foregroundColor: isDarkMode
              ? AppColors.darkOnSurface
              : AppColors.onSurface,
          iconTheme: IconThemeData(
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
          actions: [
            IconButton(
              onPressed: () {
                final workoutProvider = Provider.of<WorkoutProvider>(
                  context,
                  listen: false,
                );
                workoutProvider.debugPrintWorkoutSessions();
              },
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug Workout Sessions',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Week Calendar Section
              _buildWeekCalendarSection(),

              const SizedBox(height: AppDimensions.marginLarge),

              // Statistics Section
              _buildStatisticsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCalendarSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A) // Darker card color for dark mode
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and expand button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week\'s Workouts',
                style: AppTextStyles.headline3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isCalendarExpanded = !_isCalendarExpanded;
                  });
                },
                icon: Icon(
                  _isCalendarExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                ),
                label: Text(
                  _isCalendarExpanded ? 'Collapse' : 'Expand',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkPrimary
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.marginMedium),

          // Week View (only shown when not expanded)
          if (!_isCalendarExpanded)
            AnimatedOpacity(
              opacity: _isCalendarExpanded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: _buildWeekView(),
            ),

          // Expanded Calendar (shown when expanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: _isCalendarExpanded ? 300 : 0,
            child: AnimatedOpacity(
              opacity: _isCalendarExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _isCalendarExpanded
                  ? Column(
                      children: [
                        const SizedBox(height: AppDimensions.marginMedium),
                        Expanded(child: _buildExpandedCalendar()),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final startOfWeek = _getStartOfWeek(_selectedWeek);

    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        return SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final hasWorkout = workoutProvider.hasWorkoutOnDate(date);
              final isToday = _isToday(date);

              return _buildDayCell(date, hasWorkout, isToday);
            }),
          ),
        );
      },
    );
  }

  Widget _buildDayCell(DateTime date, bool hasWorkout, bool isToday) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    Color dayNameColor;
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Color dotColor;

    if (isToday) {
      dayNameColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
      backgroundColor = isDarkMode
          ? AppColors.darkPrimary.withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.2);
      borderColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
      textColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
      dotColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
    } else if (hasWorkout) {
      dayNameColor = isDarkMode ? AppColors.darkGray : AppColors.darkGray;
      backgroundColor = isDarkMode
          ? AppColors.forestGreen.withValues(alpha: 0.2)
          : AppColors.forestGreen.withValues(alpha: 0.1);
      borderColor = AppColors.forestGreen;
      textColor = AppColors.forestGreen;
      dotColor = AppColors.forestGreen;
    } else {
      dayNameColor = isDarkMode ? AppColors.darkGray : AppColors.darkGray;
      backgroundColor = Colors.transparent;
      borderColor = Colors.transparent;
      textColor = isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface;
      dotColor = Colors.transparent;
    }

    return Expanded(
      child: GestureDetector(
        onTap: hasWorkout ? () => _showWorkoutDetails(date) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              // Day name
              Text(
                _getDayName(date.weekday),
                style: AppTextStyles.caption.copyWith(
                  color: dayNameColor,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                ),
              ),

              const SizedBox(height: 4),

              // Date circle with workout indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Date number
                    Text(
                      '${date.day}',
                      style: AppTextStyles.bodyText1.copyWith(
                        fontWeight: isToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: textColor,
                      ),
                    ),

                    // Workout indicator dot
                    if (hasWorkout)
                      Positioned(
                        bottom: 2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedCalendar() {
    return Column(
      children: [
        // Month/Year header with navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedWeek = DateTime(
                    _selectedWeek.year,
                    _selectedWeek.month - 1,
                    _selectedWeek.day,
                  );
                });
              },
              icon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            Text(
              _getMonthYearString(_selectedWeek),
              style: AppTextStyles.headline3.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedWeek = DateTime(
                    _selectedWeek.year,
                    _selectedWeek.month + 1,
                    _selectedWeek.day,
                  );
                });
              },
              icon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.marginMedium),

        // Calendar grid
        Expanded(child: _buildCalendarGrid()),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<AuthProvider, WorkoutProvider>(
      builder: (context, authProvider, workoutProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Statistics',
              style: AppTextStyles.headline3.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
            ),

            const SizedBox(height: AppDimensions.marginMedium),

            // Statistics tabs
            Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF2A2A2A) // Darker card color for dark mode
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: isDarkMode
                          ? const Color(0xFF64B5F6) // Light blue for dark mode
                          : AppColors.primary,
                      unselectedLabelColor: isDarkMode
                          ? Colors.grey[400]
                          : AppColors.darkGray,
                      indicatorColor: isDarkMode
                          ? const Color(0xFF64B5F6) // Light blue for dark mode
                          : AppColors.primary,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Workouts'),
                        Tab(text: 'Progress'),
                        Tab(text: 'Goals'),
                      ],
                    ),
                  ),

                  // Tab Content
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(workoutProvider, authProvider),
                        _buildWorkoutsTab(workoutProvider),
                        _buildProgressTab(workoutProvider),
                        _buildGoalsTab(authProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Tab content builders
  Widget _buildOverviewTab(
    WorkoutProvider workoutProvider,
    AuthProvider authProvider,
  ) {
    final sessions = workoutProvider.workoutSessions;
    final totalWorkouts = sessions.length;
    final thisWeekWorkouts = sessions.where((session) {
      final sessionDate = session.completedAt;
      final startOfWeek = _getStartOfWeek(DateTime.now());
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return sessionDate.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          sessionDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).length;

    final totalDuration = sessions.fold(
      0,
      (sum, session) => sum + session.duration,
    );
    final avgDuration = sessions.isNotEmpty
        ? totalDuration ~/ sessions.length
        : 0;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Workouts',
                  totalWorkouts.toString(),
                  Icons.fitness_center,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.marginSmall),
              Expanded(
                child: _buildStatCard(
                  'This Week',
                  thisWeekWorkouts.toString(),
                  Icons.calendar_today,
                  AppColors.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Time',
                  '${(totalDuration ~/ 60)}h ${totalDuration % 60}m',
                  Icons.timer,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.marginSmall),
              Expanded(
                child: _buildStatCard(
                  'Avg Duration',
                  '${avgDuration}min',
                  Icons.av_timer,
                  AppColors.forestGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab(WorkoutProvider workoutProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sessions = workoutProvider.workoutSessions;
    final workouts = workoutProvider.workouts;

    // Sort sessions by completion date (most recent first)
    final sortedSessions = List<dynamic>.from(sessions)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed Workouts',
            style: AppTextStyles.bodyText1.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white.withValues(alpha: 0.9) : null,
            ),
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Expanded(
            child: sortedSessions.isEmpty
                ? Center(
                    child: Text(
                      'No workouts completed yet',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: isDarkMode
                            ? Colors.grey[400]
                            : AppColors.darkGray,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedSessions.length,
                    itemBuilder: (context, index) {
                      final session = sortedSessions[index];

                      // Find the workout name by ID
                      final workout = workouts.firstWhere(
                        (w) => w.id == session.workoutId,
                        orElse: () => Workout(
                          id: session.workoutId,
                          name: 'Unknown Workout',
                          description: '',
                          exercises: [],
                          estimatedDuration: 0,
                          difficulty: 'Beginner',
                          createdAt: DateTime.now(),
                        ),
                      );

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: AppDimensions.marginSmall,
                        ),
                        padding: const EdgeInsets.all(
                          AppDimensions.paddingMedium,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF3A3A3A)
                              : Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                          border: isDarkMode
                              ? Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  width: 0.5,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Workout name and date
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          workout.name,
                                          style: AppTextStyles.bodyText1
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode
                                                    ? Colors.white.withValues(
                                                        alpha: 0.9,
                                                      )
                                                    : null,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        '${session.completedAt.day}/${session.completedAt.month}/${session.completedAt.year}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : AppColors.darkGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Duration and volume info
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : AppColors.darkGray,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${session.duration} min',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : AppColors.darkGray,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (session.totalVolume != null) ...[
                                        Icon(
                                          Icons.fitness_center,
                                          size: 16,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : AppColors.darkGray,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${session.totalVolume!.toStringAsFixed(1)} kg',
                                          style: AppTextStyles.caption.copyWith(
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : AppColors.darkGray,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Delete button
                            IconButton(
                              onPressed: () => _showDeleteWorkoutSessionDialog(
                                context,
                                session,
                                workout.name,
                                workoutProvider,
                              ),
                              icon: Icon(
                                Icons.delete_outline,
                                color: isDarkMode
                                    ? Colors.red[300]
                                    : Colors.red[600],
                              ),
                              tooltip: 'Delete completed workout',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab(WorkoutProvider workoutProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sessions = workoutProvider.workoutSessions;
    final last30Days = sessions.where((session) {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      return session.completedAt.isAfter(thirtyDaysAgo);
    }).toList();

    final weeklyData = <String, int>{};
    for (final session in last30Days) {
      final weekStart = _getStartOfWeek(session.completedAt);
      final weekKey = '${weekStart.day}/${weekStart.month}';
      weeklyData[weekKey] = (weeklyData[weekKey] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 30 Days Progress',
            style: AppTextStyles.bodyText1.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white.withValues(alpha: 0.9) : null,
            ),
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Expanded(
            child: weeklyData.isEmpty
                ? Center(
                    child: Text(
                      'No workout data in the last 30 days',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: isDarkMode
                            ? Colors.grey[400]
                            : AppColors.darkGray,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildStatCard(
                        'Workouts (30d)',
                        last30Days.length.toString(),
                        Icons.trending_up,
                        isDarkMode
                            ? const Color(0xFF64B5F6)
                            : AppColors.primary,
                      ),
                      const SizedBox(height: AppDimensions.marginMedium),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(
                            AppDimensions.paddingMedium,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF3A3A3A)
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSmall,
                            ),
                            border: isDarkMode
                                ? Border.all(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    width: 0.5,
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Breakdown',
                                style: AppTextStyles.bodyText2.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.marginSmall),
                              ...weeklyData.entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Week of ${entry.key}',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white.withValues(
                                                  alpha: 0.8,
                                                )
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        '${entry.value} workouts',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isDarkMode
                                              ? const Color(0xFF64B5F6)
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildGoalsTab(AuthProvider authProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.user;
    final goalData = user?.goalData;
    final motivation = user?.motivation;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Fitness Goals',
            style: AppTextStyles.bodyText1.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white.withValues(alpha: 0.9) : null,
            ),
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Expanded(
            child: goalData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag,
                          size: 48,
                          color: isDarkMode
                              ? Colors.grey[600]
                              : AppColors.darkGray.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppDimensions.marginSmall),
                        Text(
                          'No goals set yet',
                          style: AppTextStyles.bodyText2.copyWith(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : AppColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (goalData['weightGoal'] != null) ...[
                          _buildGoalItem(
                            'Weight Goal',
                            goalData['weightGoal'],
                            Icons.monitor_weight,
                          ),
                          const SizedBox(height: AppDimensions.marginSmall),
                        ],
                        if (goalData['timeframe'] != null) ...[
                          _buildGoalItem(
                            'Timeframe',
                            goalData['timeframe'],
                            Icons.schedule,
                          ),
                          const SizedBox(height: AppDimensions.marginSmall),
                        ],
                        if (goalData['specificGoals'] != null &&
                            (goalData['specificGoals'] as List).isNotEmpty) ...[
                          _buildGoalItem(
                            'Specific Goals',
                            (goalData['specificGoals'] as List).join(', '),
                            Icons.flag,
                          ),
                          const SizedBox(height: AppDimensions.marginSmall),
                        ],
                        if (motivation != null && motivation.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(
                              AppDimensions.paddingMedium,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2A2A2A)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSmall,
                              ),
                              border: isDarkMode
                                  ? Border.all(
                                      color: const Color(
                                        0xFF64B5F6,
                                      ).withValues(alpha: 0.3),
                                      width: 0.5,
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      color: isDarkMode
                                          ? const Color(0xFF64B5F6)
                                          : AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(
                                      width: AppDimensions.marginSmall,
                                    ),
                                    Text(
                                      'Your Motivation',
                                      style: AppTextStyles.bodyText2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? const Color(0xFF64B5F6)
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: AppDimensions.marginSmall,
                                ),
                                Text(
                                  motivation,
                                  style: AppTextStyles.bodyText2.copyWith(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Adjust colors for dark mode
    final cardColor = isDarkMode
        ? color.withValues(alpha: 0.2)
        : color.withValues(alpha: 0.1);
    final iconColor = isDarkMode ? color.withValues(alpha: 0.9) : color;
    final titleColor = isDarkMode ? color.withValues(alpha: 0.9) : color;
    final valueColor = isDarkMode ? color.withValues(alpha: 0.95) : color;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: isDarkMode
            ? Border.all(color: color.withValues(alpha: 0.3), width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: AppDimensions.marginSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Text(
            value,
            style: AppTextStyles.headline3.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String title, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF3A3A3A) // Darker background for dark mode
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: isDarkMode
            ? Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 0.5)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode
                ? const Color(0xFF64B5F6) // Light blue for dark mode
                : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.marginMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: isDarkMode ? Colors.grey[400] : AppColors.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyText2.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.9)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showWorkoutDetails(DateTime date) {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    final sessions = workoutProvider.getWorkoutSessionsForDate(date);

    if (sessions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Workouts on ${_formatDate(date)}',
                style: AppTextStyles.headline2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppDimensions.marginMedium),

              // Scrollable content
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) => _buildDetailedWorkoutCard(
                    sessions[index],
                    workoutProvider,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedWorkoutCard(
    dynamic session,
    WorkoutProvider workoutProvider,
  ) {
    // Find the workout name from the workoutId
    final workout = workoutProvider.workouts.firstWhere(
      (w) => w.id == session.workoutId,
      orElse: () => Workout(
        id: '',
        name: 'Unknown Workout',
        description: '',
        exercises: [],
        estimatedDuration: 0,
        difficulty: 'Beginner',
        createdAt: DateTime.now(),
        isTemplate: false,
      ),
    );

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: AppDimensions.marginMedium),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppColors.forestGreen,
            size: 24,
          ),
        ),
        title: Text(
          workout.name,
          style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Duration: ${session.formattedDuration}',
                  style: AppTextStyles.bodyText2,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.sports_gymnastics,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Exercises: ${session.completedExercises.length}',
                  style: AppTextStyles.bodyText2,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Completed at: ${_formatTime(session.completedAt)}',
                  style: AppTextStyles.bodyText2,
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise Details',
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                ...session.completedExercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return _buildExerciseDetail(exercise, index + 1);
                }).toList(),

                if (session.notes != null && session.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.lightGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: 16,
                              color: AppColors.darkGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Notes:',
                              style: AppTextStyles.bodyText2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(session.notes, style: AppTextStyles.bodyText2),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetail(dynamic exercise, int exerciseNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$exerciseNumber',
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
                  exercise.exerciseName ?? 'Unknown Exercise',
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Sets information
          if (exercise.sets != null && exercise.sets.isNotEmpty) ...[
            Text(
              'Sets:',
              style: AppTextStyles.bodyText2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 4),
            ...exercise.sets.asMap().entries.map((setEntry) {
              final setIndex = setEntry.key;
              final set = setEntry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: set.completed
                      ? AppColors.forestGreen.withValues(alpha: 0.1)
                      : AppColors.cardinalRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: set.completed
                        ? AppColors.forestGreen.withValues(alpha: 0.3)
                        : AppColors.cardinalRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      set.completed ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: set.completed
                          ? AppColors.forestGreen
                          : AppColors.cardinalRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Set ${setIndex + 1}:',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${set.reps ?? 0} reps', style: AppTextStyles.caption),
                    if ((set.weight ?? 0) > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '@ ${set.weight}kg',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.steelBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],

          // Exercise notes if available
          if (exercise.notes != null && exercise.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Note: ${exercise.notes}',
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildCalendarGrid() {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        return Column(
          children: [
            // Days of the week header
            _buildWeekHeader(),

            const SizedBox(height: 8),

            // Calendar grid
            Expanded(child: _buildMonthGrid(workoutProvider)),
          ],
        );
      },
    );
  }

  Widget _buildWeekHeader() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: dayNames
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthGrid(WorkoutProvider workoutProvider) {
    final firstDayOfMonth = DateTime(
      _selectedWeek.year,
      _selectedWeek.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedWeek.year,
      _selectedWeek.month + 1,
      0,
    );
    final firstDayOfCalendar = _getStartOfWeek(firstDayOfMonth);
    final lastDayOfCalendar = _getEndOfWeek(lastDayOfMonth);

    final totalDays =
        lastDayOfCalendar.difference(firstDayOfCalendar).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    return Column(
      children: List.generate(weeks, (weekIndex) {
        return Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
              final date = firstDayOfCalendar.add(
                Duration(days: weekIndex * 7 + dayIndex),
              );

              final isCurrentMonth = date.month == _selectedWeek.month;
              final hasWorkout = workoutProvider.hasWorkoutOnDate(date);
              final isToday = _isToday(date);

              return _buildCalendarDayCell(
                date,
                hasWorkout,
                isToday,
                isCurrentMonth,
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildCalendarDayCell(
    DateTime date,
    bool hasWorkout,
    bool isToday,
    bool isCurrentMonth,
  ) {
    // Determine colors based on state and theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    if (isToday) {
      backgroundColor = isDarkMode ? AppColors.darkPrimary : AppColors.primary;
      textColor = isDarkMode ? Colors.black : Colors.white;
      borderColor = null;
    } else if (hasWorkout && isCurrentMonth) {
      backgroundColor = isDarkMode
          ? AppColors.forestGreen
          : AppColors.forestGreen;
      textColor = isDarkMode ? Colors.black : Colors.white;
      borderColor = null;
    } else {
      backgroundColor = Colors.transparent;
      textColor = !isCurrentMonth
          ? (isDarkMode ? AppColors.darkGray : AppColors.lightGray)
          : (isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface);
      borderColor = null;
    }

    return Expanded(
      child: GestureDetector(
        onTap: hasWorkout ? () => _showWorkoutDetails(date) : null,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: backgroundColor,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: AppTextStyles.bodyText2.copyWith(
                fontWeight: isToday || (hasWorkout && isCurrentMonth)
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime _getEndOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return DateTime(date.year, date.month, date.day + daysToSunday);
  }

  // Show confirmation dialog for deleting a completed workout session
  Future<void> _showDeleteWorkoutSessionDialog(
    BuildContext context,
    dynamic session,
    String workoutName,
    WorkoutProvider workoutProvider,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : null,
          title: Text(
            'Delete Completed Workout',
            style: TextStyle(color: isDarkMode ? Colors.white : null),
          ),
          content: Text(
            'Are you sure you want to delete this completed workout?\n\n'
            'Workout: $workoutName\n'
            'Completed: ${session.completedAt.day}/${session.completedAt.month}/${session.completedAt.year}\n'
            'Duration: ${session.duration} min\n\n'
            'This action cannot be undone.',
            style: TextStyle(color: isDarkMode ? Colors.white70 : null),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: isDarkMode ? Colors.white70 : null),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Delete the workout session
                  await workoutProvider.deleteWorkoutSession(session.id);

                  Navigator.of(context).pop();

                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Completed workout deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();

                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete workout: ${e.toString()}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
