import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/account%20screens/accounts_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class GroupSettings extends ConsumerStatefulWidget {
  const GroupSettings({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends ConsumerState<GroupSettings> {
  BankAccount? selectedBankAccount;

  @override
  void initState() {
    super.initState();
    final UserFinanceData userFinanceData =
        ref.read(userFinanceDataNotifierProvider);
    selectedBankAccount = userFinanceData.listOfBankAccounts?.firstWhere(
      (element) => element.bid == widget.group.linkedBankAccountId,
      orElse: () => BankAccount(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: _appBar(),
      body: _body(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: color4,
      title: Text("Group Settings"),
      centerTitle: true,
    );
  }

  Widget _body() {
    final UserData userData = ref.watch(userDataNotifierProvider);
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    final Group group = userFinanceData.listOfGroups!
        .firstWhere((element) => element.gid == widget.group.gid);
    final listOfBankAccountsIds = userFinanceData.listOfBankAccounts
        ?.map((element) => element.bid)
        .toList();
    BankAccount? linkedBankAccount;
    if (group.linkedBankAccountId != null &&
        group.linkedBankAccountId!.isNotEmpty &&
        listOfBankAccountsIds!.contains(group.linkedBankAccountId)) {
      linkedBankAccount = userFinanceData.listOfBankAccounts!.firstWhere(
        (element) => element.bid == group.linkedBankAccountId,
      );
    }

    return Padding(
      padding: EdgeInsets.all(15),
      child: SingleChildScrollView(
        child: Column(
          children: [
            (userData.uid == group.creatorId)
                ? borderedContainer([
                    settingsTile(
                      iconData: Icons.link,
                      text: "Linked Account",
                    ),
                    Divider(),
                    (group.linkedBankAccountId == null ||
                            group.linkedBankAccountId!.isEmpty)
                        ? settingsTile(
                            iconData: Icons.add_circle_outline_rounded,
                            text: "Add Account",
                            onTap: () {
                              _showPaymentModeSelectionBottomSheet(
                                  userData, ref);
                            },
                          )
                        : settingsTile(
                            iconData: Icons.check_circle_outline_rounded,
                            text: "Account Linked",
                            isSufixIcon: true,
                            sufixIcon: Icons.edit,
                            onSufixTap: () {
                              _showPaymentModeSelectionBottomSheet(
                                  userData, ref);
                            },
                          ),
                    (group.linkedBankAccountId == null ||
                            group.linkedBankAccountId != null &&
                                group.linkedBankAccountId!.isEmpty)
                        ? SizedBox.shrink()
                        : accountTile(
                            icon: Icons.account_balance_outlined,
                            title: linkedBankAccount?.bankAccountName ??
                                'Unknown Account',
                            subtitle:
                                "Balance: ${linkedBankAccount?.totalBalance ?? "0"} ₹",
                            trailingWidget: SizedBox.shrink(),
                          ),
                  ])
                : SizedBox.shrink(),
            (userData.uid == group.creatorId)
                ? borderedContainer([
                    settingsTile(
                      iconData: Icons.delete_forever_outlined,
                      text: "Delete Group",
                      isLogoutTile: true,
                      onTap: () {
                        showYesNoDialog(
                          context,
                          title: "Delete Group?",
                          contentWidget: SizedBox(),
                          onTapYes: () async {
                            await ref
                                .read(userFinanceDataNotifierProvider.notifier)
                                .deleteGroupProfile(group: widget.group)
                                .then((value) {
                              if (value) {
                                snackbarToast(
                                  context: context,
                                  text: "Group deleted successfully!",
                                  icon: Icons.check_circle_outline_rounded,
                                );
                                Navigate().goBack();
                                Navigate().goBack();
                                Navigate().goBack();
                              } else {
                                snackbarToast(
                                  context: context,
                                  text: "Failed to delete group!",
                                  icon: Icons.error_outline_rounded,
                                );
                              }
                            });
                          },
                          onTapNo: () {
                            Navigate().goBack();
                          },
                        );
                      },
                    )
                  ])
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  void _showPaymentModeSelectionBottomSheet(UserData userData, WidgetRef ref) {
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Bank Account",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color3,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close,
                        color: color3,
                      ),
                    ),
                  ],
                ),
                sbh10,
                // Bank Accounts
                ...userFinanceData.listOfBankAccounts!.map((bankAccount) {
                  bool isSelected = selectedBankAccount?.bid == bankAccount.bid;

                  return InkWell(
                    onTap: () async {
                      if (selectedBankAccount == null) {
                        setState(() {
                          selectedBankAccount = bankAccount;
                        });
                        onTapBankAccount(bankAccount, userData);
                      } else {
                        final isUnlinked =
                            await unLinkSelectedBankAccount(userData, ref);
                        setState(() {
                          selectedBankAccount =
                              (isUnlinked) ? bankAccount : null;
                        });
                        onTapBankAccount(bankAccount, userData);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(
                                bottom: BorderSide(
                                  color: color3,
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight: const Radius.circular(10),
                            bottomLeft: isSelected
                                ? const Radius.circular(0)
                                : const Radius.circular(10),
                            bottomRight: isSelected
                                ? const Radius.circular(0)
                                : const Radius.circular(10),
                          ),
                          border: Border.all(
                            color: color2.withAlpha(150),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              children: [
                                Text(
                                  "Account: ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color3 : color1,
                                  ),
                                ),
                                Text(
                                  bankAccount.bankAccountName ?? "Bank Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color3 : color1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Total Balance: ${bankAccount.totalBalance}",
                              style: TextStyle(
                                fontSize: 16,
                                color: color1,
                              ),
                            ),
                            Text(
                              "Available Balance: ${bankAccount.availableBalance}",
                              style: TextStyle(
                                fontSize: 16,
                                color: color1,
                              ),
                            ),
                            Text(
                              "Linked Group Balances:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color1,
                              ),
                            ),
                            if (bankAccount.groupsBalance == null ||
                                bankAccount.groupsBalance!.isEmpty)
                              Text(
                                "No groups linked",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              )
                            else
                              ...bankAccount.groupsBalance!.entries.map(
                                (entry) {
                                  final key = entry.key;
                                  final value = entry.value;
                                  return Row(
                                    spacing: 10,
                                    children: [
                                      Text(
                                        "◗ ${userFinanceData.listOfGroups?.firstWhere((group) => group.gid == key).name}:",
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
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> unLinkSelectedBankAccount(
      UserData userData, WidgetRef ref) async {
    return await ref
        .read(userFinanceDataNotifierProvider.notifier)
        .unlinkBankAccountFromGroup(
          uid: userData.uid ?? "",
          groupId: widget.group.gid ?? '',
          bankAccountId: selectedBankAccount!.bid ?? '',
          groupBalance: (widget.group.totalAmount ?? 0).toString(),
        )
        .then((success) {
      Logger().i("Bank account unlinked: $success");
      return success;
    });
  }

  Future<void> onTapBankAccount(
      BankAccount bankAccount, UserData userData) async {
    if (selectedBankAccount != null) {
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .linkBankAccountToGroup(
            uid: userData.uid ?? "",
            groupId: widget.group.gid ?? '',
            bankAccountId: selectedBankAccount!.bid ?? '',
            groupBalance: (widget.group.totalAmount ?? 0).toString(),
          )
          .then((success) {
        if (success) {
          snackbarToast(
            context: context,
            text: "Account linked successfully!",
            icon: Icons.check_circle_outline_rounded,
          );
          Navigator.pop(context);
        } else {
          snackbarToast(
            context: context,
            text: "Failed to link account!",
            icon: Icons.error_outline_rounded,
          );
        }
      });
    } else {
      snackbarToast(
        context: context,
        text: "Please select an account first!",
        icon: Icons.warning_amber_rounded,
      );
    }
  }
}
