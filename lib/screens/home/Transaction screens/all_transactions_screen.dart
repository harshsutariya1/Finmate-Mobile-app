import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key, required this.transactionsList});
  final List<Transaction> transactionsList;

  @override
  ConsumerState<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  // Initialize to current month (0-indexed)
  late int _selectedIndex;
  late PageController _pageController;

  List<String> monthsTabTitles = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    // Get the current month (1-12) and convert to 0-indexed (0-11)
    _selectedIndex = DateTime.now().month - 1;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: _buildAppBar(),
      body: _buildTransactionPageView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: color4,
      title: const Text('Transactions'),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: color1,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomTabBar(
          selectedIndex: _selectedIndex,
          tabTitles: monthsTabTitles,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildTransactionPageView() {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      itemCount: monthsTabTitles.length,
      itemBuilder: (context, index) {
        return _buildMonthlyTransactionList(index + 1); // Month is 1-indexed
      },
    );
  }

// __________________________________________________________________________ //

  Widget _buildMonthlyTransactionList(int month) {
    // Filter transactions for the selected month
    List<Transaction> monthlyTransactions = _filterTransactionsByMonth(month);

    // Sort transactions by date and time in descending order
    monthlyTransactions.sort((a, b) {
      int dateComparison = b.date!.compareTo(a.date!);
      if (dateComparison != 0) {
        return dateComparison;
      } else {
        return b.time!.format(context).compareTo(a.time!.format(context));
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: monthlyTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: color2.withAlpha(150),
                  ),
                  sbh15,
                  Text(
                    "No transactions in ${monthsTabTitles[month - 1]}",
                    style: TextStyle(
                      color: color2,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSummary(monthlyTransactions),
                  sbh15,
                  ...monthlyTransactions.map((transaction) =>
                      transactionTile(context, transaction, ref)),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSummary(List<Transaction> transactions) {
    // Calculate month summary
    double income = 0;
    double expense = 0;

    for (var transaction in transactions) {
      if (transaction.transactionType == TransactionType.income.displayName) {
        income += double.parse(transaction.amount ?? "0.0");
      } else if (transaction.transactionType ==
          TransactionType.expense.displayName) {
        expense += double.parse(transaction.amount ?? "0.0");
      }
    }

    double balance = income - expense;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color1.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem("Income", income, Colors.green),
              _buildSummaryItem("Expense", expense, Colors.red),
            ],
          ),
          sbh10,
          Divider(color: color2.withAlpha(100)),
          sbh10,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSummaryItem(
                "Balance",
                balance,
                balance >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: color2,
          ),
        ),
        Text(
          "₹ ${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Transaction> _filterTransactionsByMonth(int month) {
    List<Transaction> filteredTransactions = [];

    // Get current year
    int currentYear = DateTime.now().year;

    for (var transaction in widget.transactionsList) {
      if (transaction.date != null &&
          transaction.date!.month == month &&
          transaction.date!.year == currentYear) {
        filteredTransactions.add(transaction);
      }
    }

    return filteredTransactions;
  }
}
