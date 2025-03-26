import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/account%20screens/accounts_screen.dart';
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
      backgroundColor: whiteColor_2,
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
            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: whiteColor,
                border: Border(
                  top: BorderSide(color: color2.withAlpha(100)),
                  left: BorderSide(color: color2.withAlpha(100)),
                  right: BorderSide(color: color2.withAlpha(100)),
                  bottom: BorderSide(color: color3, width: 5),
                ),
              ),
              child: accountTile(
                icon: Icons.account_balance_wallet_outlined,
                title: "Cash",
                subtitle: "Balance: ${userFinanceData.cash?.amount ?? 0.0} ₹",
                trailingWidget: IconButton(
                  onPressed: () {
                    showEditAmountBottomSheet(context, ref, userData,
                        isCash: true,
                        amount: userFinanceData.cash?.amount ?? "0.0");
                  },
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: color3,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
