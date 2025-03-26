import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  List<String> monthsTabTitles = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      title: const Text('Analysis'),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: color1,
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.filter_list_rounded,
            color: color3,
            size: 30,
          ),
          onPressed: () {
            // Handle filer action
            snackbarToast(
                context: context,
                text: "This feature is in development❗",
                icon: Icons.developer_mode);
          },
        ),
        sbw10,
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomTabBar(
          selectedIndex: _selectedIndex,
          tabTitles: monthsTabTitles,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
        ),
      ),
    );
  }

  Widget _body() {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      itemCount: monthsTabTitles.length,
      itemBuilder: (context, index) {
        return MonthlyAnalysisCharts(
          monthInt: index + 1,
          monthName: monthsTabTitles[index],
        );
      },
    );
  }
}

class MonthlyAnalysisCharts extends ConsumerStatefulWidget {
  const MonthlyAnalysisCharts(
      {super.key, required this.monthInt, required this.monthName});
  final String monthName;
  final int monthInt;
  @override
  ConsumerState<MonthlyAnalysisCharts> createState() =>
      _MonthlyAnalysisChartsState();
}

class _MonthlyAnalysisChartsState extends ConsumerState<MonthlyAnalysisCharts> {
  bool isIncomeSelected = false;
  int piChartTouchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor_2,
      body: _body(),
    );
  }

  Widget _body() {
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    final List<Transaction> listOfTransactions =
        List.from(userFinanceData.listOfUserTransactions ?? []);
    final List<Transaction> monthlyTransactions = listOfTransactions
        .where((transaction) =>
            transaction.date?.month == widget.monthInt &&
            transaction.date?.year == DateTime.now().year)
        .toList();
    monthlyTransactions.sort((a, b) {
      double amountA = double.tryParse(a.amount ?? "0.0") ?? 0.0;
      double amountB = double.tryParse(b.amount ?? "0.0") ?? 0.0;
      return amountB.compareTo(amountA);
    });

    Map<String, double> categoryTotals = {};
    for (var transaction in monthlyTransactions) {
      if ((transaction.transactionType ==
              ((isIncomeSelected)
                  ? TransactionType.expense.displayName
                  : TransactionType.income.displayName)) ||
          (transaction.transactionType ==
              TransactionType.transfer.displayName)) {
        continue; // Skip income transactions
      }
      String category = transaction.category ?? "Others";
      double amount = double.parse(transaction.amount ?? "0.0");

      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = categoryTotals[category]! + amount;
      } else {
        categoryTotals[category] = amount;
      }
    }

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _totalIncomeExpense(userFinanceData, monthlyTransactions),
            _pieChart(categoryTotals),
          ],
        ),
      ),
    );
  }

  Widget _totalIncomeExpense(
      UserFinanceData userFinanceData, List<Transaction> monthlyTransactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in monthlyTransactions) {
      if (transaction.transactionType == TransactionType.income.displayName) {
        totalIncome += double.parse(transaction.amount ?? "0.0");
      } else if (transaction.transactionType ==
          TransactionType.expense.displayName) {
        totalExpense += double.parse(transaction.amount ?? "0.0");
      }
    }

    return Row(
      spacing: 10,
      children: [
        Expanded(
            child: InkWell(
          onTap: () {
            setState(() {
              isIncomeSelected = true;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: (isIncomeSelected) ? color3 : color2.withAlpha(150),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              spacing: 5,
              children: [
                Text("Total Income"),
                Text("$totalIncome"),
              ],
            ),
          ),
        )),
        Expanded(
            child: InkWell(
          onTap: () {
            setState(() {
              isIncomeSelected = false;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: (!isIncomeSelected) ? color3 : color2.withAlpha(150),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              spacing: 5,
              children: [
                Text("Total Expense"),
                Text("$totalExpense"),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _pieChart(Map<String, double> categoryTotals) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: color4,
        border: Border.all(color: color2.withAlpha(100)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        spacing: 20,
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        piChartTouchedIndex = -1;
                        return;
                      }
                      piChartTouchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                ),
                sectionsSpace: 5,
                centerSpaceRadius: 50,
                sections: piChartShowingSections(categoryTotals),
              ),
            ),
          ),
          _categoryAndAmount(categoryTotals),
        ],
      ),
    );
  }

  List<PieChartSectionData> piChartShowingSections(
      Map<String, double> categoryTotals) {
    List<PieChartSectionData> pieChartSections = [];

    categoryTotals.forEach((category, total) {
      final isTouched = pieChartSections.length == piChartTouchedIndex;
      final radius = isTouched ? 60.0 : 50.0;

      pieChartSections.add(
        PieChartSectionData(
          color: Colors.primaries[pieChartSections.length %
              Colors
                  .primaries.length], // Use different colors for each category
          value: total,
          title: total.toStringAsFixed(1),
          radius: radius,
          titleStyle: TextStyle(
            fontSize: 14,
            color: whiteColor,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    });

    return pieChartSections;
  }

  Widget _categoryAndAmount(Map<String, double> categoryTotals) {
    return Column(
      spacing: 10,
      children: categoryTotals.entries.map((entry) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 20,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.primaries[
                    categoryTotals.keys.toList().indexOf(entry.key) %
                        Colors.primaries.length],
              ),
            ),
            Text(
              entry.key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "${entry.value.toStringAsFixed(2)} ₹",
              style: TextStyle(fontSize: 15, color: color2),
            ),
          ],
        );
      }).toList(),
    );
  }
}
