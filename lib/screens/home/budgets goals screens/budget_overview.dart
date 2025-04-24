import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/budget.dart';
import 'package:finmate/providers/budget_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class BudgetOverviewScreen extends ConsumerStatefulWidget {
  final Budget budget;
  const BudgetOverviewScreen({super.key, required this.budget});

  @override
  ConsumerState<BudgetOverviewScreen> createState() =>
      _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends ConsumerState<BudgetOverviewScreen> {
  late Budget budget;
  late double totalBudget;
  late double spendings;
  late double progress;
  late double remaining;
  late bool isOverBudget;
  late String budgetPeriod;

  // Controller for category navigation
  late ValueNotifier<int> _currentCategoryIndex;

  @override
  void initState() {
    super.initState();
    _initializeBudgetData();
  }

  @override
  void dispose() {
    _currentCategoryIndex.dispose();
    super.dispose();
  }

  /// Initialize all budget data with safe fallbacks
  void _initializeBudgetData() {
    budget = widget.budget;

    // Parse numeric values with safe defaults
    totalBudget = double.tryParse(budget.totalBudget ?? '0') ?? 0;
    spendings = double.tryParse(budget.spendings ?? '0') ?? 0;

    // Calculate derived values
    progress = totalBudget > 0
        ? (spendings / totalBudget).clamp(0.0, double.infinity)
        : 0.0;

    // Fix for overspent calculation: when overspent, remaining should be 0
    isOverBudget = spendings > totalBudget;
    remaining =
        isOverBudget ? spendings - totalBudget : totalBudget - spendings;

    // Format period string
    final months = [
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
      'December'
    ];
    final month = budget.date?.month != null &&
            budget.date!.month >= 1 &&
            budget.date!.month <= 12
        ? months[budget.date!.month - 1]
        : 'Month';
    final year = budget.date?.year ?? DateTime.now().year;
    budgetPeriod = "$month $year Budget";

    // Initialize category index controller
    _currentCategoryIndex = ValueNotifier<int>(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: _appBar(),
      body: _body(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: color4,
      title: Text(budgetPeriod),
      centerTitle: true,
      actions: [
        // Use OutlinedButton styled as a circle
        Padding(
          padding:
              const EdgeInsets.only(right: 8.0), // Adjust spacing if needed
          child: OutlinedButton(
            onPressed: _confirmDeleteBudget,
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.all(8), // Adjust padding for icon size
              minimumSize:
                  const Size(40, 40), // Ensure a reasonable tap target size
              foregroundColor: Colors.red, // Color for splash/highlight
            ),
            child: const Icon(Icons.delete, color: Colors.red, size: 20),
          ),
        ),
      ],
    );
  }

  // Add this method to handle budget deletion with confirmation
  void _confirmDeleteBudget() {
    showYesNoDialog(
      context,
      title: 'Delete Budget',
      contentWidget: Text('Are you sure you want to delete the $budgetPeriod?'),
      onTapYes: () async {
        final userData = ref.read(userDataNotifierProvider);
        final success = await ref
            .read(budgetNotifierProvider.notifier)
            .deleteBudget(userData.uid ?? '', budget.bid ?? '');

        if (success) {
          // Show success message and navigate back
          if (mounted) {
            snackbarToast(
              context: context,
              text: "Budget deleted successfully",
              icon: Icons.check_circle,
            );
            Navigate().goBack();
            Navigate().goBack();
          }
        } else {
          // Show error message
          if (mounted) {
            snackbarToast(
              context: context,
              text: "Failed to delete budget",
              icon: Icons.error,
            );
          }
        }
      },
      onTapNo: () {
        Navigate().goBack();
      },
    );
  }

  Widget _body() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallProgressCard(),
            sbh20,
            _buildCategoryBreakdownCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard() {
    // Fix remaining percentage calculation
    final remainingPercentage = totalBudget > 0
        ? (isOverBudget
            ? "${((spendings - totalBudget) / totalBudget * 100).clamp(0, 100).toStringAsFixed(1)}%"
            : "${((remaining / totalBudget) * 100).clamp(0, 100).toStringAsFixed(1)}%")
        : "0%";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Budget Overview",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            const Divider(height: 30),

            // Row with Total Budget and Spending information
            Row(
              children: [
                Expanded(
                  child: _buildAmountDisplay(
                    title: "Total Budget",
                    amount: totalBudget,
                    color: color3,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: _buildAmountDisplay(
                    title: "Spent",
                    amount: spendings,
                    color: Colors.orange,
                    icon: Icons.shopping_cart_outlined,
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Remaining balance with progress bar
            Center(
              child: LayoutBuilder(builder: (context, constraints) {
                return Column(
                  spacing: 15,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 15,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isOverBudget ? Colors.red : Colors.green)
                                .withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOverBudget
                                ? Icons.warning_amber_rounded
                                : Icons.savings_outlined,
                            color: isOverBudget ? Colors.red : Colors.green,
                            size: 24,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOverBudget ? "Overspent" : "Remaining",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: color1,
                              ),
                            ),
                            Text(
                              "₹${remaining.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isOverBudget ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          remainingPercentage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOverBudget ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),

                    // Half-width progress bar for remaining
                    LinearProgressIndicator(
                      value: isOverBudget
                          ? 0.0
                          : totalBudget > 0
                              ? (remaining / totalBudget).clamp(0.0, 1.0)
                              : 0.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget ? Colors.red : Colors.green),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                );
              }),
            ),

            // Warning message for overspent budget
            if (isOverBudget) ...[
              SizedBox(height: 15),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(
                        26), // 0.1 opacity = 25.5 alpha, rounded to 26
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Exceeded by ${(progress * 100 - 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDisplay({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard() {
    // Early return if no categories
    if (budget.categoryBudgets == null || budget.categoryBudgets!.isEmpty) {
      return _buildNoCategoriesCard();
    }

    // Use a safe list of categories
    final List<MapEntry<String, Map<String, String>>> categories =
        budget.categoryBudgets!.entries.toList();

    // Initialize the current index controller with a valid range
    if (_currentCategoryIndex.value >= categories.length) {
      _currentCategoryIndex.value = 0;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<int>(
                valueListenable: _currentCategoryIndex,
                builder: (context, index, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Category Breakdown",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color1,
                        ),
                      ),
                      Text(
                        "${index + 1}/${categories.length}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  );
                }),
            const Divider(height: 25),

            // Category with navigation controls
            ValueListenableBuilder<int>(
              valueListenable: _currentCategoryIndex,
              builder: (context, index, _) {
                // Check for empty categories
                if (categories.isEmpty) {
                  return _buildNoDataAvailableWidget();
                }

                // Safe index access
                index = index.clamp(0, categories.length - 1);
                final categoryEntry = categories[index];

                return Row(
                  children: [
                    // Left navigation button
                    IconButton(
                      icon: Icon(Icons.chevron_left,
                          color:
                              index > 0 ? color3 : Colors.grey.withOpacity(0.3),
                          size: 30),
                      onPressed: index > 0
                          ? () => _currentCategoryIndex.value = index - 1
                          : null,
                    ),

                    // Category card
                    Expanded(
                      child: _buildCategoryCard(
                        categoryEntry.key,
                        categoryEntry.value['allocated'] ?? '0',
                        categoryEntry.value['spent'] ?? '0',
                        categoryEntry.value['percentage'] ?? '0',
                      ),
                    ),

                    // Right navigation button
                    IconButton(
                      icon: Icon(Icons.chevron_right,
                          color: index < categories.length - 1
                              ? color3
                              : Colors.grey.withOpacity(0.3),
                          size: 30),
                      onPressed: index < categories.length - 1
                          ? () => _currentCategoryIndex.value = index + 1
                          : null,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCategoriesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                "No Categories Available",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                "This budget doesn't have any category breakdown.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataAvailableWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 40),
          SizedBox(height: 8),
          Text(
            "No data available",
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String category, String allocated, String spent, String percentage) {
    // Safe parsing with fallbacks
    final allocatedAmount = double.tryParse(allocated) ?? 0;
    final spentAmount = double.tryParse(spent) ?? 0;
    final percentageValue = double.tryParse(percentage) ?? 0;
    final isOverBudget = spentAmount > allocatedAmount;

    // Generate a consistent color based on category name
    final colors = [
      color3,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
    ];
    final colorIndex = category.hashCode % colors.length;
    final categoryColor = colors[colorIndex.abs()];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51), // 0.2 opacity = 51 alpha
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 25,
        children: [
          // Category title with ellipsis for long names
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Circular progress indicator
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 20,
            backgroundWidth: 15,
            animation: true,
            animationDuration: 1200,
            percent: (percentageValue / 100).clamp(0.0, 1.0),
            center: Text(
              "${percentageValue.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isOverBudget ? Colors.red : categoryColor,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: isOverBudget ? Colors.red : categoryColor,
            backgroundColor:
                (isOverBudget ? Colors.red : categoryColor).withAlpha(51),
          ),

          // Amount information with proper spacing
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Allocated",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      "₹${allocatedAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Spent",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      "₹${spentAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
