import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/goal.dart';
import 'package:finmate/providers/goals_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/budgets%20goals%20screens/add_edit_goal_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch goals when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGoals(showMessage: false);
    });
  }

  // Dedicated method for refreshing goals data
  Future<void> _refreshGoals({bool showMessage = true}) async {
    final user = ref.read(userDataNotifierProvider);
    if (user.uid == null || user.uid!.isEmpty) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await ref.read(goalsNotifierProvider.notifier).fetchUserGoals(user.uid!);
      if (showMessage) {
        if (mounted) {
          snackbarToast(
            context: context,
            text: "Goals refreshed successfully!",
            icon: Icons.check_circle,
          );
        }
      }
    } catch (e) {
      if (mounted && showMessage) {
        snackbarToast(
          context: context,
          text: "Failed to refresh goals",
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsNotifierProvider);
    final initialFetch = ref.watch(initialGoalsFetchProvider);

    // Filter goals by status
    final activeGoals =
        goals.where((g) => g.status == GoalStatus.active).toList();
    final completedGoals =
        goals.where((g) => g.status != GoalStatus.active).toList();

    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        title: const Text(
          "Financial Goals",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color4,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Add refresh button to app bar
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ))
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () => _refreshGoals(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: color3,
          indicatorWeight: 3,
          labelColor: color3,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "ACTIVE"),
            Tab(text: "COMPLETED"),
          ],
        ),
      ),
      body: initialFetch.when(
        data: (_) => RefreshIndicator(
          onRefresh: () => _refreshGoals(showMessage: false),
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _buildGoalsList(activeGoals, true),
                  _buildGoalsList(completedGoals, false),
                ],
              ),
              if (_isRefreshing)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Error loading goals: $error"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _refreshGoals(),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color3,
        onPressed: () {
          Navigate().push(const AddEditGoalScreen());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals, bool isActive) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.flag_outlined : Icons.flag_circle_outlined,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? "No active goals yet.\nAdd one with the + button."
                  : "No completed goals yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return GoalCard(
          goal: goal,
          onTap: () {
            // Navigate().push(GoalDetailScreen(goalId: goal.id!));
          },
        );
      },
    );
  }
}

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final bool isAchieved = goal.status == GoalStatus.achieved;
    final deadlineText = goal.deadline != null
        ? DateFormat.yMMMMd().format(goal.deadline!)
        : 'No deadline';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header row with name and EDIT BUTTON (moved here from footer)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Edit icon wrapped in InkWell
                    InkWell(
                      onTap: () {
                        Navigate().push(AddEditGoalScreen(goalId: goal.id));
                      },
                      borderRadius:
                          BorderRadius.circular(16), // Make splash circular
                      child: Container(
                        padding:
                            const EdgeInsets.all(8), // Add padding for tap area
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: color3,
                        ),
                      ),
                    ), // InkWell ends here
                  ], // Row children end here
                ), // Row ends here

                const SizedBox(height: 16),

                // Progress and amount info
                Row(
                  children: [
                    // Circular progress indicator
                    CircularPercentIndicator(
                      radius: 50,
                      lineWidth: 10,
                      percent: goal.progressPercentage,
                      center: Text(
                        '${(goal.progressPercentage * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isAchieved ? Colors.green : color3,
                        ),
                      ),
                      progressColor: isAchieved ? Colors.green : color3,
                      backgroundColor: Colors.grey[200]!,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),

                    const SizedBox(width: 16),

                    // Amount details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target: ${currencyFormat.format(goal.targetAmount)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Saved: ${currencyFormat.format(goal.currentAmount)}',
                            style: TextStyle(
                              fontSize: 15,
                              color: isAchieved ? Colors.green : null,
                              fontWeight: isAchieved ? FontWeight.bold : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAchieved
                                ? 'Goal achieved!'
                                : 'Remaining: ${currencyFormat.format(goal.remainingAmount)}',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  isAchieved ? Colors.green : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Footer with deadline and STATUS CHIP (moved here from header)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deadlineText,
                          style: TextStyle(
                            color: goal.deadline != null &&
                                    goal.deadline!.isBefore(DateTime.now())
                                ? Colors.redAccent
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    // Status chip moved here
                    _buildStatusChip(goal.status),
                  ],
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildStatusChip(GoalStatus status) {
    Color color;
    String text;

    switch (status) {
      case GoalStatus.active:
        color = color3;
        text = 'Active';
        break;
      case GoalStatus.achieved:
        color = Colors.green;
        text = 'Achieved';
        break;
      case GoalStatus.archived:
        color = Colors.grey;
        text = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 opacity = 25.5 alpha, rounded to 26
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color
                .withAlpha(128)), // 0.5 opacity = 127.5 alpha, rounded to 128
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
