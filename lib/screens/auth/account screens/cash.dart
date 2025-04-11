import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/account%20screens/accounts_screen.dart';
import 'package:finmate/screens/home/Transaction%20screens/all_transactions_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CashScreen extends ConsumerStatefulWidget {
  const CashScreen({super.key});

  @override
  ConsumerState createState() => _CashScreenState();
}

class _CashScreenState extends ConsumerState<CashScreen> {
  final TextEditingController cashAmountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider); // User data
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider); // User finance data

    return Scaffold(
      backgroundColor: whiteColor_2,
      body: _body(ref, userData, userFinanceData),
    );
  }

  Widget _body(
    WidgetRef ref,
    UserData userData,
    UserFinanceData userFinanceData,
  ) {
    return Container(
      padding: EdgeInsets.all(0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: whiteColor,
                border: Border(
                  top: BorderSide(color: color2.withAlpha(100)),
                  left: BorderSide(color: color2.withAlpha(100)),
                  right: BorderSide(color: color2.withAlpha(100)),
                  bottom: BorderSide(color: color3, width: 5),
                ),
              ),
              child: accountTile(
                icon: Icons.account_balance_wallet_outlined,
                title: "Cash",
                subtitle: "Balance: ${userFinanceData.cash?.amount ?? 0.0} ₹",
                trailingWidget: IconButton(
                  onPressed: () {
                    showEditAmountBottomSheet(context, ref, userData,
                        isCash: true,
                        amount: userFinanceData.cash?.amount ?? "0.0");
                  },
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: color3,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Add Cash Transactions section
            _cashTransactions(userData, userFinanceData),
          ],
        ),
      ),
    );
  }

  Widget _cashTransactions(UserData userData, UserFinanceData userFinanceData) {
    // Filter cash transactions
    List<Transaction> transactionsList = [];

    if (userFinanceData.listOfUserTransactions != null) {
      transactionsList = userFinanceData.listOfUserTransactions!
          .where((transaction) =>
              transaction.methodOfPayment == "Cash" ||
              transaction.methodOfPayment2 == "Cash")
          .toList();

      // Sort transactions by date and time (newest first)
      transactionsList.sort((a, b) {
        int dateComparison = b.date!.compareTo(a.date!);
        if (dateComparison != 0) {
          return dateComparison;
        } else {
          return b.time!.format(context).compareTo(a.time!.format(context));
        }
      });
    }

    return Container(
      margin: EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 20),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and View All button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(left: 10),
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: color3.withAlpha(100),
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  "Cash Transactions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color1,
                  ),
                ),
              ),
              TextButton.icon(
                iconAlignment: IconAlignment.end,
                onPressed: () {
                  Navigate().push(
                    AllTransactionsScreen(
                      transactionsList: transactionsList,
                    ),
                  );
                },
                label: Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 16,
                    color: color3,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color3,
                  size: 20,
                ),
              ),
            ],
          ),

          // Transactions list
          if (transactionsList.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Text(
                "No cash transactions found ❗",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            ...transactionsList.map((transaction) {
              return transactionTile(context, transaction, ref);
            }).take(4), // Show only the first 4 transactions
        ],
      ),
    );
  }
}
