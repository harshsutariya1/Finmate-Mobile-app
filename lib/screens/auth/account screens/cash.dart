import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/account%20screens/accounts_screen.dart';
import 'package:finmate/widgets/settings_widgets.dart';
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
}
