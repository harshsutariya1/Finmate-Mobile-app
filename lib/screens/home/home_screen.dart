import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/accounts_screen.dart';
import 'package:finmate/screens/auth/edit_user_details.dart';
import 'package:finmate/screens/auth/notifications_screen.dart';
import 'package:finmate/screens/auth/settings_screen.dart';
import 'package:finmate/screens/home/Transaction%20screens/all_transactions_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isExtendedAppbar = false;
  bool visible = false;
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
      backgroundColor: color4,
      floatingActionButton: floatingUserImage(userData),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: _body(userData, userFinanceData, transactionsList),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _body(UserData userData, UserFinanceData userFinanceData,
      List<Transaction> transactionsList) {
    return Stack(
      children: [
        Column(
          children: [
            appbar(userData),
            Column(
              spacing: 15,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                sbh10,
                transactionContainer(userFinanceData, transactionsList),
                sbh15,
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget appbar(UserData userData) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      margin: EdgeInsets.only(top: statusBarHeight + 10),
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color4,
      ),
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

  Widget floatingUserImage(UserData userData) {
    final Size size = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 10),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: (isExtendedAppbar) ? size.height * .55 : 60,
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
            ],
          ),
        ),
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
          (userFinanceData.listOfUserTransactions == null ||
                  userFinanceData.listOfUserTransactions!.isEmpty)
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
