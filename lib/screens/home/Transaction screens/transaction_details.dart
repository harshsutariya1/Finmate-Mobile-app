import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/transaction_category.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionDetails extends ConsumerStatefulWidget {
  const TransactionDetails({super.key, required this.transaction});
  final Transaction transaction;
  @override
  ConsumerState<TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends ConsumerState<TransactionDetails> {
  late Transaction transaction;
  @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: _appBar(),
      body: _body(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: whiteColor,
      leading: IconButton(
        onPressed: () => Navigate().goBack(),
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: color1),
      ),
      actions: [
        // edit button
        IconButton(
          onPressed: () {
            // _editTransaction();
          },
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color3,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.all(5.0),
            child: Icon(
              Icons.edit_outlined,
              color: color3,
            ),
          ),
        ),
        // share button
        IconButton(
          onPressed: () {},
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color1,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.all(5.0),
            child: Icon(
              Icons.share_outlined,
              color: color1,
            ),
          ),
        ),
        // delete button
        IconButton(
          onPressed: () {
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
                    Navigate().goBack();
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
          },
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.all(5.0),
            child: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: (transaction.transactionType ==
                          TransactionType.income.displayName)
                      ? color3
                      : (transaction.transactionType ==
                              TransactionType.transfer.displayName)
                          ? color2
                          : Colors.red,
                  width: 5,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              margin: const EdgeInsets.only(top: 50),
              decoration: BoxDecoration(
                color: color4.withAlpha(100),
                border: Border.all(color: color2.withAlpha(100)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              alignment: Alignment.center,
              child: _transactionDetails(),
            ),
          ),
          Positioned(
            top: 0,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: (transaction.transactionType ==
                      TransactionType.income.displayName)
                  ? color3
                  : (transaction.transactionType ==
                          TransactionType.transfer.displayName)
                      ? color2
                      : Colors.red,
              child: CircleAvatar(
                radius: 46,
                backgroundColor: whiteColor,
                child: Icon(
                  CategoryHelpers.getIconForCategory(
                      transaction.category ?? "Others"),
                  size: 50,
                  color: color2.withAlpha(200),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionDetails() {
    final String fromAccountName =
        (transaction.methodOfPayment == PaymentModes.bankAccount.displayName)
            ? (transaction.bankAccountId != null &&
                    transaction.bankAccountId!.isNotEmpty)
                ? transaction.bankAccountName!
                : "Unknown"
            : (transaction.methodOfPayment == PaymentModes.group.displayName)
                ? (transaction.gid != null && transaction.gid!.isNotEmpty)
                    ? transaction.groupName!
                    : "Unknown"
                : "Unknown";

    final String toAccountName =
        (transaction.methodOfPayment2 == PaymentModes.bankAccount.displayName)
            ? (transaction.bankAccountId2 != null &&
                    transaction.bankAccountId2!.isNotEmpty)
                ? transaction.bankAccountName2!
                : "Unknown"
            : (transaction.methodOfPayment2 == PaymentModes.group.displayName)
                ? (transaction.gid2 != null && transaction.gid2!.isNotEmpty)
                    ? transaction.groupName2!
                    : "Unknown"
                : "Unknown";

    return Column(
      children: [
        Text(
          (transaction.payee != null && transaction.payee!.isNotEmpty)
              ? transaction.payee!
              : (transaction.category != null &&
                      transaction.category!.isNotEmpty)
                  ? transaction.category!
                  : "Unknown",
          style: const TextStyle(
            color: color2,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        sbh10,
        // date & time
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // date
            Text(
              (transaction.date != null)
                  ? "Date: ${transaction.date!.day}/${transaction.date!.month}/${transaction.date!.year}"
                  : "Date: Unknown",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            // time
            Text(
              (transaction.time != null)
                  ? "Time: ${transaction.time!.hour}:${transaction.time!.minute}"
                  : "Time: Unknown",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        sbh10,
        Divider(color: color3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sbh10,
            // to payee
            Row(
              spacing: 10,
              children: [
                Text(
                  "To:",
                  style: TextStyle(
                    color: color2,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Text(
                    (transaction.payee != null && transaction.payee!.isNotEmpty)
                        ? transaction.payee!
                        : "Unknown",
                    style: TextStyle(
                      color: color2,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // description
            sbh10,
            Row(
              spacing: 10,
              children: [
                Text(
                  "Description:",
                  style: TextStyle(
                    color: color2,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Text(
                    (transaction.description != null &&
                            transaction.description!.isNotEmpty)
                        ? transaction.description!
                        : "Unknown",
                    style: TextStyle(
                      color: color2,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            sbh10,
            // category
            Row(
              spacing: 10,
              children: [
                Text(
                  "Category:",
                  style: TextStyle(
                    color: color2,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Text(
                    (transaction.category != null &&
                            transaction.category!.isNotEmpty)
                        ? transaction.category!
                        : "Unknown",
                    style: TextStyle(
                      color: color2,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        sbh10,
        Divider(color: color3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sbh10,
            // Payment Mode
            Row(
              spacing: 10,
              children: [
                Text(
                  "Payment Mode:",
                  style: TextStyle(
                    color: color2,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Text(
                    (transaction.methodOfPayment != null &&
                            transaction.methodOfPayment!.isNotEmpty)
                        ? transaction.methodOfPayment!
                        : "Unknown",
                    style: TextStyle(
                      color: color2,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            sbh10,
            // From Account
            Row(
              spacing: 10,
              children: [
                Text(
                  "From:",
                  style: TextStyle(
                    color: color2,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Text(
                    fromAccountName,
                    style: TextStyle(
                      color: color2,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            sbh10,
            // To Account
            (transaction.transactionType ==
                    TransactionType.transfer.displayName)
                ? Row(
                    spacing: 10,
                    children: [
                      Text(
                        "To:",
                        style: TextStyle(
                          color: color2,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          toAccountName,
                          style: TextStyle(
                            color: color2,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            (transaction.transactionType ==
                    TransactionType.transfer.displayName)
                ? sbh10
                : SizedBox.shrink(),
            // amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Amount:",
                  style: TextStyle(
                    color: color2,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Text(
                    "${transaction.amount ?? 0.0} ₹",
                    style: TextStyle(
                      color: (transaction.transactionType ==
                              TransactionType.income.displayName)
                          ? color3
                          : (transaction.transactionType ==
                                  TransactionType.transfer.displayName)
                              ? color2
                              : Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

// __________________________________________________________________________ //

  // Future<void> _editTransaction() async {
  //   try {
  //    final Transaction? updatedTransaction = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => EditTransactionScreen(transaction: transaction),
  //     ),
  //   );
  //   if (updatedTransaction != null) {
  //     setState(() {
  //       transaction = updatedTransaction;
  //     });
  //   }
  //   } catch (e) {
  //     Logger().e("Error editing transaction: ${e.toString()}");
  //   }
  // }
}
