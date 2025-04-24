import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/budget.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/transaction_category.dart';
import 'package:finmate/providers/budget_provider.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/budgets%20goals%20screens/budget_overview.dart'; 
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  // Add a map to track category visibility for each budget
  final Map<String?, bool> _categoryVisibility = {};

  // Add a map to track animation triggers for each budget
  final Map<String?, bool> _animationTriggered = {};

  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: _appBar(),
      body: _body(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color3,
        onPressed: _showMonthPicker,
        child: Icon(Icons.addchart_rounded, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: color4,
      centerTitle: true,
      title: const Text("Budgets"),
      actions: [
        Icon(
          Icons.track_changes_rounded,
          color: color3,
          size: 30,
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  /// Main content builder that shows either empty state or budget list
  Widget _body() {
    final budgets = ref.watch(budgetNotifierProvider);

    if (budgets.isEmpty) {
      return _emptyBudgetState();
    } else {
      // Sort budgets by date in ascending order (earliest first)
      final sortedBudgets = List<Budget>.from(budgets);
      sortedBudgets.sort((a, b) {
        // Default to current date if date is null
        final dateA = a.date ?? DateTime.now();
        final dateB = b.date ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      return _budgetsList(sortedBudgets);
    }
  }

  /// Displays a message and create button when no budgets exist
  Widget _emptyBudgetState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: color3.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 75,
                color: color3.withAlpha(204),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No budgets found",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Create a budget to track your expenses and stay on top of your financial goals",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            InkWell(
              onTap: _showMonthPicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: color3,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color3.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Create Budget",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  /// Creates a scrollable list of budget cards
  Widget _budgetsList(List<Budget> budgets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final totalBudget = double.tryParse(budget.totalBudget ?? '0') ?? 0;
        final spendings = double.tryParse(budget.spendings ?? '0') ?? 0;
        final progress = totalBudget > 0 ? (spendings / totalBudget) : 0.0;

        return _budgetCard(budget, progress);
      },
    );
  }

  /// Builds a card view for a single budget with progress tracking
  /// Shows total amount, spending progress, and category breakdown
  Widget _budgetCard(Budget budget, double progress) {
    final isOverBudget = progress > 1;
    final percentage = (progress * 100).clamp(0, 100).toStringAsFixed(1);
    final totalBudget = double.tryParse(budget.totalBudget ?? '0') ?? 0;
    final spendings = double.tryParse(budget.spendings ?? '0') ?? 0;
    final remaining = (totalBudget - spendings).abs();

    // Initialize visibility state for this budget if not already set
    _categoryVisibility[budget.bid] ??= false;
    _animationTriggered[budget.bid] ??= false;

    final bool isCategoryVisible = _categoryVisibility[budget.bid] ?? false;
    final bool hasAnimationTriggered = _animationTriggered[budget.bid] ?? false;

    // Format month name
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
      'Dec'
    ];
    final month =
        budget.date?.month != null ? months[budget.date!.month - 1] : '';
    final year = budget.date?.year ?? DateTime.now().year;
    final budgetPeriod = "$month $year Budget";

    return InkWell(
      onTap: () {
        Navigate()
            .push(BudgetOverviewScreen(budget: budget)); // Navigate on tap
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with period and percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budgetPeriod,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOverBudget
                          ? Colors.red.withAlpha(38)
                          : color3.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$percentage%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : color3,
                      ),
                    ),
                  ),
                ],
              ),

              // Progress bar visualization with animation
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(
                        begin: 0, end: progress > 1 ? 1 : progress),
                    builder: (context, animatedProgress, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          GradientProgressBar(
                            value: animatedProgress,
                            height: 12,
                            borderRadius: 8,
                          ),
                          Text(
                            "${(animatedProgress == 0)?"   ":""}${(animatedProgress * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 10, // Adjusted size for better fit
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .white, // White for contrast on gradient
                              shadows: [
                                // Add shadow for readability
                                Shadow(
                                  blurRadius: 1.0,
                                  color: Colors.black.withAlpha(
                                      153), // Changed from withOpacity(0.6)
                                  offset: Offset(0.5, 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              // Budget summary info (total, spent, remaining)
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _budgetInfoItem(
                    title: "Total Budget",
                    amount: "₹$totalBudget",
                    color: color3,
                    icon: Icons.account_balance_wallet,
                  ),
                  _budgetInfoItem(
                    title: "Spent",
                    amount: "₹$spendings",
                    color: Colors.orange,
                    icon: Icons.shopping_cart_outlined,
                  ),
                  _budgetInfoItem(
                    title: isOverBudget ? "Overspent" : "Remaining",
                    amount: "₹$remaining",
                    color: isOverBudget ? Colors.red : Colors.green,
                    icon: isOverBudget
                        ? Icons.warning_amber_rounded
                        : Icons.savings_outlined,
                  ),
                ],
              ),

              // category breakdown section with toggle and animation
              if (budget.categoryBudgets != null &&
                  budget.categoryBudgets!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 30),
                    // Category header with toggle button
                    InkWell(
                      onTap: () {
                        setState(() {
                          // Toggle visibility
                          _categoryVisibility[budget.bid] = !isCategoryVisible;

                          // Set animation trigger to true when expanding
                          if (!isCategoryVisible) {
                            _animationTriggered[budget.bid] = true;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Category Breakdown",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color1,
                              ),
                            ),
                            // Animated rotation for the dropdown icon
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              tween: Tween<double>(
                                begin: 0,
                                end: isCategoryVisible ? 180 : 0,
                              ),
                              builder: (_, angle, child) {
                                return Transform.rotate(
                                  angle: angle * 3.14159 / 180,
                                  child: child,
                                );
                              },
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: color3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    sbh10,
                    // Animated container for category items
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.fastOutSlowIn,
                      height: isCategoryVisible
                          ? budget.categoryBudgets!.length *
                              65.0 // Approximate height per item
                          : 0,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isCategoryVisible ? 1.0 : 0.0,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...budget.categoryBudgets!.entries.map((entry) {
                                final categoryName = entry.key;
                                final categoryData = entry.value;
                                final allocated =
                                    categoryData['allocated'] ?? '0';
                                final spent = categoryData['spent'] ?? '0';
                                final remaining =
                                    categoryData['remaining'] ?? '0';
                                final percentage =
                                    categoryData['percentage'] ?? '0';

                                return _categoryBudgetItem(
                                  categoryName,
                                  allocated,
                                  spent: spent,
                                  remaining: remaining,
                                  percentage: percentage,
                                  animationEnabled: isCategoryVisible &&
                                      hasAnimationTriggered,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates an info item with icon, title and amount for budget summaries
  Widget _budgetInfoItem({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Displays a single category item with color coding and amount
  Widget _categoryBudgetItem(
    String category,
    String allocated, {
    String spent = '0',
    String remaining = '0',
    String percentage = '0',
    bool animationEnabled = false,
  }) {
    final allocatedAmount = double.tryParse(allocated) ?? 0;
    final spentAmount = double.tryParse(spent) ?? 0;
    // final remainingAmount = double.tryParse(remaining) ?? 0;
    final percentageValue = double.tryParse(percentage) ?? 0;
    final isOverBudget = spentAmount > allocatedAmount;

    final colors = [
      color3,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    // Generate a consistent color based on category name
    final colorIndex = category.hashCode % colors.length;
    final categoryColor = colors[colorIndex.abs()];

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category name and allocated amount
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color1,
                  ),
                ),
              ),
              Text(
                "₹$allocatedAmount",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          // Spent amount and percentage progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Spent: ₹$spentAmount",
                style: TextStyle(
                  fontSize: 12,
                  color: isOverBudget ? Colors.red : Colors.grey[600],
                ),
              ),
              Text(
                "${percentageValue.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOverBudget ? Colors.red : color3,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          // Animated progress bar for category
          animationEnabled
              ? Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(
                        begin: 0,
                        end: percentageValue > 0 ? percentageValue / 100 : 0,
                      ),
                      builder: (context, animatedProgress, child) {
                        return GradientProgressBar(
                          value: animatedProgress,
                          height: 6,
                          borderRadius: 4,
                        );
                      },
                    ),
                ],
              )
              : Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  GradientProgressBar(
                      value: 0,
                      height: 6,
                      borderRadius: 4,
                    ),
                ],
              ),
        ],
      ),
    );
  }

  /// Shows a month picker and creates a budget for the selected month
  void _showMonthPicker() async {
    selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT BUDGET MONTH',
      confirmText: 'CREATE BUDGET',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: color3,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Create a budget for the first day of the selected month
      // final selectedMonth = DateTime(pickedDate.year, pickedDate.month, 1);
      Logger().i(
          "Selected month in picker: ${selectedDate?.toIso8601String()}"); // Debug
      _createBudget();
    } else {
      // Handle case when no date is selected
      Logger().w("No date selected in month picker"); // Debug
      snackbarToast(
        context: context,
        text: "No date selected",
        icon: Icons.error_outline,
      );
    }
  }

  /// Handler for budget creation - opens a bottom sheet with budget form
  void _createBudget() {
    final formKey = GlobalKey<FormState>();
    final totalBudgetController = TextEditingController();
    // List<Map<String, dynamic>> selectedCategories = [];

    // Initialize with provided date
    // DateTime selectedDate =
    //     initialDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    Logger().i("Initial selectedDate in _createBudget: $selectedDate"); // Debug

    // Define months array
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
      'Dec'
    ];

    // Get expense categories from transaction_category.dart with controllers
    final expenseCategories = ExpenseCategory.values
        .map((category) => {
              'name': category.displayName,
              'icon': category.icon,
              'selected': false,
              'controller': TextEditingController(),
            })
        .toList();

    // Define state variables outside the builder
    List<Map<String, dynamic>> selectedCategories = [];
    bool isSubmitting = false;
    bool isLoadingTransactions = true;
    double currentSpending = 0;
    Map<String, double> categorySpending = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isLoadingTransactions) {
                _fetchExistingTransactionData(
                  selectedDate ?? DateTime.now(),
                  (spending, categories) {
                    // This callback will be called when transaction data is fetched
                    if (!context.mounted) return;

                    setModalState(() {
                      currentSpending = spending;
                      categorySpending = categories;
                      isLoadingTransactions = false;
                      totalBudgetController.text = spending > 0
                          ? (spending * 1.2)
                              .ceil()
                              .toString() // Suggest 20% more than current spending
                          : '';

                      // Pre-select categories with spending
                      for (var categoryData in expenseCategories) {
                        final categoryName = categoryData['name'];
                        if (categorySpending.containsKey(categoryName) &&
                            categorySpending[categoryName]! > 0) {
                          categoryData['selected'] = true;
                          (categoryData['controller'] as TextEditingController)
                                  .text =
                              categorySpending[categoryName]!.ceil().toString();
                        }
                      }

                      selectedCategories = expenseCategories
                          .where((c) => c['selected'] == true)
                          .toList();
                    });
                  },
                );
              }
            });

            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    // Header with handle bar
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            height: 5,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(100),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Create Budget for ${months[selectedDate!.month - 1]} ${selectedDate!.year}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Loading indicator or main content
                    isLoadingTransactions
                        ? Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: color3),
                                  SizedBox(height: 20),
                                  Text(
                                    "Analyzing your transactions...",
                                    style: TextStyle(
                                      color: color1,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Current spending summary card
                                  if (currentSpending > 0)
                                    Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current Spending Summary',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: color1,
                                              ),
                                            ),
                                            SizedBox(height: 15),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Total Spent:",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: color1,
                                                  ),
                                                ),
                                                Text(
                                                  "₹${currentSpending.toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              "Spending by Category:",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: color1,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            ...categorySpending.entries
                                                .where((e) => e.value > 0)
                                                .map((entry) => Padding(
                                                      padding: EdgeInsets.only(
                                                          bottom: 5),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            "• ${entry.key}",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                          Expanded(
                                                              child: SizedBox(
                                                            child: Divider(
                                                              indent: 20,
                                                              endIndent: 20,
                                                            ),
                                                          )),
                                                          Text(
                                                            "₹${entry.value.toStringAsFixed(2)}",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[800],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                          ],
                                        ),
                                      ),
                                    ),

                                  SizedBox(height: 20),

                                  // Total Budget Card
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Budget Amount',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: color1,
                                            ),
                                          ),
                                          SizedBox(height: 15),
                                          TextFormField(
                                            controller: totalBudgetController,
                                            decoration: InputDecoration(
                                              labelText: 'Budget Amount',
                                              prefixIcon: Icon(
                                                  Icons.account_balance_wallet,
                                                  color: color3),
                                              prefixText: '₹ ',
                                              prefixStyle: TextStyle(
                                                color: color1,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 15,
                                                      horizontal: 15),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color:
                                                        color1.withAlpha(100)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color: color3, width: 2),
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter a budget amount';
                                              }
                                              if (double.tryParse(value) ==
                                                  null) {
                                                return 'Please enter a valid number';
                                              }
                                              if (double.parse(value) <= 0) {
                                                return 'Budget must be greater than zero';
                                              }
                                              if (double.parse(value) <
                                                  currentSpending) {
                                                return 'Budget cannot be less than current spending';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 20),

                                  // Category Budgets Card
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header with title and button
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Category Budgets',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: color1,
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () {
                                                  _showCategorySelectionDialog(
                                                      context,
                                                      expenseCategories,
                                                      (categories) {
                                                    setState(() {
                                                      selectedCategories =
                                                          categories
                                                              .where((c) =>
                                                                  c['selected'] ==
                                                                  true)
                                                              .toList();
                                                    });
                                                  });
                                                },
                                                icon: Icon(
                                                    Icons.add_circle_outline,
                                                    color: color3),
                                                label: Text(
                                                  'Add Categories',
                                                  style:
                                                      TextStyle(color: color3),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Set specific budget amounts for different expense categories',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 15),
                                          if (selectedCategories.isEmpty)
                                            Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(20),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.category_outlined,
                                                      size: 48,
                                                      color: Colors.grey[400],
                                                    ),
                                                    SizedBox(height: 10),
                                                    Text(
                                                      'No categories selected',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(height: 5),
                                                    Text(
                                                      'Tap "Add Categories" to allocate your budget',
                                                      style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 14,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            ...selectedCategories
                                                .map((category) {
                                              return Padding(
                                                padding:
                                                    EdgeInsets.only(bottom: 15),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      category['icon'] ??
                                                          Icons.category,
                                                      color: color3,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        category['name'],
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: TextFormField(
                                                        controller: category[
                                                            'controller'],
                                                        decoration:
                                                            InputDecoration(
                                                          prefixText: '₹ ',
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          12),
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (value) {
                                                          if (value != null &&
                                                              value
                                                                  .isNotEmpty &&
                                                              double.tryParse(
                                                                      value) ==
                                                                  null) {
                                                            return 'Invalid number';
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                    // Submit button - fixed at bottom
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color3,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            setModalState(() {
                              isSubmitting = true;
                            });

                            final userData = ref.read(userDataNotifierProvider);
                            final totalBudget = totalBudgetController.text;

                            // Build category budgets map with detailed structure
                            final Map<String, Map<String, String>>
                                categoryBudgets = {};
                            for (var category in selectedCategories) {
                              final allocatedValue =
                                  category['controller'].text;
                              if (allocatedValue.isNotEmpty) {
                                final allocated = double.parse(allocatedValue);
                                final spent =
                                    categorySpending[category['name']] ?? 0.0;
                                final remaining = allocated - spent;
                                final percentage = allocated > 0
                                    ? ((spent / allocated) * 100).clamp(0, 100)
                                    : 0.0;

                                categoryBudgets[category['name']] = {
                                  "allocated": allocatedValue,
                                  "spent": spent.toString(),
                                  "remaining": remaining.toString(),
                                  "percentage": percentage.toString(),
                                };
                              }
                            }

                            print(
                                "Creating budget with date: ${selectedDate?.toIso8601String()}");

                            // Create budget object with explicit date
                            final budget = Budget(
                              date: DateTime(selectedDate!.year,
                                  selectedDate!.month, selectedDate!.day),
                              totalBudget: totalBudget,
                              spendings: currentSpending.toString(),
                              categoryBudgets: categoryBudgets,
                            );

                            // Add debug logging
                            print(
                                "Creating budget with date: ${budget.date?.toIso8601String()}");

                            // Save budget
                            final success = await ref
                                .read(budgetNotifierProvider.notifier)
                                .createBudget(userData.uid ?? '', budget);

                            Navigate().goBack();

                            // Show success/error message
                            if (success) {
                              snackbarToast(
                                context: context,
                                text: "Budget created successfully!",
                                icon: Icons.check_circle,
                              );
                            } else {
                              snackbarToast(
                                context: context,
                                text: "Failed to create budget",
                                icon: Icons.error,
                              );
                            }
                          }
                        },
                        child: isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'Create Budget',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Fetches existing transaction data for the selected month
  void _fetchExistingTransactionData(
    DateTime selectedDate,
    Function(double totalSpending, Map<String, double> categorySpending)
        onDataFetched,
  ) {
    final userFinanceData = ref.read(userFinanceDataNotifierProvider);
    final transactions = userFinanceData.listOfUserTransactions ?? [];

    // Calculate total spending and category-wise spending for the selected month
    double totalSpending = 0;
    Map<String, double> categorySpending = {};

    // Filter transactions for the selected month and year
    final filteredTransactions = transactions.where((transaction) {
      if (transaction.transactionType != TransactionType.expense.displayName) {
        return false;
      }

      final transactionDate = transaction.date;
      return ((transactionDate?.month == selectedDate.month) &&
          (transactionDate?.year == selectedDate.year));
    }).toList();

    // Calculate spending amounts
    for (var transaction in filteredTransactions) {
      final amount =
          double.tryParse(transaction.amount?.replaceAll('-', '') ?? '0') ?? 0;
      final category = transaction.category ?? 'Others';

      totalSpending += amount;

      if (categorySpending.containsKey(category)) {
        categorySpending[category] = categorySpending[category]! + amount;
      } else {
        categorySpending[category] = amount;
      }
    }

    // Initialize spending for all expense categories
    for (var category in ExpenseCategory.values) {
      if (!categorySpending.containsKey(category.displayName)) {
        categorySpending[category.displayName] = 0;
      }
    }

    // Call the callback with the results
    onDataFetched(totalSpending, categorySpending);
  }

  // Helper method to show category selection dialog
  void _showCategorySelectionDialog(
      BuildContext context,
      List<Map<String, dynamic>> categories,
      Function(List<Map<String, dynamic>>) onSave) {
    // Create a copy of the categories to work with
    final workingCategories = List<Map<String, dynamic>>.from(categories);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Categories'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workingCategories.map((category) {
                      return FilterChip(
                        label: Text(category['name']),
                        selected: category['selected'],
                        checkmarkColor: Colors.white,
                        selectedColor: color3,
                        labelStyle: TextStyle(
                          color: category['selected'] ? Colors.white : color1,
                          fontWeight: category['selected']
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            category['selected'] = selected;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color3,
                  ),
                  onPressed: () {
                    onSave(workingCategories);
                    Navigator.pop(context);
                  },
                  child: Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Custom gradient progress bar widget that transitions from green to red
class GradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final double borderRadius;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    // Define gradient colors based on progress value
    List<Color> getGradientColors() {
      if (value < 0.4) {
        // Green to light green (safe zone)
        return [
          Colors.green.shade700,
          Colors.green.shade400,
        ];
      } else if (value < 0.7) {
        // Light green to orange (caution zone)
        return [
          Colors.green.shade400,
          Colors.orange.shade300,
        ];
      } else if (value < 0.9) {
        // Orange to red (warning zone)
        return [
          Colors.orange.shade300,
          Colors.orange.shade800,
        ];
      } else {
        // Red (danger zone)
        return [
          Colors.orange.shade800,
          Colors.red.shade700,
        ];
      }
    }

    final gradientColors = getGradientColors();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(38),
        ),
        child: FractionallySizedBox(
          widthFactor: value,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
