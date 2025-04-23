import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/budget.dart';
import 'package:finmate/screens/home/budgets%20goals%20screens/budgets_screen.dart'; // For GradientProgressBar
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

  @override
  void initState() {
    super.initState();
    budget = widget.budget;
    totalBudget = double.tryParse(budget.totalBudget ?? '0') ?? 0;
    spendings = double.tryParse(budget.spendings ?? '0') ?? 0;
    progress = totalBudget > 0 ? (spendings / totalBudget) : 0.0;
    remaining = (totalBudget - spendings).abs();
    isOverBudget = progress > 1.0;

    // Format month name
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = budget.date?.month != null ? months[budget.date!.month - 1] : '';
    final year = budget.date?.year ?? DateTime.now().year;
    budgetPeriod = "$month $year Budget";
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
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallProgressCard(),
          sbh20,
          _buildCategoryBreakdownCard(),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard() {
    final displayProgress = progress.clamp(0.0, 1.0); // Cap progress at 100% for display
    final percentage = (progress * 100).toStringAsFixed(1);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 12.0,
              percent: displayProgress,
              center: Text(
                "${(displayProgress * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                  color: isOverBudget ? Colors.red : color3,
                ),
              ),
              progressColor: isOverBudget ? Colors.red : color3,
              backgroundColor: (isOverBudget ? Colors.red : color3).withAlpha(50),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1200,
            ),
            sbh20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn("Total Budget", "₹${totalBudget.toStringAsFixed(2)}", color1),
                _buildInfoColumn("Spent", "₹${spendings.toStringAsFixed(2)}", Colors.orange),
                _buildInfoColumn(
                  isOverBudget ? "Overspent" : "Remaining",
                  "₹${remaining.toStringAsFixed(2)}",
                  isOverBudget ? Colors.red : Colors.green,
                ),
              ],
            ),
            if (isOverBudget) ...[
              sbh15,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  sbw5,
                  Text(
                    "You've exceeded your budget by $percentage%!",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        sbh5,
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard() {
    if (budget.categoryBudgets == null || budget.categoryBudgets!.isEmpty) {
      return const SizedBox.shrink(); // No categories to show
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Category Breakdown",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            const Divider(height: 25),
            ...budget.categoryBudgets!.entries.map((entry) {
              final categoryName = entry.key;
              final categoryData = entry.value;
              final allocated = categoryData['allocated'] ?? '0';
              final spent = categoryData['spent'] ?? '0';
              final percentage = categoryData['percentage'] ?? '0';

              return _buildCategoryItem(
                categoryName,
                allocated,
                spent,
                percentage,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
      String category, String allocated, String spent, String percentage) {
    final allocatedAmount = double.tryParse(allocated) ?? 0;
    final spentAmount = double.tryParse(spent) ?? 0;
    final percentageValue = double.tryParse(percentage) ?? 0;
    final isOverCategoryBudget = spentAmount > allocatedAmount;

    final colors = [
      color3, Colors.orange, Colors.purple, Colors.teal, Colors.indigo, Colors.pink,
    ];
    final colorIndex = category.hashCode % colors.length;
    final categoryColor = colors[colorIndex.abs()];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle),
              ),
              sbw10,
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color1),
                ),
              ),
              Text(
                "₹${spentAmount.toStringAsFixed(0)} / ₹${allocatedAmount.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 14,
                  color: isOverCategoryBudget ? Colors.red : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          sbh10,
          GradientProgressBar(
            value: (percentageValue / 100).clamp(0.0, 1.0),
            height: 8,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}
