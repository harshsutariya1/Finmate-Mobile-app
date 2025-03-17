import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  ConsumerState<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    List<Transaction>? transactionsList =
        List.from(userFinanceData.listOfUserTransactions ?? []);

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
      appBar: AppBar(
        backgroundColor: color4,
        title: const Text('All Transactions'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: (userFinanceData.listOfUserTransactions == null ||
                userFinanceData.listOfUserTransactions!.isEmpty)
            ? Center(
                child: Text("No Transactions found!"),
              )
            : SingleChildScrollView(
                child: Column(
                  children: transactionsList
                      .map((transaction) =>
                          transactionTile(context, transaction, ref))
                      .toList(),
                ),
              ),
      ),
    );
  }
}
