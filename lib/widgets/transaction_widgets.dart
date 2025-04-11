import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/transaction_category.dart';
import 'package:finmate/screens/home/Transaction%20screens/add_transaction_screen.dart';
import 'package:finmate/screens/home/Transaction%20screens/transaction_details.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget transactionTile(
  BuildContext context,
  Transaction transaction,
  WidgetRef ref,
) {
  final String? accountId1 = (transaction.isTransferTransaction)
      ? transaction.bankAccountName ?? transaction.groupName
      : null;
  final String? accountId2 = (transaction.isTransferTransaction)
      ? transaction.bankAccountName2 ?? transaction.groupName2
      : null;

  final String? paymentMode1 = (transaction.isTransferTransaction)
      ? (transaction.methodOfPayment == PaymentModes.bankAccount.displayName ||
              transaction.methodOfPayment == PaymentModes.group.displayName
          ? accountId1
          : 'Cash')
      : null;

  final paymentMode2 = (transaction.isTransferTransaction)
      ? (transaction.methodOfPayment2 == PaymentModes.bankAccount.displayName ||
              transaction.methodOfPayment2 == PaymentModes.group.displayName
          ? accountId2
          : 'Cash')
      : null;

  return Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
    child: InkWell(
      onTap: () =>
          Navigate().push(TransactionDetails(transaction: transaction)),
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
                                          SystemCategory
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

Widget expenseIncomeTransferButtons() {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 10),
    margin: EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: color4,
      border: Border.all(color: color3.withAlpha(100)),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: color2.withAlpha(50),
          blurRadius: 1,
          spreadRadius: 2,
          offset: Offset(0, 1.5),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () {
            Navigate().push(AddTransactionScreen(
              initialIndex: 0,
              isIncome: true,
            ));
          },
          child: Column(
            spacing: 5,
            children: [
              Icon(
                Icons.arrow_circle_up_rounded,
                color: color2,
                size: 40,
              ),
              Text(
                "Income",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Navigate().push(AddTransactionScreen(
              initialIndex: 0,
              isIncome: false,
            ));
          },
          child: Column(
            spacing: 5,
            children: [
              Icon(
                Icons.arrow_circle_down_rounded,
                color: color2,
                size: 40,
              ),
              Text(
                "Expense",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Navigate().push(AddTransactionScreen(
              initialIndex: 1,
              isIncome: false,
            ));
          },
          child: Column(
            spacing: 5,
            children: [
              Icon(
                Icons.swap_horizontal_circle_outlined,
                color: color2,
                size: 40,
              ),
              Text(
                "Transfer",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
