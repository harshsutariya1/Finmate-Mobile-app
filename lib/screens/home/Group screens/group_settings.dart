import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/accounts_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupSettings extends ConsumerStatefulWidget {
  const GroupSettings({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends ConsumerState<GroupSettings> {
  final TextEditingController _paymentModeController = TextEditingController();
  BankAccount? selectedBankAccount;
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
      context: context,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                bankAccountContainer(
                  context: context,
                  userFinanceData: userFinanceData,
                  isSelectable: true,
                  selectedBank: selectedBankAccount?.bankAccountName ?? '',
                  onTapBank: (BankAccount bankAccount) {
                    setState(() {
                      _paymentModeController.text =
                          PaymentModes.bankAccount.displayName;
                      selectedBankAccount = bankAccount;
                    });
                    onTapBankAccount(bankAccount, userData);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
