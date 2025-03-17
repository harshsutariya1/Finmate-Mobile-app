import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/accounts_screen.dart';
import 'package:finmate/screens/home/Transaction%20screens/expense_income_fields.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class TransferFields extends ConsumerStatefulWidget {
  const TransferFields({super.key});

  @override
  ConsumerState<TransferFields> createState() => _TransferFieldsState();
}

class _TransferFieldsState extends ConsumerState<TransferFields> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController =
      TextEditingController(text: "Transfer");
  final TextEditingController _paymentModeOneController =
      TextEditingController();
  final TextEditingController _paymentModeTwoController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool isPaymentModeOneGroup = false;
  bool isPaymentModeTwoGroup = false;

  Group? selectedGroup1;
  BankAccount? selectedBank1;
  Wallet? selectedWallet1;

  Group? selectedGroup2;
  BankAccount? selectedBank2;
  Wallet? selectedWallet2;

  bool isButtonDisabled = false;
  bool isButtonLoading = false;

  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: color4,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _floatingButton(userData, userFinanceData),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            _dateTimePicker(),
            _amountField(),
            _descriptionField(),
            _paymentModeChoiceChips(true),
            _paymentModeField(userData, userFinanceData, true),
            _paymentModeChoiceChips(false),
            _paymentModeField(userData, userFinanceData, false),
          ],
        ),
      ),
    );
  }

  // __________________________________________________________________________ //

  Widget _dateTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: textfield(
            controller: TextEditingController(
              text: "${_selectedDate.toLocal()}".split(' ')[0],
            ),
            hintText: "Select Date",
            prefixIconData: Icons.calendar_today,
            readOnly: true,
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: textfield(
            controller: TextEditingController(
              text: _selectedTime.format(context),
            ),
            hintText: "Select Time",
            prefixIconData: Icons.access_time,
            readOnly: true,
            onTap: () async {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null) {
                setState(() {
                  _selectedTime = pickedTime;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _amountField() {
    return textfield(
      controller: _amountController,
      hintText: "00.00",
      lableText: "Amount",
      prefixIconData: Icons.currency_rupee_sharp,
    );
  }

  Widget _descriptionField() {
    return textfield(
      controller: _descriptionController,
      hintText: "Description",
      lableText: "Description",
      prefixIconData: Icons.description_outlined,
    );
  }

  Widget _paymentModeChoiceChips(bool isPaymentModeOne) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          isPaymentModeOne ? "From" : "To",
          style: TextTheme.of(context).titleLarge,
        ),
        ChoiceChip(
          label: const Text("Self Account"),
          selected: isPaymentModeOne
              ? !isPaymentModeOneGroup
              : !isPaymentModeTwoGroup,
          onSelected: (selected) {
            setState(() {
              if (isPaymentModeOne) {
                isPaymentModeOneGroup = !selected;
                _clearPaymentModeSelection(true);
              } else {
                isPaymentModeTwoGroup = !selected;
                _clearPaymentModeSelection(false);
              }
            });
          },
        ),
        ChoiceChip(
          label: const Text("Group"),
          selected:
              isPaymentModeOne ? isPaymentModeOneGroup : isPaymentModeTwoGroup,
          onSelected: (selected) {
            setState(() {
              if (isPaymentModeOne) {
                isPaymentModeOneGroup = selected;
                _clearPaymentModeSelection(true);
              } else {
                isPaymentModeTwoGroup = selected;
                _clearPaymentModeSelection(false);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _paymentModeField(
    UserData userData,
    UserFinanceData userFinanceData,
    bool isPaymentModeOne,
  ) {
    final isGroup =
        isPaymentModeOne ? isPaymentModeOneGroup : isPaymentModeTwoGroup;
    final controller = isPaymentModeOne
        ? _paymentModeOneController
        : _paymentModeTwoController;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        textfield(
          controller: controller,
          hintText: "Select ${isGroup ? "Group" : "Payment Mode"}",
          lableText: "Select ${isGroup ? "Group" : "Payment Mode"}",
          prefixIconData: Icons.payments_rounded,
          readOnly: true,
          sufixIconData: Icons.arrow_drop_down_circle_outlined,
          onTap: () {
            if (isGroup) {
              _showGroupSelectionBottomSheet(
                  userData, userFinanceData, isPaymentModeOne);
            } else {
              _showPaymentModeSelectionBottomSheet(
                  userData, userFinanceData, isPaymentModeOne);
            }
          },
        ),
        if (isGroup) ...[
          if (isPaymentModeOne && selectedGroup1 != null)
            ListTile(
              leading: const Icon(Icons.group),
              title: Text(selectedGroup1!.name ?? "Group"),
              subtitle: Text(
                  "Total Balance: ${selectedGroup1!.totalAmount ?? '0'} \nYour Balance: ${selectedGroup1!.membersBalance?[userData.uid] ?? '0'}"),
            ),
          if (!isPaymentModeOne && selectedGroup2 != null)
            ListTile(
              leading: const Icon(Icons.group),
              title: Text(selectedGroup2!.name ?? "Group"),
              subtitle: Text(
                  "Total Balance: ${selectedGroup2!.totalAmount ?? '0'} \nYour Balance: ${selectedGroup2!.membersBalance?[userData.uid] ?? '0'}"),
            ),
        ] else ...[
          // is Account
          if (isPaymentModeOne && selectedBank1 != null)
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(selectedBank1!.bankAccountName ?? "Bank Account"),
              subtitle: Text(
                  "Total Balance: ${selectedBank1!.availableBalance ?? '0'} \nAvailable Balance: ${selectedBank1!.availableBalance ?? '0'}"),
            ),
          if (!isPaymentModeOne && selectedBank2 != null)
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(selectedBank2!.bankAccountName ?? "Bank Account"),
              subtitle: Text(
                  "Total Balance: ${selectedBank2!.availableBalance ?? '0'} \nAvailable Balance: ${selectedBank2!.availableBalance ?? '0'}"),
            ),
          if (isPaymentModeOne && selectedWallet1 != null)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(selectedWallet1!.walletName ?? "Wallet"),
              subtitle: Text("Balance: ${selectedWallet1!.balance ?? '0'}"),
            ),
          if (!isPaymentModeOne && selectedWallet2 != null)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(selectedWallet2!.walletName ?? "Wallet"),
              subtitle: Text("Balance: ${selectedWallet2!.balance ?? '0'}"),
            ),
        ],
      ],
    );
  }

  void _showPaymentModeSelectionBottomSheet(
    UserData userData,
    UserFinanceData userFinanceData,
    bool isPaymentModeOne,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                bankAccountContainer(
                  context: context,
                  userFinanceData: userFinanceData,
                  isSelectable: true,
                  selectedBank: (isPaymentModeOne)
                      ? selectedBank1?.bankAccountName ?? ''
                      : selectedBank2?.bankAccountName ?? '',
                  onTapBank: (BankAccount bankAccount) {
                    setState(() {
                      if (isPaymentModeOne) {
                        _paymentModeOneController.text =
                            PaymentModes.bankAccount.displayName;
                        selectedBank1 = (_paymentModeOneController.text ==
                                PaymentModes.bankAccount.displayName)
                            ? bankAccount
                            : null;
                        selectedWallet1 = null;
                      } else {
                        _paymentModeTwoController.text =
                            PaymentModes.bankAccount.displayName;
                        selectedBank2 = (_paymentModeTwoController.text ==
                                PaymentModes.bankAccount.displayName)
                            ? bankAccount
                            : null;
                        selectedWallet2 = null;
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
                walletsContainer(
                  context: context,
                  userFinanceData: userFinanceData,
                  isSelectable: true,
                  selectedWallet: (isPaymentModeOne)
                      ? selectedWallet1?.walletName ?? ''
                      : selectedWallet2?.walletName ?? '',
                  onTapWallet: (Wallet wallet) {
                    setState(() {
                      if (isPaymentModeOne) {
                        _paymentModeOneController.text =
                            PaymentModes.wallet.displayName;
                        selectedWallet1 = (_paymentModeOneController.text ==
                                PaymentModes.wallet.displayName)
                            ? wallet
                            : null;
                        selectedBank1 = null;
                      } else {
                        _paymentModeTwoController.text =
                            PaymentModes.wallet.displayName;
                        selectedWallet2 = (_paymentModeTwoController.text ==
                                PaymentModes.wallet.displayName)
                            ? wallet
                            : null;
                        selectedBank2 = null;
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
                cashContainer(
                  isSelectable: true,
                  isSelected: (isPaymentModeOne)
                      ? _paymentModeOneController.text ==
                          PaymentModes.cash.displayName
                      : _paymentModeTwoController.text ==
                          PaymentModes.cash.displayName,
                  userFinanceData: userFinanceData,
                  onTap: () {
                    setState(() {
                      if (isPaymentModeOne) {
                        _paymentModeOneController.text =
                            PaymentModes.cash.displayName;
                        selectedBank1 = null;
                        selectedWallet1 = null;
                      } else {
                        _paymentModeTwoController.text =
                            PaymentModes.cash.displayName;
                        selectedBank2 = null;
                        selectedWallet2 = null;
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGroupSelectionBottomSheet(
    UserData userData,
    UserFinanceData userFinanceData,
    bool isPaymentModeOne,
  ) {
    // final List<Group> listOfUserGroups = userFinanceData.listOfGroups
    //         ?.where((group) => group.creatorId == userData.uid)
    //         .toList() ??
    //     [];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final groupList = userFinanceData.listOfGroups ?? [];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 8.0,
            children: /*((isPaymentModeOne) ? listOfUserGroups : groupList)*/
                groupList.map((group) {
              return ChoiceChip(
                label: Text(group.name ?? ""),
                selected: isPaymentModeOne
                    ? selectedGroup1 == group
                    : selectedGroup2 == group,
                onSelected: (selected) {
                  setState(() {
                    if (isPaymentModeOne) {
                      selectedGroup1 = selected ? group : null;
                      _paymentModeOneController.text =
                          selected ? PaymentModes.group.displayName : "";
                    } else {
                      selectedGroup2 = selected ? group : null;
                      _paymentModeTwoController.text =
                          selected ? PaymentModes.group.displayName : "";
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _clearPaymentModeSelection(bool isPaymentModeOne) {
    if (isPaymentModeOne) {
      _paymentModeOneController.clear();
      selectedGroup1 = null;
      selectedBank1 = null;
      selectedWallet1 = null;
    } else {
      _paymentModeTwoController.clear();
      selectedGroup2 = null;
      selectedBank2 = null;
      selectedWallet2 = null;
    }
  }

  Widget _floatingButton(UserData userData, UserFinanceData userFinanceData) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(300, 70), // Increased width and height
      ),
      onPressed: isButtonDisabled
          ? null
          : () {
              addTransaction(
                  userData.uid ?? '', userData, ref, userFinanceData);
            },
      child: isButtonLoading
          ? const CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : const Text(
              "Save Transaction",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
    );
  }

// __________________________________________________________________________ //

  void addTransaction(
    String uid,
    UserData userData,
    WidgetRef ref,
    UserFinanceData userFinanceData,
  ) async {
    _setButtonState(isLoading: true);

    // Validate inputs
    final validationError = _validateInputs(userFinanceData);
    if (validationError != null) {
      _showSnackbar(validationError, Icons.error);
      _resetButtonState();
      return;
    }

    // Prepare transaction data
    final transactionData = _prepareTransactionData(userData);
    if (transactionData == null) {
      _showSnackbar("Failed to prepare transaction data.", Icons.error);
      _resetButtonState();
      return;
    }

    // Save transaction
    final success =
        await _saveTransaction(uid, transactionData, ref, userFinanceData);
    if (success) {
      _showSnackbar("Transaction Added ✅", Icons.check_circle);
      Navigate().toAndRemoveUntil(BnbPages());
    } else {
      _showSnackbar("Error adding transaction ❗", Icons.error);
    }

    _resetButtonState();
  }

  String? _validateInputs(UserFinanceData userFinanceData) {
    UserData userData = ref.watch(userDataNotifierProvider);
    final amountText = _amountController.text.trim();
    final paymentMode1 = _paymentModeOneController.text.trim();
    final paymentMode2 = _paymentModeTwoController.text.trim();

    // Amount validation
    if (amountText.isEmpty) return "Amount cannot be empty.";
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return "Invalid amount entered.";

    // Payment mode validation
    if (paymentMode1.isEmpty || paymentMode2.isEmpty) {
      return "Please select both payment modes.";
    }

    // Ensure selected payment modes are not the same entity
    if (isPaymentModeOneGroup && isPaymentModeTwoGroup) {
      // if (selectedGroup1?.gid == selectedGroup2?.gid) {
      return "Can not Transfer from one group to another.";
      // }
    } else if (!isPaymentModeOneGroup && !isPaymentModeTwoGroup) {
      if (paymentMode1 == "Cash" && paymentMode2 == "Cash") {
        return "Both payment modes cannot be Cash.";
      }
      if (paymentMode1 == "Bank Account" &&
          paymentMode2 == "Bank Account" &&
          selectedBank1?.bid == selectedBank2?.bid) {
        return "Selected bank accounts cannot be the same.";
      }
      if (paymentMode1 == "Wallet" &&
          paymentMode2 == "Wallet" &&
          selectedWallet1?.wid == selectedWallet2?.wid) {
        return "Selected wallets cannot be the same.";
      }
    }

    // Check for sufficient balance in the selected payment mode
    if (paymentMode1 == "Cash" &&
        amount > double.parse(userFinanceData.cash?.amount ?? '0')) {
      return "Insufficient cash balance.";
    }

    if (paymentMode1 == "Bank Account" &&
        amount > double.parse(selectedBank1?.availableBalance ?? '0')) {
      return "Insufficient bank account balance.";
    }

    if (paymentMode1 == "Wallet" &&
        amount > double.parse(selectedWallet1?.balance ?? '0')) {
      return "Insufficient wallet balance.";
    }

    // add validation for groups here
    if (isPaymentModeOneGroup) {
      final group1 = selectedGroup1;
      if (group1 == null) return "Please select a valid group for 'From'.";

      final userBalance = double.parse((userData.uid == group1.creatorId)
          ? group1.totalAmount ?? "0.0"
          : group1.membersBalance?[userData.uid] ?? '0.0');
      if (amount > userBalance) {
        return "Insufficient balance in the selected group for 'From'.";
      }
    }

    if (isPaymentModeTwoGroup) {
      final group2 = selectedGroup2;
      if (group2 == null) return "Please select a valid group for 'To'.";

      if (isPaymentModeOneGroup && selectedGroup1?.gid == group2.gid) {
        return "Cannot transfer within the same group.";
      }
    }

    return null; // No validation errors
  }

  Transaction? _prepareTransactionData(UserData userData) {
    final amount = _amountController.text.trim().replaceAll('-', '');
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();
    final paymentMode1 = _paymentModeOneController.text.trim();
    final paymentMode2 = _paymentModeTwoController.text.trim();
    final bankAccountId1 = selectedBank1?.bid;
    final bankAccountId2 = selectedBank2?.bid;
    final walletId1 = selectedWallet1?.wid;
    final walletId2 = selectedWallet2?.wid;
    final groupId1 = selectedGroup1?.gid;
    final groupName = selectedGroup1?.name;
    final groupId2 = selectedGroup2?.gid;
    final groupName2 = selectedGroup2?.name;

    Logger().i("Transaction Data:\n"
        "Amount: $amount\n"
        "Description: $description\n"
        "Category: $category\n"
        "Payment Mode 1: $paymentMode1\n"
        "Payment Mode 2: $paymentMode2\n"
        "Bank Account ID 1: $bankAccountId1\n"
        "Bank Account ID 2: $bankAccountId2\n"
        "Wallet ID 1: $walletId1\n"
        "Wallet ID 2: $walletId2\n"
        "Group ID 1: $groupId1\n"
        "Group Name 1: $groupName\n"
        "Group ID 2: $groupId2\n"
        "Group Name 2: $groupName2\n"
        "Date: $_selectedDate\n"
        "Time: $_selectedTime");

    return Transaction(
      uid: userData.uid ?? "",
      amount: amount,
      category: category,
      date: _selectedDate,
      time: _selectedTime,
      description: description.isEmpty ? category : description,
      methodOfPayment: paymentMode1,
      methodOfPayment2: paymentMode2,
      isGroupTransaction: isPaymentModeOneGroup || isPaymentModeTwoGroup,
      gid: isPaymentModeOneGroup ? groupId1 : null,
      groupName: groupName,
      type: TransactionType.transfer,
      bankAccountId: bankAccountId1,
      walletId: walletId1,
      isTransferTransaction: true,
      gid2: isPaymentModeTwoGroup ? groupId2 : null,
      groupName2: groupName2,
      bankAccountId2: bankAccountId2,
      walletId2: walletId2,
    );
  }

  Future<bool> _saveTransaction(
    String uid,
    Transaction transactionData,
    WidgetRef ref,
    UserFinanceData userFinanceData,
  ) async {
    // save transaction to firestore and provider state
    final success = await ref
        .read(userFinanceDataNotifierProvider.notifier)
        .addTransferTransactionToUserData(
          uid: uid,
          transactionData: transactionData,
        );

    if (success) {
      // Update balances based on payment modes
      await _updateBalances(uid, transactionData, ref, userFinanceData);
    }

    return success;
  }

  Future<void> _updateBalances(
    String uid,
    Transaction transactionData,
    WidgetRef ref,
    UserFinanceData userFinanceData,
  ) async {
    final amount = double.parse(transactionData.amount ?? "0");

    // Update balance for Payment Mode 1
    await _updatePaymentModeBalance(
      uid: uid,
      paymentMode: transactionData.methodOfPayment,
      bankAccountId: transactionData.bankAccountId,
      walletId: transactionData.walletId,
      groupId: transactionData.gid,
      amount: -amount, // Deduct amount for Payment Mode 1
      ref: ref,
      userFinanceData: userFinanceData,
    );

    // Update balance for Payment Mode 2
    await _updatePaymentModeBalance(
      uid: uid,
      paymentMode: transactionData.methodOfPayment2,
      bankAccountId: transactionData.bankAccountId2,
      walletId: transactionData.walletId2,
      groupId: transactionData.gid2,
      amount: amount, // Add amount for Payment Mode 2
      ref: ref,
      userFinanceData: userFinanceData,
    );
  }

  Future<void> _updatePaymentModeBalance({
    required String uid,
    required String? paymentMode,
    required String? bankAccountId,
    required String? walletId,
    required String? groupId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    if (paymentMode == "Cash") {
      // Update cash balance
      final updatedCashAmount =
          (double.parse(userFinanceData.cash?.amount ?? '0') + amount)
              .toString();
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateUserCashAmount(
            uid: uid,
            amount: updatedCashAmount,
          );
    } else if (paymentMode == "Bank Account" && bankAccountId != null) {
      // Update bank account balance
      final bankAccount = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);
      final updatedBalance =
          (double.parse(bankAccount?.availableBalance ?? '0') + amount)
              .toString();
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId,
            newBalance: updatedBalance,
          );
    } else if (paymentMode == "Wallet" && walletId != null) {
      // Update wallet balance
      final wallet = userFinanceData.listOfWallets
          ?.firstWhere((wallet) => wallet.wid == walletId);
      final updatedBalance =
          (double.parse(wallet?.balance ?? '0') + amount).toString();
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateWalletBalance(
            uid: uid,
            walletId: walletId,
            newBalance: updatedBalance,
          );
    } else if (paymentMode == "Group" && groupId != null) {
      // Update group balance
      final group = userFinanceData.listOfGroups
          ?.firstWhere((group) => group.gid == groupId);
      final updatedGroupAmount =
          (double.parse(group?.totalAmount ?? '0') + amount).toString();
      final updatedMemberAmount =
          (double.parse(group?.membersBalance?[uid] ?? '0') + amount)
              .toString();
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateGroupAmount(
            gid: groupId,
            amount: updatedGroupAmount,
            uid: uid,
            memberAmount: updatedMemberAmount,
          );
    }
  }

// __________________________________________________________________________ //

  void _showSnackbar(String message, IconData icon) {
    snackbarToast(
      context: context,
      text: message,
      icon: icon,
    );
  }

  void _setButtonState({required bool isLoading}) {
    setState(() {
      isButtonDisabled = isLoading;
      isButtonLoading = isLoading;
    });
  }

  void _resetButtonState() {
    _setButtonState(isLoading: false);
  }
}
