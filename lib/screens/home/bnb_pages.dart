import 'package:finmate/models/user_finance_data_provider.dart';
import 'package:finmate/models/user_provider.dart';
import 'package:finmate/screens/home/analytics_screen.dart';
import 'package:finmate/screens/home/groups_screen.dart';
import 'package:finmate/screens/home/home_screen.dart';
import 'package:finmate/screens/home/investments_screen.dart';
import 'package:finmate/screens/home/scaning_screen.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

class BnbPages extends ConsumerStatefulWidget {
  const BnbPages({super.key});

  @override
  ConsumerState<BnbPages> createState() => _BnbPagesState();
}

class _BnbPagesState extends ConsumerState<BnbPages> {
  late AuthService _authService;
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
  void initState() {
    _authService = GetIt.instance.get<AuthService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataNotifierProvider);
    final userFinanceData = ref.watch(userFinanceDataNotifierProvider);
    final List<Widget> screens = [
      HomeScreen(
        userData: userData,
        userFinanceData: userFinanceData,
        authService: _authService,
      ),
      AnalyticsScreen(),
      ScaningScreen(),
      InvestmentsScreen(),
      GroupsScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        iconSize: 30,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: List.generate(
          screens.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(
              listOfIcons[index],
              color: Colors.black,
            ),
            activeIcon: Icon(
              listOfIcons[index],
              color: Colors.blue,
            ),
            label: listOfTitles[index],
          ),
        ),
      ),
    );
  }
}
