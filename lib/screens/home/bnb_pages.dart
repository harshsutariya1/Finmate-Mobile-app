import 'package:finmate/constants/colors.dart';
import 'package:finmate/screens/home/Group%20screens/groups_screen.dart';
import 'package:finmate/screens/home/add_transaction_screen.dart';
import 'package:finmate/screens/home/analytics_screen.dart';
import 'package:finmate/screens/home/home_screen.dart';
import 'package:finmate/screens/home/investments_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
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

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // 1
      HomeScreen(),
      // 2
      AnalyticsScreen(),
      // 3
      SizedBox(),
      // 4
      InvestmentsScreen(),
      // 5
      GroupsScreen(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: color4,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        iconSize: 30,
        onTap: (index) {
          setState(() {
            print(index.toString());
            currentIndex = (index != 2) ? index : 3;
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
      floatingActionButton: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: (isExpanded) ? 130 : 60,
        width: (isExpanded) ? 200 : 60,
        margin: EdgeInsets.only(
          bottom: (isExpanded) ? 50 : 0,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () {
                  Navigate().push(AddTransactionScreen());
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 46, 193, 201),
                    shape: BoxShape.circle,
                    boxShadow: (!isExpanded)
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 3,
                              spreadRadius: 1,
                              offset: Offset(0, 1),
                            )
                          ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: InkWell(
                onTap: () {
                  snackbarToast(
                      context: context,
                      text: "This function is in development.",
                      icon: Icons.developer_mode_rounded);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 46, 193, 201),
                    shape: BoxShape.circle,
                    boxShadow: (!isExpanded)
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 3,
                              spreadRadius: 1,
                              offset: Offset(0, 1),
                            )
                          ],
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color3,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 3,
                        spreadRadius: 1,
                        offset: Offset(0, 1),
                      )
                    ],
                  ),
                  child: AnimatedRotation(
                    duration: Duration(milliseconds: 300),
                    turns: (isExpanded) ? 0.125 : 0,
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
