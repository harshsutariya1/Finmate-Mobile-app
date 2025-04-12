import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/transaction_category.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
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
      TextEditingController(text: SystemCategory.transfer.displayName);
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

  Group? selectedGroup2;
  BankAccount? selectedBank2;

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
          spacing: 10,
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
          // is Group
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
          // is Bank Account
          if (isPaymentModeOne && selectedBank1 != null)
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(selectedBank1!.bankAccountName ?? "Bank Account"),
              subtitle: Text(
                  "Total Balance: ${selectedBank1!.totalBalance ?? '0'} \nAvailable Balance: ${selectedBank1!.availableBalance ?? '0'} \n${(selectedGroup2 != null && (selectedGroup2?.linkedBankAccountId == selectedBank1?.bid)) ? 'Available Group Balances: ${selectedBank1!.groupsBalance?[selectedGroup2?.gid] ?? '0'}' : ''}"),
            ),
          if (!isPaymentModeOne && selectedBank2 != null)
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(selectedBank2!.bankAccountName ?? "Bank Account"),
              subtitle: Text(
                  "Total Balance: ${selectedBank2!.totalBalance ?? '0'} \nAvailable Balance: ${selectedBank2!.availableBalance ?? '0'} \n${(selectedGroup1 != null && (selectedGroup1?.linkedBankAccountId == selectedBank2?.bid)) ? 'Available Group Balance: ${selectedBank2!.groupsBalance?[selectedGroup1?.gid] ?? '0'}' : ''}"),
            ),
          // is Cash
          if (isPaymentModeOne &&
              _paymentModeOneController.text == PaymentModes.cash.displayName)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text("Cash"),
              subtitle: Text("Balance: ${userFinanceData.cash?.amount ?? '0'}"),
            ),
          if (!isPaymentModeOne &&
              _paymentModeTwoController.text == PaymentModes.cash.displayName)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text("Cash"),
              subtitle: Text("Balance: ${userFinanceData.cash?.amount ?? '0'}"),
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
      isScrollControlled: true, // Allow the bottom sheet to expand
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.7, // Set height to 70% of the screen
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
                      "Select Payment Mode",
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
                  bool isSelected = (isPaymentModeOne
                      ? selectedBank1?.bid == bankAccount.bid
                      : selectedBank2?.bid == bankAccount.bid);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isPaymentModeOne) {
                          _paymentModeOneController.text =
                              PaymentModes.bankAccount.displayName;
                          selectedBank1 = bankAccount;
                        } else {
                          _paymentModeTwoController.text =
                              PaymentModes.bankAccount.displayName;
                          selectedBank2 = bankAccount;
                        }
                      });
                      Navigator.pop(context);
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
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                sbh10,
                // Cash Option
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isPaymentModeOne) {
                        _paymentModeOneController.text =
                            PaymentModes.cash.displayName;
                        selectedBank1 = null;
                      } else {
                        _paymentModeTwoController.text =
                            PaymentModes.cash.displayName;
                        selectedBank2 = null;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: (isPaymentModeOne
                                  ? _paymentModeOneController.text
                                  : _paymentModeTwoController.text) ==
                              PaymentModes.cash.displayName
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
                          bottomLeft: (isPaymentModeOne
                                      ? _paymentModeOneController.text
                                      : _paymentModeTwoController.text) ==
                                  PaymentModes.cash.displayName
                              ? const Radius.circular(0)
                              : const Radius.circular(10),
                          bottomRight: (isPaymentModeOne
                                      ? _paymentModeOneController.text
                                      : _paymentModeTwoController.text) ==
                                  PaymentModes.cash.displayName
                              ? const Radius.circular(0)
                              : const Radius.circular(10),
                        ),
                        border: Border.all(
                          color: color2.withAlpha(150),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: (isPaymentModeOne
                                        ? _paymentModeOneController.text
                                        : _paymentModeTwoController.text) ==
                                    PaymentModes.cash.displayName
                                ? color3
                                : color1,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cash",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: (isPaymentModeOne
                                                ? _paymentModeOneController.text
                                                : _paymentModeTwoController
                                                    .text) ==
                                            PaymentModes.cash.displayName
                                        ? color3
                                        : color1,
                                  ),
                                ),
                                Text(
                                  "Balance: ${userFinanceData.cash?.amount ?? '0'}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: color1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final groupList = userFinanceData.listOfGroups ?? [];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 8.0,
            children: groupList.map((group) {
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
    } else {
      _paymentModeTwoController.clear();
      selectedGroup2 = null;
      selectedBank2 = null;
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
      return "Can not Transfer from one group to another.";
    } else if (!isPaymentModeOneGroup && !isPaymentModeTwoGroup) {
      if (paymentMode1 == "Cash" && paymentMode2 == "Cash") {
        return "Both payment modes cannot be Cash.";
      }
      if (paymentMode1 == "Bank Account" &&
          paymentMode2 == "Bank Account" &&
          selectedBank1?.bid == selectedBank2?.bid) {
        return "Selected bank accounts cannot be the same.";
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
    final bankAccountName = selectedBank1?.bankAccountName;
    final bankAccountId2 = selectedBank2?.bid;
    final bankAccountName2 = selectedBank2?.bankAccountName;
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
      bankAccountId: bankAccountId1,
      bankAccountName: bankAccountName,
      transactionType: TransactionType.transfer.displayName,
      isTransferTransaction: true,
      gid2: isPaymentModeTwoGroup ? groupId2 : null,
      groupName2: groupName2,
      bankAccountId2: bankAccountId2,
      bankAccountName2: bankAccountName2,
    );
  }

  Future<bool> _saveTransaction(
    String uid,
    Transaction transactionData,
    WidgetRef ref,
    UserFinanceData userFinanceData,
  ) async {
    try {
      // Save transaction to Firestore and provider state
      final success = await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .addTransferTransactionToUserData(
            uid: uid,
            transactionData: transactionData,
          );

      if (success) {
        // Update balances based on payment modes
        await _updateBalances(
          uid: uid,
          transactionData: transactionData,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      }

      return success;
    } catch (e, stackTrace) {
      Logger()
          .e("Error in _saveTransaction:", error: e, stackTrace: stackTrace);
      _showSnackbar("Failed to save transaction.", Icons.error);
      return false;
    }
  }

// __________________________________________________________________________ //

  Future<void> _updateBalances({
    required String uid,
    required Transaction transactionData,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    try {
      final double amount = double.parse(transactionData.amount ?? "0");

      // Determine the payment modes and call the appropriate handler
      if (transactionData.methodOfPayment ==
              PaymentModes.bankAccount.displayName &&
          transactionData.methodOfPayment2 ==
              PaymentModes.bankAccount.displayName) {
        // Bank to Bank
        await _handleBankToBankTransfer(
          uid: uid,
          bankAccountId1: transactionData.bankAccountId ?? '',
          bankAccountId2: transactionData.bankAccountId2 ?? "",
          amount: amount,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      } else if (transactionData.methodOfPayment ==
              PaymentModes.bankAccount.displayName &&
          transactionData.methodOfPayment2 == PaymentModes.cash.displayName) {
        // Bank to Cash
        await _handleBankToCashTransfer(
          uid: uid,
          bankAccountId: transactionData.bankAccountId,
          amount: amount,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      } else if (transactionData.methodOfPayment ==
              PaymentModes.cash.displayName &&
          transactionData.methodOfPayment2 ==
              PaymentModes.bankAccount.displayName) {
        // Cash to Bank
        await _handleCashToBankTransfer(
          uid: uid,
          bankAccountId: transactionData.bankAccountId2,
          amount: amount,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      } else if (transactionData.methodOfPayment ==
              PaymentModes.group.displayName &&
          transactionData.methodOfPayment2 == PaymentModes.cash.displayName) {
        // Group to Cash
        await _handleGroupToCashTransfer(
          uid: uid,
          groupId: transactionData.gid,
          amount: amount,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      } else if (transactionData.methodOfPayment ==
              PaymentModes.cash.displayName &&
          transactionData.methodOfPayment2 == PaymentModes.group.displayName) {
        // Cash to Group
        await _handleCashToGroupTransfer(
          uid: uid,
          groupId: transactionData.gid2,
          amount: amount,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      } else if (transactionData.methodOfPayment ==
              PaymentModes.bankAccount.displayName &&
          transactionData.methodOfPayment2 == PaymentModes.group.displayName) {
        // Bank to Group
        await _handleBankToGroupTransfer(
          uid: uid,
          bankAccountId: transactionData.bankAccountId,
          groupId: transactionData.gid2,
          amount: amount,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      } else if (transactionData.methodOfPayment ==
              PaymentModes.group.displayName &&
          transactionData.methodOfPayment2 ==
              PaymentModes.bankAccount.displayName) {
        // Group to Bank
        await _handleGroupToBankTransfer(
          uid: uid,
          bankAccountId: transactionData.bankAccountId2,
          groupId: transactionData.gid,
          amount: amount,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      } else {
        throw Exception("Unsupported payment mode combination.");
      }
    } catch (e, stackTrace) {
      Logger().e("Error in _updateBalances:", error: e, stackTrace: stackTrace);
      _showSnackbar("An error occurred while updating balances.", Icons.error);
    }
  }

  Future<void> _handleBankToBankTransfer({
    required String uid,
    required String bankAccountId1,
    required String bankAccountId2,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    try {
      final bankAccount1 = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId1);
      final bankAccount2 = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId2);

      if (bankAccount1 == null || bankAccount2 == null) {
        throw Exception("Bank accounts not found.");
      }

      final updatedAvailableBalance1 =
          (double.parse(bankAccount1.availableBalance ?? '0') - amount)
              .toString();
      final updatedTotalBalance1 =
          (double.parse(bankAccount1.totalBalance ?? '0') - amount).toString();

      final updatedAvailableBalance2 =
          (double.parse(bankAccount2.availableBalance ?? '0') + amount)
              .toString();
      final updatedTotalBalance2 =
          (double.parse(bankAccount2.totalBalance ?? '0') + amount).toString();

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId1,
            availableBalance: updatedAvailableBalance1,
            totalBalance: updatedTotalBalance1,ref: ref,
          );

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId2,
            availableBalance: updatedAvailableBalance2,
            totalBalance: updatedTotalBalance2,
            ref: ref,
          );
    } catch (e, stackTrace) {
      Logger().e("Error in _handleBankToBankTransfer:",
          error: e, stackTrace: stackTrace);
      _showSnackbar("Failed to transfer between bank accounts.", Icons.error);
    }
  }

  Future<void> _handleBankToCashTransfer({
    required String uid,
    required String? bankAccountId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    try {
      final bankAccount = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);

      if (bankAccount == null) {
        throw Exception("Bank account not found.");
      }

      final updatedAvailableBalance =
          (double.parse(bankAccount.availableBalance ?? '0') - amount)
              .toString();
      final updatedTotalBalance =
          (double.parse(bankAccount.totalBalance ?? '0') - amount).toString();
      final updatedCashAmount =
          (double.parse(userFinanceData.cash?.amount ?? '0') + amount)
              .toString();

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId!,
            availableBalance: updatedAvailableBalance,
            totalBalance: updatedTotalBalance,
            ref: ref,
          );

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateUserCashAmount(
            uid: uid,
            amount: updatedCashAmount,
            ref: ref,
          );
    } catch (e, stackTrace) {
      Logger().e("Error in _handleBankToCashTransfer:",
          error: e, stackTrace: stackTrace);
      _showSnackbar("Failed to transfer from bank to cash.", Icons.error);
    }
  }

  Future<void> _handleCashToBankTransfer({
    required String uid,
    required String? bankAccountId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    try {
      final bankAccount = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);

      if (bankAccount == null) {
        throw Exception("Bank account not found.");
      }

      final updatedAvailableBalance =
          (double.parse(bankAccount.availableBalance ?? '0') + amount)
              .toString();
      final updatedTotalBalance =
          (double.parse(bankAccount.totalBalance ?? '0') + amount).toString();
      final updatedCashAmount =
          (double.parse(userFinanceData.cash?.amount ?? '0') - amount)
              .toString();

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId!,
            availableBalance: updatedAvailableBalance,
            totalBalance: updatedTotalBalance,
            ref: ref,
          );

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateUserCashAmount(
            uid: uid,
            amount: updatedCashAmount,
            ref: ref,
          );
    } catch (e, stackTrace) {
      Logger().e("Error in _handleCashToBankTransfer:",
          error: e, stackTrace: stackTrace);
      _showSnackbar("Failed to transfer from cash to bank.", Icons.error);
    }
  }

  Future<void> _handleGroupToCashTransfer({
    required String uid,
    required String? groupId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    try {
      final group = userFinanceData.listOfGroups
          ?.firstWhere((group) => group.gid == groupId);

      if (group == null) {
        throw Exception("Group not found.");
      }

      final updatedGroupTotalAmount =
          (double.parse(group.totalAmount ?? '0') - amount).toString();
      final updatedMemberBalance =
          (double.parse(group.membersBalance?[uid] ?? '0') - amount).toString();
      final updatedCashAmount =
          (double.parse(userFinanceData.cash?.amount ?? '0') + amount)
              .toString();

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateGroupAmount(
            gid: groupId!,
            amount: updatedGroupTotalAmount,
            uid: uid,
            memberAmount: updatedMemberBalance,
          );

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateUserCashAmount(
            uid: uid,
            amount: updatedCashAmount,
            ref: ref,
          );
    } catch (e, stackTrace) {
      Logger().e("Error in _handleGroupToCashTransfer:",
          error: e, stackTrace: stackTrace);
      _showSnackbar("Failed to transfer from group to cash.", Icons.error);
    }
  }

  Future<void> _handleCashToGroupTransfer({
    required String uid,
    required String? groupId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    try {
      final group = userFinanceData.listOfGroups
          ?.firstWhere((group) => group.gid == groupId);

      if (group == null) {
        throw Exception("Group not found.");
      }

      final updatedGroupTotalAmount =
          (double.parse(group.totalAmount ?? '0') + amount).toString();
      final updatedMemberBalance =
          (double.parse(group.membersBalance?[uid] ?? '0') + amount).toString();
      final updatedCashAmount =
          (double.parse(userFinanceData.cash?.amount ?? '0') - amount)
              .toString();

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateGroupAmount(
            gid: groupId!,
            amount: updatedGroupTotalAmount,
            uid: uid,
            memberAmount: updatedMemberBalance,
          );

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateUserCashAmount(
            uid: uid,
            amount: updatedCashAmount,
            ref: ref,
          );
    } catch (e, stackTrace) {
      Logger().e("Error in _handleCashToGroupTransfer:",
          error: e, stackTrace: stackTrace);
      _showSnackbar("Failed to transfer from cash to group.", Icons.error);
    }
  }

  Future<void> _handleGroupToBankTransfer({
    required String uid,
    required String? bankAccountId,
    required String? groupId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    try {
      final bankAccount = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);
      final group = userFinanceData.listOfGroups
          ?.firstWhere((group) => group.gid == groupId);

      if (bankAccount == null || group == null) {
        throw Exception("Bank account or group not found.");
      }

      final isAdmin = group.creatorId == uid;
      final isBankLinked =
          bankAccount.linkedGroupIds?.contains(groupId) ?? false;

      if (isBankLinked) {
        // Case 1: Group is linked to the bank
        final updatedGroupTotalAmount =
            (double.parse(group.totalAmount ?? '0') - amount).toString();
        final updatedMemberBalance =
            (double.parse(group.membersBalance?[uid] ?? '0') - amount)
                .toString();
        final updatedGroupBalance =
            (double.parse(bankAccount.groupsBalance?[groupId] ?? '0') - amount)
                .toString();
        final updatedAvailableBalance =
            (double.parse(bankAccount.availableBalance ?? '0') + amount)
                .toString();

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupAmount(
              gid: groupId!,
              amount: updatedGroupTotalAmount,
              uid: uid,
              memberAmount: updatedMemberBalance,
            );

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateBankAccountBalance(
          uid: uid,
          bankAccountId: bankAccountId!,
          availableBalance: updatedAvailableBalance,
          totalBalance: bankAccount.totalBalance ?? '0',
          groupsBalance: {
            ...bankAccount.groupsBalance!,
            groupId: updatedGroupBalance,
          },
          ref: ref,
        );
      } else if (isAdmin) {
        // Case 2: Group is not linked, and user is admin
        final updatedGroupTotalAmount =
            (double.parse(group.totalAmount ?? '0') - amount).toString();
        final updatedMemberBalance =
            (double.parse(group.membersBalance?[uid] ?? '0') - amount)
                .toString();

        final linkedBankAccount = userFinanceData.listOfBankAccounts
            ?.firstWhere((account) => account.bid == group.linkedBankAccountId);

        if (linkedBankAccount != null) {
          final updatedLinkedBankTotalBalance =
              (double.parse(linkedBankAccount.totalBalance ?? '0') - amount)
                  .toString();
          final updatedLinkedBankGroupBalance =
              (double.parse(linkedBankAccount.groupsBalance?[groupId] ?? '0') -
                      amount)
                  .toString();

          await ref
              .read(userFinanceDataNotifierProvider.notifier)
              .updateBankAccountBalance(
            uid: uid,
            bankAccountId: linkedBankAccount.bid!,
            totalBalance: updatedLinkedBankTotalBalance,
            availableBalance: linkedBankAccount.availableBalance ?? '0',
            groupsBalance: {
              ...linkedBankAccount.groupsBalance!,
              groupId!: updatedLinkedBankGroupBalance,
            },
            ref: ref,
          );
        }

        final updatedAvailableBalance =
            (double.parse(bankAccount.availableBalance ?? '0') + amount)
                .toString();
        final updatedTotalBalance =
            (double.parse(bankAccount.totalBalance ?? '0') + amount).toString();

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateBankAccountBalance(
              uid: uid,
              bankAccountId: bankAccountId!,
              availableBalance: updatedAvailableBalance,
              totalBalance: updatedTotalBalance,ref: ref,
            );

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupAmount(
              gid: groupId!,
              amount: updatedGroupTotalAmount,
              uid: uid,
              memberAmount: updatedMemberBalance,
            );
      } else {
        // Case 3: Group is not linked, and user is not admin
        final updatedGroupTotalAmount =
            (double.parse(group.totalAmount ?? '0') - amount).toString();
        final updatedMemberBalance =
            (double.parse(group.membersBalance?[uid] ?? '0') - amount)
                .toString();

        final linkedBankAccount = userFinanceData.listOfBankAccounts
            ?.firstWhere((account) => account.bid == group.linkedBankAccountId);

        if (linkedBankAccount != null) {
          final updatedLinkedBankTotalBalance =
              (double.parse(linkedBankAccount.totalBalance ?? '0') - amount)
                  .toString();
          final updatedLinkedBankGroupBalance =
              (double.parse(linkedBankAccount.groupsBalance?[groupId] ?? '0') -
                      amount)
                  .toString();

          await ref
              .read(userFinanceDataNotifierProvider.notifier)
              .updateBankAccountBalance(
            uid: group.creatorId!,
            bankAccountId: linkedBankAccount.bid!,
            totalBalance: updatedLinkedBankTotalBalance,
            availableBalance: linkedBankAccount.availableBalance ?? '0',
            groupsBalance: {
              ...linkedBankAccount.groupsBalance!,
              groupId!: updatedLinkedBankGroupBalance,
            },
            ref: ref,
          );
        }

        final updatedAvailableBalance =
            (double.parse(bankAccount.availableBalance ?? '0') + amount)
                .toString();
        final updatedTotalBalance =
            (double.parse(bankAccount.totalBalance ?? '0') + amount).toString();

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateBankAccountBalance(
              uid: uid,
              bankAccountId: bankAccountId!,
              availableBalance: updatedAvailableBalance,
              totalBalance: updatedTotalBalance,
              ref: ref,
            );

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupAmount(
              gid: groupId!,
              amount: updatedGroupTotalAmount,
              uid: uid,
              memberAmount: updatedMemberBalance,
            );
      }
    } catch (e, stackTrace) {
      Logger().e("Error in _handleGroupToBankTransfer:",
          error: e, stackTrace: stackTrace);
      _showSnackbar("Failed to transfer from group to bank.", Icons.error);
    }
  }

  Future<void> _handleBankToGroupTransfer({
    required String uid,
    required String? bankAccountId,
    required String? groupId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    try {
      final bankAccount = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);
      final group = userFinanceData.listOfGroups
          ?.firstWhere((group) => group.gid == groupId);

      if (bankAccount == null || group == null) {
        throw Exception("Bank account or group not found.");
      }

      final isAdmin = group.creatorId == uid;
      final isBankLinked =
          bankAccount.linkedGroupIds?.contains(groupId) ?? false;

      if (isBankLinked) {
        // Case 1: Bank is linked to the group
        final updatedAvailableBalance =
            (double.parse(bankAccount.availableBalance ?? '0') - amount)
                .toString();
        final updatedTotalBalance =
            (double.parse(bankAccount.totalBalance ?? '0') - amount).toString();

        final updatedGroupTotalAmount =
            (double.parse(group.totalAmount ?? '0') + amount).toString();
        final updatedMemberBalance =
            (double.parse(group.membersBalance?[uid] ?? '0') + amount)
                .toString();
        final updatedGroupBalance =
            (double.parse(bankAccount.groupsBalance?[groupId] ?? '0') + amount)
                .toString();

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateBankAccountBalance(
          uid: uid,
          bankAccountId: bankAccountId!,
          availableBalance: updatedAvailableBalance,
          totalBalance: updatedTotalBalance,
          bankAccount: bankAccount,
          groupsBalance: {
            ...?bankAccount.groupsBalance,
            groupId!: updatedGroupBalance,
          },
          ref: ref,
        );

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupAmount(
              gid: groupId,
              amount: updatedGroupTotalAmount,
              uid: uid,
              memberAmount: updatedMemberBalance,
            );
      } else if (isAdmin) {
        // Case 2: Bank is not linked, and user is admin
        final updatedAvailableBalance =
            (double.parse(bankAccount.availableBalance ?? '0') - amount)
                .toString();
        final updatedTotalBalance =
            (double.parse(bankAccount.totalBalance ?? '0') - amount).toString();
        final updatedGroupTotalAmount =
            (double.parse(group.totalAmount ?? '0') + amount).toString();
        final updatedMemberBalance =
            (double.parse(group.membersBalance?[uid] ?? '0') + amount)
                .toString();

        final linkedBankAccount = userFinanceData.listOfBankAccounts
            ?.firstWhere((account) => account.bid == group.linkedBankAccountId);

        if (linkedBankAccount != null) {
          final updatedLinkedBankTotalBalance =
              (double.parse(linkedBankAccount.totalBalance ?? '0') + amount)
                  .toString();
          final updatedLinkedBankGroupBalance =
              (double.parse(linkedBankAccount.groupsBalance?[groupId] ?? '0') +
                      amount)
                  .toString();

          await ref
              .read(userFinanceDataNotifierProvider.notifier)
              .updateBankAccountBalance(
            uid: uid,
            bankAccountId: linkedBankAccount.bid!,
            totalBalance: updatedLinkedBankTotalBalance,
            availableBalance: linkedBankAccount.availableBalance ?? '0',
            groupsBalance: {
              ...?linkedBankAccount.groupsBalance,
              groupId!: updatedLinkedBankGroupBalance,
            },ref: ref,
          );
        }

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateBankAccountBalance(
              uid: uid,
              bankAccountId: bankAccountId!,
              availableBalance: updatedAvailableBalance,
              totalBalance: updatedTotalBalance,ref: ref,
            );

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupAmount(
              gid: groupId!,
              amount: updatedGroupTotalAmount,
              uid: uid,
              memberAmount: updatedMemberBalance,
            );
      } else {
        // Case 3: Bank is not linked, and user is not admin
        final updatedAvailableBalance =
            (double.parse(bankAccount.availableBalance ?? '0') - amount)
                .toString();
        final updatedTotalBalance =
            (double.parse(bankAccount.totalBalance ?? '0') - amount).toString();
        final updatedGroupTotalAmount =
            (double.parse(group.totalAmount ?? '0') + amount).toString();
        final updatedMemberBalance =
            (double.parse(group.membersBalance?[uid] ?? '0') + amount)
                .toString();

        final linkedBankAccount = userFinanceData.listOfBankAccounts
            ?.firstWhere((account) => account.bid == group.linkedBankAccountId);

        if (linkedBankAccount != null) {
          final updatedLinkedBankTotalBalance =
              (double.parse(linkedBankAccount.totalBalance ?? '0') + amount)
                  .toString();
          final updatedLinkedBankGroupBalance =
              (double.parse(linkedBankAccount.groupsBalance?[groupId] ?? '0') +
                      amount)
                  .toString();

          await ref
              .read(userFinanceDataNotifierProvider.notifier)
              .updateBankAccountBalance(
            uid: group.creatorId!,
            bankAccountId: linkedBankAccount.bid!,
            totalBalance: updatedLinkedBankTotalBalance,
            availableBalance: linkedBankAccount.availableBalance ?? '0',
            groupsBalance: {
              ...?linkedBankAccount.groupsBalance,
              groupId!: updatedLinkedBankGroupBalance,
            },ref: ref,
          );
        }

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateBankAccountBalance(
              uid: uid,
              bankAccountId: bankAccountId!,
              availableBalance: updatedAvailableBalance,
              totalBalance: updatedTotalBalance,ref: ref,
            );

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupAmount(
              gid: groupId!,
              amount: updatedGroupTotalAmount,
              uid: uid,
              memberAmount: updatedMemberBalance,
            );
      }
    } catch (e, stackTrace) {
      Logger().e("Error in _handleBankToGroupTransfer:",
          error: e, stackTrace: stackTrace);
      _showSnackbar("Failed to transfer from bank to group.", Icons.error);
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
