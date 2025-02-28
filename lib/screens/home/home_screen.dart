import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/notifications_screen.dart';
import 'package:finmate/screens/auth/settings_screen.dart';
import 'package:finmate/screens/home/all_transactions_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    List<Transaction>? transactionsList =
        List.from(userFinanceData.listOfTransactions ?? []);

    // Sort transactions by date and time in descending order
    transactionsList.sort((a, b) {
      int dateComparison = b.date!.compareTo(a.date!);
      if (dateComparison != 0) {
        return dateComparison;
      } else {
        return b.time!.format(context).compareTo(a.time!.format(context));
      }
    });

    return Scaffold(
      backgroundColor: color4,
      appBar: appbar(userData),
      body: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          transactionContainer(userFinanceData, transactionsList),
          sbh15,
        ],
      ),
    );
  }

  PreferredSizeWidget appbar(UserData userData) {
    return PreferredSize(
      preferredSize: Size.fromHeight(80.0), // Set the desired height here

      child: AppBar(
        backgroundColor: color4,
        leading: Padding(
          padding: const EdgeInsets.only(
            top: 6,
            bottom: 6,
            left: 10,
            right: 0,
          ),
          child: userProfilePicInCircle(
            imageUrl: userData.pfpURL.toString(),
            innerRadius: 20,
            outerRadius: 25,
          ),
        ),
        title: Text(
          (userData.name == "") ? "Home" : userData.name ?? "Home",
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
              Navigate().push(SettingsScreen());
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  Widget transactionContainer(
    UserFinanceData userFinanceData,
    List<Transaction> transactionsList,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: color2.withAlpha(100),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Recent Transactions",
                  style: TextStyle(
                    color: color1,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton(
                  onPressed: () {
                    Navigate().push(AllTransactionsScreen());
                  },
                  child: Text(
                    "View All",
                    style: TextStyle(
                      color: color2,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          (userFinanceData.listOfTransactions == null ||
                  userFinanceData.listOfTransactions!.isEmpty)
              ? Center(
                  child: Text("No Transactions found!"),
                )
              : Column(
                  children: transactionsList
                      .take(4)
                      .map((transaction) =>
                          transactionTile(context, transaction, ref))
                      .toList(),
                ),
        ],
      ),
    );
  }
}
