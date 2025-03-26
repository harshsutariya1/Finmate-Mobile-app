import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';

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
              // Animate to the selected page when tab is tapped
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
        // Update selected index when page changes via swipe
        setState(() {
          _selectedIndex = index;
        });
      },
      itemCount: monthsTabTitles.length,
      itemBuilder: (context, index) {
        return MonthlyAnalysisCharts(month: monthsTabTitles[index]);
      },
    );
  }
}

class MonthlyAnalysisCharts extends StatefulWidget {
  const MonthlyAnalysisCharts({super.key, required this.month});
  final String month;
  @override
  State<MonthlyAnalysisCharts> createState() => _MonthlyAnalysisChartsState();
}

class _MonthlyAnalysisChartsState extends State<MonthlyAnalysisCharts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Center(
        child: Text(
          "Charts for ${widget.month}",
          style: TextStyle(color: color1, fontSize: 20),
        ),
      ),
    );
  }
}
