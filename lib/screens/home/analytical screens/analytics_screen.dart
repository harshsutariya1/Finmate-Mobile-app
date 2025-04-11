import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/radial_chartdata_model.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Initialize to current month (0-indexed)
  late int _selectedIndex;
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
    // Get the current month (1-12) and convert to 0-indexed (0-11)
    _selectedIndex = DateTime.now().month - 1;
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

// __________________________________________________________________________ //

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
        continue; // Skip income & transfer transactions
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
      // margin: const EdgeInsets.all(10),
      // padding: const EdgeInsets.all(10),
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _totalIncomeExpense(userFinanceData, monthlyTransactions),
            (categoryTotals.isEmpty)
                ? noTransactionsFoundText()
                : Column(
                    children: [
                      (categoryTotals.length < 5)
                          ? const SizedBox.shrink()
                          : _radialBarChart(categoryTotals),
                      _pieChart(categoryTotals),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

// __________________________________________________________________________ //

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

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
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
                  Text(
                    "Total Income",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color1,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "$totalIncome ₹",
                    style: TextStyle(
                      color: color1,
                      fontSize: 16,
                    ),
                  ),
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
                  Text(
                    "Total Expense",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color1,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "$totalExpense",
                    style: TextStyle(
                      color: color1,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

// __________________________________________________________________________ //

  Widget _pieChart(Map<String, double> categoryTotals) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: color4,
          border: Border.all(color: color2.withAlpha(100)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          spacing: 15,
          children: [
            AspectRatio(
              aspectRatio: 1.4,
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
                        piChartTouchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 1,
                  centerSpaceRadius: 50,
                  sections: piChartShowingSections(categoryTotals),
                ),
              ),
            ),
            _categoryAndAmount(categoryTotals),
          ],
        ));
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
          titlePositionPercentageOffset: 1.4,
          titleStyle: TextStyle(
            fontSize: 14,
            color: color1,
            overflow: TextOverflow.ellipsis,
          ),
          showTitle: false,
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
            sbw20,
            Text(
              entry.key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Divider(
                  indent: 20,
                  endIndent: 20,
                ),
              ),
            ),
            Text(
              "${double.parse(entry.value.toStringAsFixed(2)).abs()} ₹",
              style: TextStyle(fontSize: 16, color: color1),
            ),
          ],
        );
      }).toList(),
    );
  }

// __________________________________________________________________________ //

  Widget _radialBarChart(Map<String, double> categoryTotals) {
    // Initialize tooltip behavior
    final TooltipBehavior tooltipBehavior = TooltipBehavior(
      enable: true,
      format: 'Category: point.x\nAmount: ₹point.y',
      header: '',
    );

    // Prepare chart data
    List<CategoryChartData> chartData = _prepareRadialChartData(categoryTotals);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: color4,
        border: Border.all(color: color2.withAlpha(100)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildRadialBarChart(chartData, tooltipBehavior),
          sbh10,
          _buildDetailedLegend(chartData),
        ],
      ),
    );
  }

  // Data preparation method
  List<CategoryChartData> _prepareRadialChartData(
      Map<String, double> categoryTotals) {
    // Sort categories by amount (descending)
    List<MapEntry<String, double>> sortedEntries = categoryTotals.entries
        .toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    // Take only top 5
    List<MapEntry<String, double>> topFiveEntries =
        sortedEntries.take(5).toList();

    // Find max amount for percentage calculation
    double maxAmount = topFiveEntries.isNotEmpty
        ? topFiveEntries.map((data) => data.value.abs()).reduce((a, b) => a + b)
        : 0;

    // Generate colors
    List<Color> categoryColors = [
      const Color.fromRGBO(248, 177, 149, 1.0),
      const Color.fromRGBO(246, 114, 128, 1.0),
      const Color.fromRGBO(61, 205, 171, 1.0),
      const Color.fromRGBO(1, 174, 190, 1.0),
      const Color.fromRGBO(116, 90, 242, 1.0),
    ];

    // Create formatted chart data
    return topFiveEntries.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value.key;
      double amount = entry.value.value.abs();

      double percentage = (amount / maxAmount) * 100;

      return CategoryChartData(
        category: category,
        amount: amount,
        color: index < categoryColors.length
            ? categoryColors[index]
            : Colors.primaries[index % Colors.primaries.length],
        percentText: '${percentage.toStringAsFixed(1)}%',
      );
    }).toList();
  }

  // Chart building method
  Widget _buildRadialBarChart(
      List<CategoryChartData> chartData, TooltipBehavior tooltipBehavior) {
    // Calculate maximum value
    double maxValue = chartData.isNotEmpty
        ? chartData.map((data) => data.amount).reduce((a, b) => a + b)
        : 1.0;

    return SizedBox(
      height: 300,
      child: SfCircularChart(
        title: ChartTitle(
          text: "Top 5 ${isIncomeSelected ? 'Income' : 'Expense'} Categories",
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
        tooltipBehavior: tooltipBehavior,
        series: <RadialBarSeries<CategoryChartData, String>>[
          RadialBarSeries<CategoryChartData, String>(
            dataSource: chartData,
            xValueMapper: (CategoryChartData data, _) => data.category,
            yValueMapper: (CategoryChartData data, _) => data.amount,
            pointColorMapper: (CategoryChartData data, _) => data.color,
            dataLabelMapper: (CategoryChartData data, _) => data.percentText,
            enableTooltip: true,
            maximumValue: maxValue,
            radius: '100%',
            gap: '10%',
            cornerStyle: CornerStyle.bothCurve,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: whiteColor,
              ),
              useSeriesColor: true,
            ),
            innerRadius: "30%",
            trackColor: Colors.grey.shade300,
            legendIconType: LegendIconType.circle,
            sortingOrder: SortingOrder.descending,
            sortFieldValueMapper: (CategoryChartData data, _) => data.amount,
          ),
        ],
      ),
    );
  }

  // Legend with exact amounts
  Widget _buildDetailedLegend(List<CategoryChartData> chartData) {
    return Column(
      children: chartData.map((data) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                data.category,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Divider(
                    indent: 20,
                    endIndent: 20,
                  ),
                ),
              ),
              Text(
                '${data.amount.toStringAsFixed(0)} ₹',
                style: TextStyle(fontSize: 16, color: color1),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

// __________________________________________________________________________ //
  Widget noTransactionsFoundText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Text(
        "No Transactions Found for this month ❗",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
