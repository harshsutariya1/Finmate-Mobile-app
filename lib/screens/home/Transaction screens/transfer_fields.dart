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

    return textfield(
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
                          selected ? group.name ?? "" : "";
                    } else {
                      selectedGroup2 = selected ? group : null;
                      _paymentModeTwoController.text =
                          selected ? group.name ?? "" : "";
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
      if (selectedGroup1?.gid == selectedGroup2?.gid) {
        return "Selected groups cannot be the same.";
      }
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
    final groupId2 = selectedGroup2?.gid;

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
      type: TransactionType.transfer,
      bankAccountId: selectedBank1?.bid,
      walletId: selectedWallet1?.wid,
      isTransferTransaction: true,
      gid2: isPaymentModeTwoGroup ? groupId2 : null,
      bankAccountId2: selectedBank2?.bid,
      walletId2: selectedWallet2?.wid,
    );
  }

  Future<bool> _saveTransaction(
    String uid,
    Transaction transactionData,
    WidgetRef ref,
    UserFinanceData userFinanceData,
  ) async {
    final success = await ref
        .read(userFinanceDataNotifierProvider.notifier)
        .addTransactionToUserData(
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
    if (transactionData.methodOfPayment == "Cash") {
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateUserCashAmount(
            uid: uid,
            amount: (double.parse(userFinanceData.cash?.amount ?? '0') - amount)
                .toString(),
          );
    } else if (transactionData.methodOfPayment == "Bank Account" &&
        transactionData.bankAccountId != null) {
      final updatedBalance =
          (double.parse(selectedBank1?.availableBalance ?? '0') - amount)
              .toString();
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: transactionData.bankAccountId!,
            newBalance: updatedBalance,
          );
    } else if (transactionData.methodOfPayment == "Wallet" &&
        transactionData.walletId != null) {
      final updatedBalance =
          (double.parse(selectedWallet1?.balance ?? '0') - amount).toString();
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateWalletBalance(
            uid: uid,
            walletId: transactionData.walletId!,
            newBalance: updatedBalance,
          );
    }

    // Update balance for Payment Mode 2 (if applicable)
    // Add logic here if Payment Mode 2 requires balance updates
  }

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
