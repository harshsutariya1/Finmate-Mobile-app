import 'package:finmate/Models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/screens/auth/notifications_screen.dart';
import 'package:finmate/screens/auth/settings_screen.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userData,
    required this.userFinanceData,
    required this.authService,
  });
  final UserData userData;
  final UserFinanceData userFinanceData;
  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.userData.name == "")
              ? "Home"
              : widget.userData.name ?? "Home",
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigate().push(NotificationScreen());
            },
            icon: Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigate().push(SettingsScreen(authService: widget.authService));
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Text("FinMate App Home")),
          Divider(),
          ...widget.userFinanceData.listOfTransactions
                  ?.map((transaction) => Text("Transaction Id: ${transaction.tid}"))
                  .toList() ??
              [],
        ],
      ),
    );
  }
}
