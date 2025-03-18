import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});
  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final TextEditingController cashAmountController = TextEditingController();
  final TextEditingController bankAccountNameController =
      TextEditingController();
  final TextEditingController bankAccountBalanceController =
      TextEditingController();
  final TextEditingController walletNameController = TextEditingController();
  final TextEditingController walletBalanceController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    Logger().i(
        "Bank Accounts: ${userFinanceData.listOfBankAccounts?.length}");

    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        centerTitle: true,
        title: const Text("Accounts"),
        actions: [
          Icon(
            Icons.account_balance_rounded,
            color: color3,
          ),
          sbw20,
        ],
      ),
      body: _body(ref, userData, userFinanceData),
    );
  }

  Widget _body(
    WidgetRef ref,
    UserData userData,
    UserFinanceData userFinanceData,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            bankAccountContainer(
              context: context,
              ref: ref,
              userdata: userData,
              userFinanceData: userFinanceData,
              bankAccountNameController: bankAccountNameController,
              bankAccountBalanceController: bankAccountBalanceController,
              clearControllers: () {
                setState(() {
                  bankAccountNameController.clear();
                  bankAccountBalanceController.clear();
                });
              },
            ),
            cashContainer(
              context: context,
              ref: ref,
              userData: userData,
              cashAmountController: cashAmountController,
              userFinanceData: userFinanceData,
            ),
          ],
        ),
      ),
    );
  }
}

// ________________________________________________________________________ //

Widget bankAccountContainer({
  required BuildContext context,
  required UserFinanceData userFinanceData,
  WidgetRef? ref,
  UserData? userdata,
  TextEditingController? bankAccountNameController,
  TextEditingController? bankAccountBalanceController,
  bool isSelectable = false,
  String selectedBank = "",
  void Function(BankAccount)? onTapBank,
  void Function()? clearControllers,
}) {
  return borderedContainer([
    Padding(
      padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Bank Accounts",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          InkWell(
            onTap: () {
              if (isSelectable) {
                Navigate().goBack();
                Navigate().push(AccountsScreen());
              } else {
                showAddBankAndWalletBottomSheet(
                  context,
                  ref!,
                  userdata!,
                  userFinanceData,
                  bankAccountNameController!,
                  bankAccountBalanceController!,
                  isAddingBank: true,
                  () => clearControllers,
                );
              }
            },
            child: Icon(
              Icons.add_circle_outline_rounded,
              color: color3,
              size: 30,
            ),
          ),
        ],
      ),
    ),
    Divider(),
    (userFinanceData.listOfBankAccounts == null ||
            userFinanceData.listOfBankAccounts!.isEmpty)
        ? Center(
            child: Text("No Bank Accounts found!"),
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: userFinanceData.listOfBankAccounts!.length,
            separatorBuilder: (BuildContext context, int index) {
              return sbh15;
            },
            itemBuilder: (BuildContext context, int index) {
              final BankAccount bankAccount =
                  userFinanceData.listOfBankAccounts![index];
              return accountTile(
                icon: Icons.account_balance_rounded,
                title: bankAccount.bankAccountName ?? "Bank Account",
                subtitle:
                    "Total Balance: ${bankAccount.totalBalance ?? "0.0"} ₹",
                trailingWidget: IconButton(
                  onPressed: (isSelectable)
                      ? () {
                          onTapBank!(bankAccount);
                        }
                      : () {
                          showEditAmountBottomSheet(
                            context,
                            ref!,
                            userdata!,
                            amount: bankAccount.totalBalance ?? "0.0",
                            isBank: true,
                            bankAccount: bankAccount,
                          );
                        },
                  icon: (isSelectable)
                      ? Icon(
                          (selectedBank == bankAccount.bankAccountName)
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: (selectedBank == bankAccount.bankAccountName)
                              ? color3
                              : color2,
                          size: 28,
                        )
                      : Icon(
                          Icons.more_vert_rounded,
                          color: color3,
                          size: 28,
                        ),
                ),
              );
            },
          ),
    sbh10,
  ]);
}

Widget cashContainer({
  BuildContext? context,
  WidgetRef? ref,
  UserData? userData,
  TextEditingController? cashAmountController,
  UserFinanceData? userFinanceData,
  bool isSelectable = false,
  bool isSelected = false,
  void Function()? onTap,
}) {
  return borderedContainer([
    accountTile(
      icon: Icons.account_balance_wallet_outlined,
      title: "Cash",
      subtitle: "Balance: ${userFinanceData?.cash?.amount ?? 0} ₹",
      trailingWidget: IconButton(
        onPressed: (isSelectable)
            ? onTap
            : () {
                showEditAmountBottomSheet(context!, ref!, userData!,
                    isCash: true,
                    amount: userFinanceData?.cash?.amount ?? "0.0");
              },
        icon: (isSelectable)
            ? Icon(
                (isSelected)
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: (isSelected) ? color3 : color2,
                size: 28,
              )
            : Icon(
                Icons.more_vert_rounded,
                color: color3,
                size: 28,
              ),
      ),
    ),
  ]);
}

// ________________________________________________________________________ //

