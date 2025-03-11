import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final TextEditingController cashAmountController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        UserData userData = ref.watch(userDataNotifierProvider);
        UserFinanceData userFinanceData =
            ref.watch(userFinanceDataNotifierProvider);
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
      },
    );
  }

  Widget _body(
    WidgetRef ref,
    UserData userData,
    UserFinanceData userFinanceData,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          bankAccountContainer(
            context: context,
            userFinanceData: userFinanceData,
          ),
          walletsContainer(
            context: context,
            userFinanceData: userFinanceData,
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
    );
  }
}

// ________________________________________________________________________ //

Widget bankAccountContainer({
  required BuildContext context,
  required UserFinanceData userFinanceData,
  bool isSelectable = false,
  bool isSelected = false,
  void Function()? onTap,
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
              snackbarToast(
                  context: context,
                  text: "This feature is in development!",
                  icon: Icons.running_with_errors_rounded);
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
    userFinanceData.listOfBankAccounts == null ||
            userFinanceData.listOfBankAccounts!.isEmpty
        ? Center(
            child: Text("No Bank Accounts found!"),
          )
        : ListView.separated(
            shrinkWrap: true,
            itemCount: userFinanceData.listOfBankAccounts!.length,
            separatorBuilder: (BuildContext context, int index) {
              return sbh15;
            },
            itemBuilder: (BuildContext context, int index) {
              final bankAccount = userFinanceData.listOfBankAccounts![index];
              return accountTile(
                icon: Icons.account_balance_wallet_rounded,
                title: bankAccount.name ?? "Bank Account",
                subtitle: "Balance: ${bankAccount.amount ?? 0}",
                trailingWidget: IconButton(
                  onPressed: (isSelectable)
                      ? onTap
                      : () {
                          // showBottomSheet(
                          //   context!,
                          //   ref!,
                          //   userData!,
                          //   cashAmountController!,
                          // );
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
              );
            },
          ),
    sbh10,
  ]);
}

Widget walletsContainer({
  required BuildContext context,
  required UserFinanceData userFinanceData,
  bool isSelectable = false,
  bool isSelected = false,
  void Function()? onTap,
}) {
  return borderedContainer([
    Padding(
      padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Wallets",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          InkWell(
            onTap: () {
              snackbarToast(
                  context: context,
                  text: "This feature is in development!",
                  icon: Icons.running_with_errors_rounded);
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
    userFinanceData.listOfBankAccounts == null ||
            userFinanceData.listOfBankAccounts!.isEmpty
        ? Center(
            child: Text("No wallets found!"),
          )
        : ListView.separated(
            shrinkWrap: true,
            itemCount: userFinanceData.listOfBankAccounts!.length,
            separatorBuilder: (BuildContext context, int index) {
              return sbh15;
            },
            itemBuilder: (BuildContext context, int index) {
              final bankAccount = userFinanceData.listOfBankAccounts![index];
              return accountTile(
                icon: Icons.account_balance_wallet_rounded,
                title: bankAccount.name ?? "Bank Account",
                subtitle: "Balance: ${bankAccount.amount ?? 0}",
                trailingWidget: IconButton(
                  onPressed: (isSelectable)
                      ? onTap
                      : () {
                          // showBottomSheet(
                          //   context!,
                          //   ref!,
                          //   userData!,
                          //   cashAmountController!,
                          // );
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
      subtitle: "Balance: ${userFinanceData?.cash?.amount ?? 0}",
      trailingWidget: IconButton(
        onPressed: (isSelectable)
            ? onTap
            : () {
                showBottomSheet(
                  context!,
                  ref!,
                  userData!,
                  cashAmountController!,
                );
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

void showBottomSheet(
  BuildContext context,
  WidgetRef ref,
  UserData userdata,
  TextEditingController cashAmountController,
) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Edit Cash amount",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh20,
            _textfield(
              controller: cashAmountController,
              lableText: "Amount",
              prefixIconData: Icons.currency_rupee_sharp,
            ),
            InkWell(
              onTap: () async {
                // update cash amount
                await ref
                    .read(userFinanceDataNotifierProvider.notifier)
                    .updateUserCashAmount(
                      uid: userdata.uid ?? '',
                      amount: cashAmountController.text,
                    );
                Navigate().goBack();
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

// Widget borderedContainer(List<Widget> listOfWidgets) {
//   return Container(
//     margin: EdgeInsets.symmetric(
//       vertical: 10,
//       horizontal: 10,
//     ),
//     decoration: BoxDecoration(
//       border: Border.all(
//         color: const Color.fromARGB(50, 57, 62, 70),
//         width: 2,
//       ),
//       borderRadius: BorderRadius.circular(15),
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ...listOfWidgets.map((widget) => widget),
//       ],
//     ),
//   );
// }
