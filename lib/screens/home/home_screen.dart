import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/notifications_screen.dart';
import 'package:finmate/screens/auth/settings_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
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
      body: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Text("Transactions")),
          Divider(),
          (userFinanceData.listOfTransactions!.isEmpty)
              ? Center(
                  child: Text("No Transactions found!"),
                )
              : Expanded(
                  child: ListView.separated(
                    itemCount: userFinanceData.listOfTransactions!.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return sbh15;
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return transactionTile(
                          userFinanceData.listOfTransactions![index]);
                    },
                  ),
                ),
          Divider(),
          Text("Now Add new transaction screen"),
        ],
      ),
    );
  }

  Widget transactionTile(Transaction transaction) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      margin: EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        border: Border.all(
          color: color2.withAlpha(150),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                // category icon
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color2,
                  child: CircleAvatar(
                    backgroundColor: color4,
                    radius: 28,
                    child: Icon(
                      transactionCategoriesAndIcons[transaction.category],
                      color: color3,
                    ),
                  ),
                ),
                // description and date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 7,
                  children: [
                    // description
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.4,
                      ),
                      child: Text(
                        "${transaction.description}",
                        style: TextStyle(
                          color: color1,
                          fontSize: 16,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // date
                    Text(
                      "${transaction.date?.day}/${transaction.date?.month}/${transaction.date?.year}",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // amount
          Column(
            spacing: 10,
            children: [
              Text(
                transaction.amount.toString(),
                style: TextStyle(
                  fontSize: 18,
                  color: double.parse(transaction.amount!) < 0
                      ? Colors.red
                      : color3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
