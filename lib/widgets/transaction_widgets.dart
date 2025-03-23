import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget transactionTile(
  BuildContext context,
  Transaction transaction,
  WidgetRef ref,
) {
  final String? accountId1 = (transaction.isTransferTransaction)
      ? transaction.bankAccountId ??
          transaction.walletId ??
          transaction.groupName
      : null;
  final String? accountId2 = (transaction.isTransferTransaction)
      ? transaction.bankAccountId2 ??
          transaction.walletId2 ??
          transaction.groupName2
      : null;

  final String? paymentMode1 = (transaction.isTransferTransaction)
      ? (transaction.methodOfPayment == PaymentModes.bankAccount.displayName ||
              transaction.methodOfPayment == PaymentModes.wallet.displayName ||
              transaction.methodOfPayment == PaymentModes.group.displayName
          ? accountId1
          : 'Cash')
      : null;

  final paymentMode2 = (transaction.isTransferTransaction)
      ? (transaction.methodOfPayment2 == PaymentModes.bankAccount.displayName ||
              transaction.methodOfPayment2 == PaymentModes.wallet.displayName ||
              transaction.methodOfPayment2 == PaymentModes.group.displayName
          ? accountId2
          : 'Cash')
      : null;

  return Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
    child: Dismissible(
      key: ValueKey(transaction),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        bool result = false;
        // delete transaction dialog
        showYesNoDialog(
          context,
          title: "Delete Transaction ?",
          contentWidget: SizedBox(),
          onTapYes: () async {
            if (transaction.uid != null && transaction.tid != null) {
              if (await ref
                  .read(userFinanceDataNotifierProvider.notifier)
                  .deleteTransaction(transaction.uid!, transaction.tid!)) {
                snackbarToast(
                  context: context,
                  text: "Transaction Deleted!",
                  icon: Icons.done,
                );
                result = true;
                Navigate().goBack();
              } else {
                // error occured
                snackbarToast(
                  context: context,
                  text: "Failed deleting transaction!",
                  icon: Icons.delete_forever_rounded,
                );
                Navigate().goBack();
              }
            }
          },
          onTapNo: () {
            Navigate().goBack();
          },
        );
        return Future.value(result);
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: color2.withAlpha(150),
          ),
          color: whiteColor_2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  // category icon
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: color2,
                    child: CircleAvatar(
                      backgroundColor: color4,
                      radius: 28,
                      child: Icon(
                        transactionCategoriesAndIcons[transaction.category],
                        color: color3,
                        size: 30,
                      ),
                    ),
                  ),
                  // description and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 7,
                      children: [
                        (transaction.isTransferTransaction)
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${paymentMode1 ?? transaction.methodOfPayment}",
                                    style: TextStyle(
                                      color: color1,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text("🔁"),
                                  Text(
                                    "${paymentMode2 ?? transaction.methodOfPayment2}",
                                    style: TextStyle(
                                      color: color1,
                                      fontSize: 16,
                                    ),
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              )
                            : Text(
                                "${transaction.description}",
                                style: TextStyle(
                                  color: (transaction.category ==
                                          TransactionCategory
                                              .balanceAdjustment.displayName)
                                      ? color2
                                      : color1,
                                  fontSize: 16,
                                ),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                        // date
                        Text(
                          "${transaction.date?.day}/${transaction.date?.month}/${transaction.date?.year} ${transaction.time?.format(context)}",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // amount
            Column(
              spacing: 10,
              children: [
                Text(
                  (transaction.isTransferTransaction)
                      ? (double.parse(transaction.amount.toString()) < 0)
                          ? "⇄ ${transaction.amount}"
                          : "⇄ ${transaction.amount}"
                      : (double.parse(transaction.amount.toString()) < 0)
                          ? transaction.amount.toString()
                          : "+${transaction.amount}",
                  style: TextStyle(
                    fontSize: 18,
                    color: double.parse(transaction.amount!) < 0
                        ? Colors.red
                        : color3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
}
