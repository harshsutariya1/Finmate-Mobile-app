import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor_2,
      body: _body(),
    );
  }

  Widget _body() {
    final UserData userData = ref.watch(userDataNotifierProvider);
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    final List<Transaction> listOfTransactions =
        List.from(userFinanceData.listOfUserTransactions ?? []);
    final List<Transaction> filteredTransactions = listOfTransactions
        .where((transaction) =>
            transaction.date?.month == widget.monthInt &&
            transaction.date?.year == DateTime.now().year)
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text("This Month Transactions: ${filteredTransactions.length}")
        ],
      ),
    );
  }
}
