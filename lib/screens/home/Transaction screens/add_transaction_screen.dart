import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Transaction%20screens/expense_income_fields.dart';
import 'package:finmate/screens/home/Transaction%20screens/transfer_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key, this.initialIndex = 0,
  });
  final int initialIndex;
  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: color4,
        appBar: _appbar(),
        body: _body(userFinanceData, userData),
      ),
    );
  }

  PreferredSizeWidget _appbar() {
    return AppBar(
      backgroundColor: color4,
      centerTitle: true,
      title: const Text('Add New Transaction'),
      bottom: TabBar(
        tabs: [
          Tab(
            text: "Expense / Income",
          ),
          Tab(
            text: "Transfer",
          ),
        ],
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: color3,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          color: Colors.blueGrey,
        ),
        indicatorColor: color3,
      ),
    );
  }

  Widget _body(UserFinanceData userFinanceData, UserData userData) {
    return TabBarView(
      children: <Widget>[
        ExpenseIncomeFields(),
        TransferFields(),
      ],
    );
  }
}
