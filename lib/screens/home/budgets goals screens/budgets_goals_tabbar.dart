import 'package:finmate/constants/colors.dart';
import 'package:finmate/screens/home/budgets%20goals%20screens/budget_screen.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetsGoalsTabbar extends ConsumerStatefulWidget {
  const BudgetsGoalsTabbar({super.key});

  @override
  ConsumerState<BudgetsGoalsTabbar> createState() => _BudgetsGoalsTabbarState();
}

class _BudgetsGoalsTabbarState extends ConsumerState<BudgetsGoalsTabbar> {
  int _selectedIndex = 0;
  late PageController _pageController;
  List<String> tabTitles = ["Budgets", "Goals"];

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
      appBar: AppBar(
        backgroundColor: color4,
        centerTitle: true,
        title: const Text("Budgets & Goals"),
        actions: [
          Icon(
            Icons.track_changes_rounded,
            color: color3,
            size: 30,
          ),
          SizedBox(width: 20),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: CustomTabBar(
            selectedIndex: _selectedIndex,
            tabTitles: tabTitles,
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
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      children: [
        BudgetScreen(), // Existing budget screen
        _goalsScreen(), // Placeholder for future goals implementation
      ],
    );
  }

  Widget _goalsScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 80,
            color: color3.withAlpha(127),
          ),
          const SizedBox(height: 20),
          Text(
            "Financial Goals Coming Soon!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Set and track your financial goals with our upcoming feature.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