void showEditAmountBottomSheet(
  BuildContext context,
  WidgetRef ref,
  UserData userdata, {
  bool isCash = false,
  bool isBank = false,
  bool isWallet = false,
  String amount = "0.0",
  BankAccount? bankAccount,
}) {
  UserFinanceData userFinanceData = ref.watch(userFinanceDataNotifierProvider);
  final TextEditingController amountController =
      TextEditingController(text: amount);
  showModalBottomSheet(
    context: context,
    builder: (contextt) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Edit ${(isCash) ? "Cash" : (isBank) ? "Bank" : (isWallet) ? "Wallet" : ""} Balance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh20,
            _textfield(
              controller: amountController,
              lableText: "Amount",
              prefixIconData: Icons.currency_rupee_sharp,
            ),
            InkWell(
              onTap: () async {
                // update cash amount
                if (amountController.text.isEmpty) {
                  snackbarToast(
                      context: contextt,
                      text: "Enter Amount❗",
                      icon: Icons.error_outline);
                } else if (double.parse(amountController.text).isNegative) {
                  snackbarToast(
                      context: contextt,
                      text: "Amount can not be Negative❗",
                      icon: Icons.error_outline);
                } else {
                  if (isCash) {
                    await ref
                        .read(userFinanceDataNotifierProvider.notifier)
                        .updateUserCashAmount(
                          uid: userdata.uid ?? '',
                          amount: amountController.text,
                          isCashBalanceAdjustment: true,
                        );
                  }
                  if (isBank) {
                    await ref
                        .read(userFinanceDataNotifierProvider.notifier)
                        .updateBankAccountBalance(
                          uid: userdata.uid ?? "",
                          bankAccountId: bankAccount?.bid ?? '',
                          availableBalance: amountController.text,
                          totalBalance: userFinanceData.listOfBankAccounts!
                              .firstWhere(
                                  (account) => account.bid == bankAccount?.bid)
                              .totalBalance
                              .toString(),
                          bankAccount: bankAccount,
                          isBalanceAdjustment: true,
                        );
                  }
                  Navigate().goBack();
                }
              },
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: color3),
                  borderRadius: BorderRadius.circular(15),
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
      );
    },
  );
}

void showAddBankAndWalletBottomSheet(
    BuildContext context,
    WidgetRef ref,
    UserData userdata,
    UserFinanceData userFinanceData,
    TextEditingController nameController,
    TextEditingController balanceController,
    void Function() clearControllers,
    {bool isAddingBank = false}) {
  showModalBottomSheet(
    context: context,
    builder: (contextt) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Add ${(isAddingBank) ? "Bank Account" : "Wallet"}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh20,
            _textfield(
              controller: nameController,
              lableText: "${(isAddingBank) ? "Bank Account" : "Wallet"} Name",
              hintText: (isAddingBank) ? "enter nick name" : "enter nick name",
              prefixIconData: (isAddingBank)
                  ? Icons.account_balance_rounded
                  : Icons.wallet_rounded,
            ),
            sbh10,
            _textfield(
              controller: balanceController,
              lableText: "Amount",
              hintText: "Amount",
              prefixIconData: Icons.currency_rupee_sharp,
            ),
            InkWell(
              onTap: () async {
                // Add Bank Accounts and Wallets
                final String name = nameController.text;
                final String balance = balanceController.text;
                bool validation = false;
                if (name.isEmpty || balance.isEmpty) {
                  snackbarToast(
                      context: context,
                      text: "Enter all fields ❗",
                      icon: Icons.warning_amber_rounded);
                } else if (double.parse(balance).isNegative) {
                  snackbarToast(
                      context: contextt,
                      text: "Amount can not be Negative❗",
                      icon: Icons.error_outline);
                } else {
                  // bank name checking...
                  if (userFinanceData.listOfBankAccounts != null &&
                      userFinanceData.listOfBankAccounts!
                          .any((account) => account.bankAccountName == name)) {
                    snackbarToast(
                        context: contextt,
                        text: "Bank Account with this name already exists❗",
                        icon: Icons.error_outline);
                  } else {
                    validation = true;
                  }
                  if (validation) {
                    // add bank account
                    final BankAccount bankAccount = BankAccount(
                      bid: name,
                      bankAccountName: name,
                      totalBalance: balance,
                      availableBalance: balance,
                    );
                    if (await ref
                        .read(userFinanceDataNotifierProvider.notifier)
                        .addBankAccount(userdata.uid!, bankAccount, ref)) {
                      snackbarToast(
                          context: context,
                          text: "Bank Account Added.",
                          icon: Icons.done_all);
                    } else {
                      snackbarToast(
                          context: context,
                          text: "Error adding Bank Account ❗",
                          icon: Icons.error_outline_rounded);
                    }
                    clearControllers();
                    Navigate().goBack();
                  }
                }
                clearControllers();
              },
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: color3),
                  borderRadius: BorderRadius.circular(15),
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
      );
    },
  );
}

Widget _textfield({
  required TextEditingController controller,
  String? hintText,
  String? lableText,
  IconData? prefixIconData,
  IconData? sufixIconData,
  bool readOnly = false,
  void Function()? onTap,
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    onTap: (onTap != null) ? onTap : null,
    keyboardType:
        (lableText == "Amount") ? TextInputType.numberWithOptions() : null,
    decoration: InputDecoration(
      labelText: (lableText != null) ? lableText : null,
      hintText: (hintText != null) ? hintText : null,
      labelStyle: TextStyle(
        color: color1,
      ),
      prefixIcon: (prefixIconData != null)
          ? Icon(
              prefixIconData,
              color: color3,
            )
          : null,
      suffixIcon: (sufixIconData != null)
          ? Icon(
              sufixIconData,
              color: color3,
              size: 30,
            )
          : null,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: color1),
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: color3,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
    ),
  );
}

Widget accountTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget trailingWidget,
}) {
  return ListTile(
    leading: Icon(
      icon,
      color: color3,
      size: 28,
    ),
    title: Text(
      title,
      style: TextStyle(
        color: color2,
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(
        color: color2,
      ),
    ),
    trailing: trailingWidget,
  );
}
