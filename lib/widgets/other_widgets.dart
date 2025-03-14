import 'package:cached_network_image/cached_network_image.dart';
import 'package:finmate/constants/assets.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget userProfilePicInCircle({
  String imageUrl = "",
  double outerRadius = 25,
  double innerRadius = 20,
  bool isNumber = false,
  String textNumber = "1",
}) {
  return CircleAvatar(
    radius: outerRadius,
    backgroundColor: color2,
    child: CircleAvatar(
      radius: innerRadius,
      backgroundColor: color4,
      child: (isNumber)
          ? Text(textNumber)
          : CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: innerRadius,
                backgroundImage: imageProvider,
              ),
              errorWidget: (context, url, error) => CircleAvatar(
                radius: innerRadius,
                backgroundImage: AssetImage(blankProfileImage),
              ),
              placeholder: (context, url) => Padding(
                padding: const EdgeInsets.all(3),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
    ),
  );
}

Widget transactionTile(
  BuildContext context,
  Transaction transaction,
  WidgetRef ref,
) {
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
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(130, 255, 255, 255),
              Colors.red,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: color2.withAlpha(150),
          ),
          color: Colors.white,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 7,
                    children: [
                      // description
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.4,
                        ),
                        child: Text(
                          "${transaction.description}",
                          style: TextStyle(
                            color: color1,
                            fontSize: 16,
                          ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // date
                      Text(
                        "${transaction.date?.day}/${transaction.date?.month}/${transaction.date?.year} ${transaction.time?.format(context)}",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            // amount
            Column(
              spacing: 10,
              children: [
                Text(
                  (double.parse(transaction.amount.toString()) < 0)
                      ? transaction.amount.toString()
                      : "+${transaction.amount.toString()}",
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
