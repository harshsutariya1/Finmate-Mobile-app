import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/screens/auth/account%20screens/bank_accounts.dart';
import 'package:finmate/screens/auth/account%20screens/cash.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});
  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  // List<String> tabTitles = ["Bank Accounts", "Cards", "Cash"];
  List<String> tabTitles = ["Bank Accounts", "Cash"];

  @override
  void initState() {
    super.initState();
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: CustomTabBar(
            selectedIndex: _selectedIndex,
            tabTitles: tabTitles,
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
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(), // Or ClampingScrollPhysics()
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      children: [
        BankAccounts(),
        // CardsScreen(),
        CashScreen(),
      ],
    );
  }
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
            textfield(
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

Widget textfield(
    {required TextEditingController controller,
    String? hintText,
    String? lableText,
    IconData? prefixIconData,
    IconData? sufixIconData,
    bool readOnly = false,
    void Function()? onTap,
    Widget? sufixWidget,
    void Function()? onTapSufixWidget,
    String? Function(String?)? validator,
    void Function(String)? onChanged}) {
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
      suffixIcon: (sufixIconData == null)
          ? (sufixWidget != null)
              ? InkWell(
                  onTap: onTapSufixWidget,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(right: 15, top: 10, bottom: 10),
                    child: sufixWidget,
                  ),
                )
              : null
          : Icon(
              sufixIconData,
              color: color3,
              size: 30,
            ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: color1),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: color3,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    validator: validator,
    onChanged: onChanged,
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

// ________________________________________________________________________ //
