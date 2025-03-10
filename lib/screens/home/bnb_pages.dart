import 'package:finmate/constants/colors.dart';
import 'package:finmate/screens/home/Group%20screens/groups_screen.dart';
import 'package:finmate/screens/home/add_transaction_screen.dart';
import 'package:finmate/screens/home/analytics_screen.dart';
import 'package:finmate/screens/home/home_screen.dart';
import 'package:finmate/screens/home/investments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BnbPages extends ConsumerStatefulWidget {
  const BnbPages({
    super.key,
  });

  @override
  ConsumerState<BnbPages> createState() => _BnbPagesState();
}

class _BnbPagesState extends ConsumerState<BnbPages> {
  var currentIndex = 0;

  List<IconData> listOfIcons = [
    Icons.home,
    Icons.analytics,
    Icons.add,
    Icons.attach_money_rounded,
    Icons.group,
  ];

  List<String> listOfTitles = [
    'Home',
    'Analytics',
    'Add',
    'Investments',
    'Groups',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // 1
      HomeScreen(),
      // 2
      AnalyticsScreen(),
      // 3
      AddTransactionScreen(),
      // 4
      InvestmentsScreen(),
      // 5
      GroupsScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: color4,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        iconSize: 30,
        onTap: (index) {
          setState(() {
            print(index.toString());
            currentIndex = index;
          });
        },
        items: List.generate(
          screens.length,
          (index) => (index == 2)
              ? BottomNavigationBarItem(icon: SizedBox.shrink(), label: '')
              : BottomNavigationBarItem(
                  icon: Icon(
                    listOfIcons[index],
                    color: Colors.black,
                  ),
                  activeIcon: Icon(
                    listOfIcons[index],
                    color: color3,
                  ),
                  label: listOfTitles[index],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            currentIndex = 2;
          });
        },
        backgroundColor: color3,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
