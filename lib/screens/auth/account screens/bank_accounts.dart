import 'package:carousel_slider/carousel_slider.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/account%20screens/accounts_screen.dart';
import 'package:finmate/screens/home/Transaction%20screens/all_transactions_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BankAccounts extends ConsumerStatefulWidget {
  const BankAccounts({super.key});

  @override
  ConsumerState createState() => _BankAccountsState();
}

class _BankAccountsState extends ConsumerState<BankAccounts> {
  int crouselIndex = 1;
  BankAccount? selectedBankAccount;

  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider); // User data
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider); // User finance data
    // crouselIndex = 1;
    selectedBankAccount = userFinanceData
        .listOfBankAccounts?[crouselIndex]; // selected bank account
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
    return SingleChildScrollView(
      child: Column(
        children: [
          addNewButton(userData, userFinanceData),
          accountsCrouselSlider(userData, userFinanceData),
          accountDetails(userData, userFinanceData),
          accountTransactions(userData, userFinanceData),
        ],
      ),
    );
  }

// __________________________________________________________________________ //

  Widget addNewButton(UserData userData, UserFinanceData userFinanceData) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      margin: EdgeInsets.only(
        top: 30,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        border: Border(
          bottom: BorderSide(
            color: color2.withAlpha(100),
            width: 2,
          ),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Bank Accounts",
            style: TextStyle(
              fontSize: 18,
              color: color1,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              showAddBankBottomSheet(
                context,
                ref,
                userData,
                userFinanceData,
              );
            },
            label: Text(
              "Add New",
              style: TextStyle(
                fontSize: 16,
                color: color3,
              ),
            ),
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: color3,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget accountsCrouselSlider(
      UserData userData, UserFinanceData userFinanceData) {
    List<BankAccount> bankAccounts = userFinanceData.listOfBankAccounts ?? [];
    return (bankAccounts.isNotEmpty)
        ? Container(
            margin: EdgeInsets.only(top: 20, bottom: 10),
            child: Column(
              spacing: 10,
              children: [
                CarouselSlider(
                  items: bankAccounts.map((bankAccount) {
                    return accountCrouselItem(bankAccount, userFinanceData);
                  }).toList(),
                  options: CarouselOptions(
                    height: 200,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                    initialPage: crouselIndex,
                    scrollDirection: Axis.horizontal,
                    viewportFraction: 0.6,
                    onPageChanged: (index, reason) => setState(() {
                      crouselIndex = index;
                      selectedBankAccount = bankAccounts[index];
                    }),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: bankAccounts.map((bankAccount) {
                    int index = bankAccounts.indexOf(bankAccount);
                    return Container(
                      width: 10.0,
                      height: 10.0,
                      margin:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: crouselIndex == index
                            ? color3
                            : color2.withAlpha(100),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          )
        : Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              color: whiteColor,
              border: Border.all(color: color2.withAlpha(50)),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color2.withAlpha(100),
                  offset: Offset(0, 3),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              "No Bank Accounts Found ❗\n\nAdd New Account",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          );
  }

  Widget accountCrouselItem(
    BankAccount bankAccount,
    UserFinanceData userFinanceData,
  ) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: whiteColor,
        border: Border(
          top: BorderSide(color: color2.withAlpha(100)),
          left: BorderSide(color: color2.withAlpha(100)),
          right: BorderSide(color: color2.withAlpha(100)),
          bottom: BorderSide(color: color3, width: 5),
        ),
      ),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 15,
          children: [
            Text(
              bankAccount.bankAccountName ?? "Bank Account",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Total Balance",
                  style: TextStyle(
                    fontSize: 18,
                    color: color2.withAlpha(200),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${bankAccount.totalBalance ?? "0.0"} ₹",
                  style: TextStyle(
                    fontSize: 16,
                    color: color2.withAlpha(200),
                  ),
                ),
                sbh5,
                Text(
                  "Available Balance",
                  style: TextStyle(
                    fontSize: 18,
                    color: color2.withAlpha(200),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${bankAccount.availableBalance ?? "0.0"} ₹",
                  style: TextStyle(
                    fontSize: 16,
                    color: color2.withAlpha(200),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// __________________________________________________________________________ //

  Widget accountDetails(UserData userData, UserFinanceData userFinanceData) {
    final List<Group>? listOfGroups = userFinanceData.listOfGroups;
    List<BankAccount> bankAccounts = userFinanceData.listOfBankAccounts ?? [];
    return (bankAccounts.isNotEmpty)
        ? Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              color: whiteColor,
              border: Border.all(color: color2.withAlpha(50)),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color2.withAlpha(100),
                  offset: Offset(0, 3),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                // account name
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.start,
                      children: [
                        Text(
                          "Account: ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color1,
                          ),
                        ),
                        Text(
                          selectedBankAccount?.bankAccountName ??
                              "Bank Account",
                          style: TextStyle(
                            fontSize: 18,
                            color: color2,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton(
                        position: PopupMenuPosition.under,
                        itemBuilder: (context) => <PopupMenuItem<String>>[
                          PopupMenuItem(
                            value: "Edit",
                            child: Text("Edit"),
                            onTap: () {
                              snackbarToast(
                                  context: context,
                                  text: "This feature is in development ❗",
                                  icon: Icons.developer_mode_rounded);
                            },
                          ),
                          PopupMenuItem(
                            value: "Delete",
                            child: Text(
                              "Delete",
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => deleteBankAccount(userData),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // upi id
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "UPI Id: ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    if (selectedBankAccount?.upiIds == null ||
                        selectedBankAccount!.upiIds!.isEmpty)
                      Text(
                        "No UPI ID",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (selectedBankAccount?.upiIds != null &&
                        selectedBankAccount!.upiIds!.isNotEmpty)
                      ...selectedBankAccount!.upiIds!.map((upiId) {
                        return Text(
                          "◗ $upiId",
                          style: TextStyle(
                            fontSize: 16,
                            color: color2,
                          ),
                        );
                      }),
                  ],
                ),
                // Linked Groups
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Groups Linked: ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    if (selectedBankAccount?.groupsBalance == null ||
                        selectedBankAccount!.groupsBalance!.isEmpty)
                      Text(
                        "No groups linked",
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      )
                    else
                      ...selectedBankAccount!.groupsBalance!.entries.map(
                        (entry) {
                          final key = entry.key;
                          final value = entry.value;
                          return Row(
                            spacing: 10,
                            children: [
                              Text(
                                "◗ ${listOfGroups?.firstWhere((group) => group.gid == key).name}:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: color1.withAlpha(200),
                                ),
                              ),
                              Text("$value ₹",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: color2,
                                  )),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }

  Widget accountTransactions(
      UserData userData, UserFinanceData userFinanceData) {
    List<BankAccount> bankAccounts = userFinanceData.listOfBankAccounts ?? [];
    // fetching transactions of selected bank account
    List<Transaction> transactionsList = userFinanceData.listOfUserTransactions!
        .where(
          (transaction) => ((transaction.bankAccountId != null ||
                  transaction.bankAccountId2 != null) &&
              (transaction.bankAccountId == selectedBankAccount?.bid ||
                  transaction.bankAccountId2 == selectedBankAccount?.bid)),
        )
        .toList();
    // sorting transactions by date and time
    transactionsList.sort((a, b) {
      int dateComparison = b.date!.compareTo(a.date!);
      if (dateComparison != 0) {
        return dateComparison;
      } else {
        return b.time!.format(context).compareTo(a.time!.format(context));
      }
    });

    return (bankAccounts.isNotEmpty)
        ? Container(
            margin: EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 20),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                // title and view all button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 10),
                      padding:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: color3.withAlpha(100),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        "Transactions",
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

                // transactions list
                if (transactionsList.isEmpty)
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No transactions found ❗",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  ...transactionsList.map((transaction) {
                    return transactionTile(context, transaction, ref);
                  }).take(4),
              ],
            ),
          )
        : SizedBox.shrink();
  }

// __________________________________________________________________________ //

  void showAddBankBottomSheet(
    BuildContext context,
    WidgetRef ref,
    UserData userdata,
    UserFinanceData userFinanceData,
  ) {
    final formKey = GlobalKey<FormState>();
    final Size size = MediaQuery.sizeOf(context);
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();
    final TextEditingController upiIdController = TextEditingController();
    clearTextControllers() {
      nameController.clear();
      balanceController.clear();
      upiIdController.clear();
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (contextt) {
        return Container(
          padding: EdgeInsets.all(20),
          height: size.height * 0.8,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Add Bank Account",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  sbh20,
                  textfield(
                    controller: nameController,
                    lableText: "Bank Account Name",
                    hintText: "enter nick name",
                    prefixIconData: Icons.account_balance_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter Bank Account Name";
                      }
                      if (userFinanceData.listOfBankAccounts != null &&
                          userFinanceData.listOfBankAccounts!.any((account) =>
                              account.bankAccountName == value.trim())) {
                        return "Bank Account with this name already exists❗";
                      }
                      return null;
                    },
                  ),
                  sbh10,
                  textfield(
                    controller: balanceController,
                    lableText: "Amount",
                    hintText: "Amount",
                    prefixIconData: Icons.currency_rupee_sharp,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter Amount";
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter valid Amount";
                      }
                      return null;
                    },
                  ),
                  sbh10,
                  textfield(
                    controller: upiIdController,
                    lableText: "UPI ID",
                    hintText: "Enter UPI ID",
                    prefixIconData: Icons.account_balance_wallet_rounded,
                    sufixWidget: Text(
                      "verify",
                      style: TextStyle(
                        color: color3,
                        fontSize: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter UPI ID";
                      }
                      return null;
                    },
                  ),
                  InkWell(
                    onTap: () async {
                      // Add Bank Accounts and Wallets
                      final String name = nameController.text.trim();
                      final String balance = balanceController.text.trim();
                      final String upiId = upiIdController.text.trim();
                      if (formKey.currentState!.validate()) {
                        // add bank account
                        final BankAccount bankAccount = BankAccount(
                          bankAccountName: name,
                          totalBalance: balance,
                          availableBalance: balance,
                          upiIds: [upiId],
                        );
                        if (await ref
                            .read(userFinanceDataNotifierProvider.notifier)
                            .addBankAccount(userdata.uid!, bankAccount, ref)) {
                          snackbarToast(
                              context: context,
                              text: "Bank Account Added.",
                              icon: Icons.done_all);
                          clearTextControllers();
                          Navigate().goBack();
                        } else {
                          snackbarToast(
                              context: context,
                              text: "Error adding Bank Account ❗",
                              icon: Icons.error_outline_rounded);
                        }
                      }
                    },
                    // save button
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      margin:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: color3),
                        borderRadius: BorderRadius.circular(10),
                        color: color4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 20,
                        children: [
                          Text(
                            "Save",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: color3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void deleteBankAccount(UserData userData) async {
    await showYesNoDialog(
      context,
      title: "Are you sure?",
      contentWidget: Text("Delete account?"),
      onTapYes: () async {
        if (selectedBankAccount?.groupsBalance == null ||
            selectedBankAccount!.groupsBalance!.isEmpty) {
          if (await ref
              .read(userFinanceDataNotifierProvider.notifier)
              .deleteBankAccount(
                  userData.uid!, selectedBankAccount?.bid ?? '', ref)) {
            snackbarToast(
                context: context,
                text: "Bank Account Deleted.",
                icon: Icons.done_all);
            Navigate().goBack();
          } else {
            snackbarToast(
                context: context,
                text: "Error deleting Bank Account ❗",
                icon: Icons.error_outline_rounded);
          }
        } else {
          snackbarToast(
              context: context,
              text: "Please Withdraw all group balances first ❗",
              icon: Icons.error_outline_rounded);
        }
      },
      onTapNo: () {
        Navigate().goBack();
      },
    );
  }
}
