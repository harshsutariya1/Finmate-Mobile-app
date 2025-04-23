import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/account%20screens/accounts_screen.dart';
import 'package:finmate/screens/auth/edit_user_details.dart';
import 'package:finmate/screens/auth/settings_screen.dart';
import 'package:finmate/screens/home/Transaction%20screens/all_transactions_screen.dart';
import 'package:finmate/screens/home/budgets%20goals%20screens/budgets_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isExtendedAppbar = false;
  bool visible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800), // Duration of the animation
    );

    // Start the animation when the app opens
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
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
      backgroundColor: color4_120,
      floatingActionButton: floatingUserImage(userData),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: _body(userData, userFinanceData, transactionsList),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _body(UserData userData, UserFinanceData userFinanceData,
      List<Transaction> transactionsList) {
    return Column(
      children: [
        _appbar(userData),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _totalBalance(),
                sbh10,
                _accounts(),
                sbh10,
                expenseIncomeTransferButtons(),
                sbh10,
                _incomeExpenseBalance(),
                sbh10,
                _transactionContainer(userFinanceData, transactionsList),
                sbh15,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _appbar(UserData userData) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        color: color4,
        border: Border(
          bottom: BorderSide(
            color: color2.withAlpha(100),
            width: 1,
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(top: statusBarHeight + 10, bottom: 10),
        height: 60,
        width: double.infinity,
        color: color4,
        child: Row(
          children: [
            SizedBox(
              width: 100,
            ),
            Text(
              (userData.name == "") ? "Home" : userData.name ?? "Home",
              textAlign: TextAlign.center,
              style: TextTheme.of(context).titleLarge,
            ),
            Spacer(),
            // IconButton(
            //   onPressed: () {
            //     Navigate().push(NotificationScreen());
            //   },
            //   icon: Icon(Icons.notifications_none_rounded),
            // ),
            IconButton(
              onPressed: () {
                Navigate().push(SettingsScreen());
              },
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalBalance() {
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    final List<BankAccount> bankAccounts =
        List.from(userFinanceData.listOfBankAccounts ?? []);
    final String cashAmount = "${userFinanceData.cash?.amount ?? 0.0}";
    final double additionOfBankBalanceAndCash = bankAccounts.fold(
          0.0,
          (previousValue, account) =>
              previousValue + (double.parse(account.totalBalance ?? '0')),
        ) +
        double.parse(cashAmount);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: whiteColor_2,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color2.withAlpha(100),
          ),
          boxShadow: [
            BoxShadow(
              color: color2.withAlpha(40),
              offset: Offset(0, 3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total Balance",
              style: TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              "₹ $additionOfBankBalanceAndCash",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accounts() {
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    final List<BankAccount> bankAccounts =
        List.from(userFinanceData.listOfBankAccounts ?? []);
    final String cashAmount = "${userFinanceData.cash?.amount ?? 0.0}";
    // Sort bank accounts by total balance in descending order
    bankAccounts.sort((a, b) {
      double balanceA = double.tryParse(a.totalBalance ?? '0') ?? 0;
      double balanceB = double.tryParse(b.totalBalance ?? '0') ?? 0;
      return balanceB.compareTo(balanceA);
    });

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // accounts button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Accounts button
              InkWell(
                onTap: () {
                  Navigate().push(AccountsScreen());
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 20,
                  ),
                  child: Text(
                    "Accounts  >",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // New add Account button
              InkWell(
                onTap: () {
                  Navigate().push(AccountsScreen());
                },
                child: Container(
                  margin: EdgeInsets.only(right: 20),
                  padding: EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: color2.withAlpha(200),
                  ),
                  child: Text(
                    "+ New",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          sbh10,
          // bank accounts balances
          ...bankAccounts.map((bankAccount) {
            return _accountBalanceTile(
              bankAccounts,
              bankAccount,
              bankAccounts.indexOf(bankAccount),
            );
          }).take(3),
          // cash balance
          _accountBalanceTile(
            bankAccounts,
            BankAccount(
              bankAccountName: "Cash Balance",
              totalBalance: cashAmount,
            ),
            bankAccounts.length,
            isCash: true,
          ),
        ],
      ),
    );
  }

  Widget _accountBalanceTile(
      List<BankAccount> bankAccounts, BankAccount bankAccount, int index,
      {bool isCash = false}) {
    Size size = MediaQuery.sizeOf(context);
    double rightMargin() {
      final margin = (index * (size.width * 0.1)) + 30;
      // print("Right Margin: $margin");
      return margin.clamp(20, 200);
    }

    // Define the animation for sliding from left to right
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: Offset(-1.5, 0), // Start off-screen to the left
      end: Offset(0, 0), // End at the original position
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          (index) * 0.1, // Stagger the animation for each tile
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: slideAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 25,
              ),
              margin: EdgeInsets.only(
                  top: 10, right: (!isCash) ? rightMargin() : 0),
              decoration: BoxDecoration(
                color: (isCash)
                    ? whiteColor_2
                    : (index % 3 == 0)
                        ? color1
                        : (index % 3 == 1)
                            ? color2
                            : color3,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: (isCash)
                    ? Border.all(
                        color: color2.withAlpha(100),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: color2.withAlpha(isCash ? 40 : 60),
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: (isCash) ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: [
                        Text(
                          bankAccount.bankAccountName ??
                              ((isCash) ? "Cash Balance" : "Bank Account"),
                          style: TextStyle(
                            fontSize: 16,
                            color: (isCash) ? color2 : color4,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          "₹ ${bankAccount.totalBalance}",
                          style: TextStyle(
                            fontSize: 20,
                            color: (isCash) ? color1 : whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _incomeExpenseBalance() {
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    double todayExpenses = 0.0;
    int currentDay = DateTime.now().day;
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;

    for (Transaction transaction
        in userFinanceData.listOfUserTransactions ?? []) {
      // Extract the transaction year and month
      int transactionYear = transaction.date?.year ?? currentYear;
      int transactionMonth = transaction.date?.month ?? currentMonth;

      // compare transaction date with current month
      if (transactionYear == currentYear && transactionMonth == currentMonth) {
        if (transaction.transactionType == TransactionType.income.displayName) {
          totalIncome += double.parse(transaction.amount ?? "0.0");
        } else if (transaction.transactionType ==
            TransactionType.expense.displayName) {
          totalExpense += double.parse(transaction.amount ?? "0.0");
        }
      }
    }

    for (Transaction transaction in userFinanceData.listOfUserTransactions
            ?.where((transaction) =>
                (transaction.date?.day == currentDay) &&
                (transaction.date?.month == currentMonth) &&
                (transaction.date?.year == currentYear)) ??
        []) {
      if (transaction.transactionType == TransactionType.expense.displayName) {
        todayExpenses += double.parse(transaction.amount ?? "0.0");
      }
    }

    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 10),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color4,
        border: Border.all(color: color2.withAlpha(100)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          // Income Expense Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Income Column
              Row(
                spacing: 15,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.green,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.green[100],
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        "Income",
                        style: TextStyle(
                          fontSize: 18,
                          color: color2.withAlpha(200),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹ $totalIncome",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Expense Column
              Row(
                spacing: 15,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.red,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.red[100],
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        "Expense",
                        style: TextStyle(
                          fontSize: 18,
                          color: color2.withAlpha(200),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹ $totalExpense",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Today Expenses
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  "Today's Expenses",
                  style: TextStyle(
                    fontSize: 18,
                    color: color2.withAlpha(200),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  "₹ $todayExpenses",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),

          // Income vs Expense bar
          _buildRangeColorAxis(context, totalIncome, totalExpense)
        ],
      ),
    );
  }

  Widget _buildRangeColorAxis(
      BuildContext context, double totalIncome, double totalExpense) {
    final income = totalIncome;
    final expense = totalExpense;
    final totalAmount = income + expense.abs();
    final double incomePercentage = ((totalIncome * 100) / totalAmount) >= 0.0
        ? (totalIncome * 100) / totalAmount
        : 50;
    // Logger().i("Income Percentage: $incomePercentage");
    return SfLinearGauge(
      useRangeColorForAxis: true,
      showLabels: false,
      showTicks: false,
      animateAxis: true,
      orientation: LinearGaugeOrientation.horizontal,
      axisTrackStyle: const LinearAxisTrackStyle(thickness: 1),
      ranges: <LinearGaugeRange>[
        LinearGaugeRange(
          endValue: incomePercentage,
          color: Colors.green,
        ),
        LinearGaugeRange(
          startValue: incomePercentage,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _transactionContainer(
    UserFinanceData userFinanceData,
    List<Transaction> transactionsList,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: color2.withAlpha(100),
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
                    Navigate().push(AllTransactionsScreen(
                      transactionsList: transactionsList,
                    ));
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
          (userFinanceData.listOfUserTransactions == null ||
                  userFinanceData.listOfUserTransactions!.isEmpty)
              ? Center(
                  child: Text(
                    "No Transactions Found yet ❗",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              : Column(
                  children: transactionsList
                      .take(4)
                      .map((transaction) =>
                          transactionTile(context, transaction, ref))
                      .toList(),
                ),
          sbh10,
        ],
      ),
    );
  }

// __________________________________________________________________________ //

  Widget floatingUserImage(UserData userData) {
    final Size size = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 10),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: (isExtendedAppbar) ? size.height * .6 : 60,
        width: (isExtendedAppbar) ? size.width * .7 : 60,
        padding: EdgeInsets.symmetric(
            vertical: (isExtendedAppbar) ? 20 : 0,
            horizontal: (isExtendedAppbar) ? 15 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: (isExtendedAppbar) ? Colors.white : Colors.transparent,
          boxShadow: (isExtendedAppbar)
              ? [
                  BoxShadow(
                    color: color2.withAlpha(120),
                    offset: Offset(5, 5),
                    blurRadius: 10,
                    spreadRadius: 5,
                  )
                ]
              : null,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              // User Image Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onTapClose,
                    child: userProfilePicInCircle(
                      imageUrl: userData.pfpURL.toString(),
                      innerRadius: 27,
                      outerRadius: 30,
                    ),
                  ),
                  futureHomeMenuWidget(
                    child: IconButton(
                      onPressed: onTapClose,
                      icon: Icon(
                        Icons.cancel_outlined,
                        color: color3,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),

              // User Name
              futureHomeMenuWidget(
                child: Text(
                  "Hello, ${userData.name}!",
                  style: TextStyle(
                    color: color3,
                    fontSize: 20,
                  ),
                ),
              ),
              futureHomeMenuWidget(
                child: Text(
                  "“Rule No. 1 : Never lose money. Rule No. 2 : Never forget Rule No. 1.”  ― Warren Buffett",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ),
              futureHomeMenuWidget(child: sbh10),

              // Button Tiles
              futureHomeMenuWidget(
                child: borderedContainer(
                  [
                    settingsTile(
                        iconData: Icons.person_pin_rounded,
                        text: "Profile",
                        onTap: () {
                          setState(() {
                            onTapClose();
                          });
                          Navigate().push(EditUserDetails(
                            userData: userData,
                          ));
                        })
                  ],
                  customMargin: EdgeInsets.all(0),
                ),
              ),
              futureHomeMenuWidget(
                child: borderedContainer(
                  [
                    settingsTile(
                      iconData: Icons.account_balance_rounded,
                      text: "Accounts",
                      onTap: () {
                        setState(() {
                          onTapClose();
                        });
                        Navigate().push(AccountsScreen());
                      },
                    )
                  ],
                  customMargin: EdgeInsets.all(0),
                ),
              ),
              futureHomeMenuWidget(
                child: borderedContainer(
                  [
                    settingsTile(
                      iconData: Icons.track_changes_rounded,
                      text: "Budgets",
                      onTap: () {
                        setState(() {
                          onTapClose();
                        });
                        Navigate().push(BudgetScreen());
                      },
                    )
                  ],
                  customMargin: EdgeInsets.all(0),
                ),
              ),
              futureHomeMenuWidget(
                child: borderedContainer(
                  [
                    settingsTile(
                      iconData: Icons.flag_circle_rounded,
                      text: "Goals",
                      onTap: () {
                        setState(() {
                          onTapClose();
                        });
                        Navigate().push(BudgetScreen());
                      },
                    )
                  ],
                  customMargin: EdgeInsets.all(0),
                ),
              ),
              futureHomeMenuWidget(
                child: borderedContainer(
                  [
                    settingsTile(
                      iconData: Icons.settings,
                      text: "Settings",
                      onTap: () {
                        setState(() {
                          onTapClose();
                        });
                        Navigate().push(SettingsScreen());
                      },
                    )
                  ],
                  customMargin: EdgeInsets.all(0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget futureHomeMenuWidget({required Widget child}) {
    if (isExtendedAppbar) {
      return (visible)
          ? AnimatedOpacity(
              opacity: (visible) ? 1 : 0,
              duration: Duration(seconds: 5),
              child: child,
            )
          : SizedBox.shrink();
    } else {
      return SizedBox.shrink();
    }
  }

  void onTapClose() async {
    setState(() {
      isExtendedAppbar = !isExtendedAppbar;
    });
    (isExtendedAppbar)
        ? await Future.delayed(Duration(milliseconds: 200)).then((value) {
            setState(() {
              visible = true;
            });
          })
        : visible = false;
  }
}

// _____________________________________________________________________________ //

class HomeMenuBar extends ConsumerStatefulWidget {
  const HomeMenuBar(
      {super.key, required this.isExtendedAppbar, required this.onTapClose});
  final bool isExtendedAppbar;
  final void Function() onTapClose;
  @override
  ConsumerState<HomeMenuBar> createState() => _HomeMenuBarState();
}

class _HomeMenuBarState extends ConsumerState<HomeMenuBar> {
  bool visible = false;
  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            // User Image Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    widget.onTapClose();
                    onTapClose();
                  },
                  child: userProfilePicInCircle(
                    imageUrl: userData.pfpURL.toString(),
                    innerRadius: 27,
                    outerRadius: 30,
                  ),
                ),
                futureHomeMenuWidget(
                  child: IconButton(
                    onPressed: () {
                      widget.onTapClose();
                      onTapClose();
                    },
                    icon: Icon(
                      Icons.cancel_outlined,
                      color: color3,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),

            // User Name
            futureHomeMenuWidget(
              child: Text(
                "Hello, ${userData.name}!",
                style: TextStyle(
                  color: color3,
                  fontSize: 20,
                ),
              ),
            ),
            futureHomeMenuWidget(child: sbh10),

            // Button Tiles
            futureHomeMenuWidget(
              child: borderedContainer(
                [
                  settingsTile(
                    iconData: Icons.person_pin_rounded,
                    text: "Profile",
                    onTap: () => Navigate().push(EditUserDetails(
                      userData: userData,
                    )),
                  )
                ],
                customMargin: EdgeInsets.all(0),
              ),
            ),
            futureHomeMenuWidget(
              child: borderedContainer(
                [
                  settingsTile(
                    iconData: Icons.account_balance_rounded,
                    text: "Accounts",
                    onTap: () => Navigate().push(AccountsScreen()),
                  )
                ],
                customMargin: EdgeInsets.all(0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onTapClose() async {
    await Future.delayed(Duration(milliseconds: 200)).then((value) {
      setState(() {
        visible = true;
      });
    });
  }

  Widget futureHomeMenuWidget({required Widget child}) {
    if (widget.isExtendedAppbar) {
      return (visible)
          ? AnimatedOpacity(
              opacity: (visible) ? 1 : 0,
              duration: Duration(seconds: 5),
              child: child,
            )
          : SizedBox.shrink();
    } else {
      return SizedBox.shrink();
    }
  }
}
