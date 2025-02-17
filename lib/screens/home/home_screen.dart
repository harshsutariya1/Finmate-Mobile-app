import 'package:finmate/Models/user.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/screens/auth/notifications_screen.dart';
import 'package:finmate/screens/auth/settings_screen.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
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
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorWhite,
      appBar: AppBar(
        backgroundColor: backgroundColorWhite,
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
      body: SingleChildScrollView(
        child: Column(
          spacing: 15,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: Text("Transactions")),
            Divider(),
            ...widget.userFinanceData.listOfTransactions
                    ?.map((transaction) => transactionData(transaction))
                    .toList() ??
                [],
            Divider(),
          ],
        ),
      ),
    );
  }

  Widget transactionData(Transaction transaction) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        border: Border.all(color: color2),
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transaction Id: ${transaction.tid}",
            style: TextStyle(
              color: color1,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text("Transaction Amount: ${transaction.amount}"),
          Text(
              "Transaction Date: ${transaction.date?.day}/${transaction.date?.month}/${transaction.date?.year}"),
        ],
      ),
    );
  }
}
