import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseIncomeFields extends ConsumerStatefulWidget {
  const ExpenseIncomeFields({super.key, this.isIncome = false});
  final bool isIncome;

  @override
  ConsumerState<ExpenseIncomeFields> createState() =>
      _ExpenseIncomeFieldsState();
}

class _ExpenseIncomeFieldsState extends ConsumerState<ExpenseIncomeFields> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _payeeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _paymentModeController = TextEditingController();

  Group? selectedGroup;
  BankAccount? selectedBank;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool isIncomeSelected = false;
  bool isButtonDisabled = false;
  bool isButtonLoading = false;

  @override
  void initState() {
    super.initState();
    isIncomeSelected = widget.isIncome;
  }

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
      body: Container(
        padding: EdgeInsets.only(
          top: 30,
          right: 20,
          left: 20,
          bottom: 0,
        ),
        child: _bodyForm(
          userData: userData,
          userFinanceData: userFinanceData,
        ),
      ),
    );
  }

  Widget _bodyForm(
      {required UserData userData, required UserFinanceData userFinanceData}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: 20,
        children: [
          _dateTimePicker(),
          Row(
            children: [
              // income / expense button
              Padding(
                padding: const EdgeInsets.only(right: 10, left: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: (isIncomeSelected)
                        ? color3.withAlpha(150)
                        : Colors.redAccent,
                    minimumSize:
                        Size(double.minPositive, 50), // Set width and height
                  ),
                  child: Text(
                    (isIncomeSelected) ? "Income" : "Expense",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color4,
                    ),
                  ),
                  onPressed: () => setState(() {
                    isIncomeSelected = !isIncomeSelected;
                  }),
                ),
              ),
              Expanded(
                child: textfield(
                  controller: _amountController,
                  hintText: "00.00",
                  lableText: "Amount",
                  prefixIconData: Icons.currency_rupee_sharp,
                ),
              ),
            ],
          ),
          textfield(
            controller: _payeeController, // Added Payee Textfield
            hintText: "To Payee",
            lableText: "To Payee",
            prefixIconData: Icons.person_outline,
          ),
          textfield(
            controller: _descriptionController,
            hintText: "Description",
            lableText: "Description",
            prefixIconData: Icons.description_outlined,
          ),
          textfield(
              controller: _categoryController,
              prefixIconData: Icons.category_rounded,
              hintText: "Select Category",
              lableText: "Category",
              readOnly: true,
              sufixIconData: Icons.arrow_drop_down_circle_outlined,
              onTap: () {
                // show modal bottom sheet to select category
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    Iterable<String> categoryList =
                        transactionCategoriesAndIcons.keys;
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Select Category"),
                                IconButton(
                                  onPressed: () {
                                    snackbarToast(
                                        context: context,
                                        text: "This Function is in development",
                                        icon: Icons.developer_mode_outlined);
                                  },
                                  icon: Icon(Icons.add),
                                  color: color3,
                                )
                              ],
                            ),
                            Wrap(
                              spacing: 8.0,
                              children: categoryList.map((category) {
                                if (category ==
                                        TransactionCategory
                                            .balanceAdjustment.displayName ||
                                    category ==
                                        TransactionCategory
                                            .transfer.displayName) {
                                  return SizedBox.shrink();
                                }
                                return ChoiceChip(
                                  label: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    spacing: 20,
                                    children: [
                                      Icon(
                                        transactionCategoriesAndIcons[category],
                                        color: color1,
                                      ),
                                      Text(category),
                                    ],
                                  ),
                                  // showCheckmark: false,
                                  selected:
                                      _categoryController.text == category,
                                  onSelected: (selected) {
                                    setState(() {
                                      _categoryController.text =
                                          selected ? category : '';
                                      Navigator.pop(context);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
          textfield(
            controller: _paymentModeController,
            prefixIconData: Icons.payments_rounded,
            hintText: "Select Payment Mode",
            lableText: "Payment Mode",
            readOnly: true,
            sufixIconData: Icons.arrow_drop_down_circle_outlined,
            onTap: () {
              showAccountSelection(userFinanceData);
            },
          ),
          if (selectedBank != null)
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(selectedBank!.bankAccountName ?? "Bank Account"),
              subtitle: Text(
                  "Total Balance: ${selectedBank!.totalBalance ?? '0'} \nAvailable Balance: ${selectedBank!.availableBalance ?? '0'}"),
            ),
          textfield(
            controller: _groupController,
            prefixIconData: Icons.group_add_rounded,
            hintText: "Add Group Transaction",
            lableText: "Group Transaction",
            readOnly: true,
            sufixIconData: Icons.arrow_drop_down_circle_outlined,
            onTap: () {
              // show modal bottom sheet to select payment mode
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  List<Group> groupList =
                      userFinanceData.listOfGroups!.toList();
                  return Container(
                    margin: EdgeInsets.only(bottom: 50),
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Select Group"),
                              Text(
                                "Your Groups = 🟢",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          sbh10,
                          Wrap(
                            spacing: 8.0,
                            children: groupList.map((group) {
                              return ChoiceChip(
                                label: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  spacing: 20,
                                  children: [
                                    Text(group.name.toString()),
                                    (group.creatorId == userData.uid)
                                        ? Text(
                                            "🟢",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : SizedBox.shrink(),
                                  ],
                                ),
                                selected: _groupController.text ==
                                    group.name.toString(),
                                onSelected: (groupSelected) {
                                  setState(() {
                                    _groupController.text = groupSelected
                                        ? group.name.toString()
                                        : '';
                                    selectedGroup =
                                        groupSelected ? group : null;

                                    // Clear payment mode selection
                                    _paymentModeController.clear();
                                    selectedBank = null;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (selectedGroup != null)
            ListTile(
              leading: const Icon(Icons.group),
              title: Text(selectedGroup!.name ?? "Group"),
              subtitle: Text(
                  "Total Amount: ${selectedGroup!.totalAmount ?? '0'} \nYour Balance: ${selectedGroup!.membersBalance?[userData.uid] ?? '0'}"),
            ),
        ],
      ),
    );
  }

// __________________________________________________________________________ //

  Widget _dateTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
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

  Widget _floatingButton(
    UserData userData,
    UserFinanceData userFinanceData,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 10,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 10,
      ),
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isButtonDisabled
            ? null
            : () {
                addTransaction(
                    userData.uid ?? '', userData, ref, userFinanceData);
              },
        child: (isButtonLoading)
            ? CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                "Save Transaction",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  void showAccountSelection(UserFinanceData userFinanceData) {
    // show modal bottom sheet to select payment mode
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        bool isCash =
            _paymentModeController.text == PaymentModes.cash.displayName;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Account",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color3,
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          Navigate().goBack();
                        },
                        icon: Icon(
                          Icons.close,
                          color: color3,
                        )),
                  ],
                ),
                sbh10,
                // bank accounts options
                ...userFinanceData.listOfBankAccounts!.map((bankAccount) {
                  bool isBankAccount = (selectedBank?.bid == bankAccount.bid);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _paymentModeController.text =
                            PaymentModes.bankAccount.displayName;
                        selectedBank = bankAccount;
                        // Clear group selection
                        _groupController.clear();
                        selectedGroup = null;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: (isBankAccount)
                            ? Border(
                                bottom: BorderSide(
                                color: color3,
                                width: 3,
                              ))
                            : null,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                            bottomLeft: (isBankAccount)
                                ? Radius.circular(0)
                                : Radius.circular(10),
                            bottomRight: (isBankAccount)
                                ? Radius.circular(0)
                                : Radius.circular(10),
                          ),
                          border: Border.all(
                            color: color2.withAlpha(150),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // name
                            Wrap(
                              children: [
                                Text(
                                  "Account: ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: (isBankAccount) ? color3 : color1,
                                  ),
                                ),
                                Text(
                                  " ${bankAccount.bankAccountName}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: (isBankAccount) ? color3 : color1,
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
                sbh10,
                // Cash option
                InkWell(
                  onTap: () {
                    setState(() {
                      _paymentModeController.text =
                          PaymentModes.cash.displayName;
                      selectedBank = null;
                      // Clear group selection
                      _groupController.clear();
                      selectedGroup = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: (isCash)
                          ? Border(
                              bottom: BorderSide(
                              color: color3,
                              width: 3,
                            ))
                          : null,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                          bottomLeft: (isCash)
                              ? Radius.circular(0)
                              : Radius.circular(10),
                          bottomRight: (isCash)
                              ? Radius.circular(0)
                              : Radius.circular(10),
                        ),
                        border: Border.all(
                          color: color2.withAlpha(150),
                        ),
                      ),
                      child: Row(
                        spacing: 15,
                        children: [
                          Icon(
                            Icons.wallet,
                            color: (isCash) ? color3 : color1,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cash",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: (isCash) ? color3 : color1,
                                  ),
                                ),
                                Text("Balance: ${userFinanceData.cash?.amount}",
                                    style: TextStyle(
                                      fontSize: 16,
                                    )),
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

// __________________________________________________________________________ //

  void addTransaction(String uid, UserData userData, WidgetRef ref,
      UserFinanceData userFinanceData,
      {bool isTransferSec = false}) async {
    setState(() {
      isButtonDisabled = true;
      isButtonLoading = true;
    });

    // Validate inputs
    final validationError = _validateInputs(userFinanceData, userData);
    if (validationError != null) {
      snackbarToast(
        context: context,
        text: validationError,
        icon: Icons.error,
      );
      _resetButtonState();
      return;
    }

    // Prepare transaction data
    final transactionData = _prepareTransactionData(userData);

    if (transactionData == null) {
      snackbarToast(
        context: context,
        text: "Failed to prepare transaction data.",
        icon: Icons.error,
      );
      _resetButtonState();
      return;
    }

    // Add transaction to user data
    final success =
        await _saveTransaction(uid, transactionData, ref, userFinanceData);

    if (success) {
      snackbarToast(
        context: context,
        text: "Transaction Added ✅",
        icon: Icons.check_circle,
      );
      Navigate().toAndRemoveUntil(BnbPages());
    } else {
      snackbarToast(
        context: context,
        text: "Error adding transaction ❗",
        icon: Icons.error,
      );
    }

    _resetButtonState();
  }

  String? _validateInputs(UserFinanceData userFinanceData, UserData userData) {
    final amountText = _amountController.text.trim();
    final category = _categoryController.text.trim();
    final paymentMode = _paymentModeController.text.trim();
    final group = _groupController.text.trim();

    // Amount validation
    if (amountText.isEmpty) return "Amount cannot be empty.";
    final amount = double.tryParse(amountText);
    if (amount == null) return "Invalid amount entered.";
    if (amount == 0) return "Amount cannot be zero.";

    // Ensure only one of payment mode or group is selected
    if (paymentMode.isNotEmpty && group.isNotEmpty) {
      return "You cannot select both a payment mode and a group.";
    }

    // Payee validation
    if (_payeeController.text.trim().isEmpty) {
      return "Payee cannot be empty.";
    }

    // Payment mode validation
    if (paymentMode.isEmpty && group.isEmpty) {
      return "Please select a payment mode or a group.";
    }

    // Check for sufficient balance in the selected payment mode
    if (paymentMode == "Cash" &&
        !isIncomeSelected &&
        amount > double.parse(userFinanceData.cash?.amount ?? '0')) {
      return "Insufficient cash balance.";
    }

    if (paymentMode == "Bank Account" &&
        !isIncomeSelected &&
        amount > double.parse(selectedBank?.availableBalance ?? '0')) {
      return "Insufficient bank account balance.";
    }

    // Category validation
    if (category.isEmpty) return "Please select a category.";

    // Group validation
    if (group.isNotEmpty) {
      if (selectedGroup == null) {
        return "Invalid group selected.";
      }
      final memberBalance =
          double.parse(selectedGroup!.membersBalance?[userData.uid] ?? '0');
      final groupBalance = double.parse(selectedGroup!.totalAmount ?? '0');
      if (!isIncomeSelected &&
          memberBalance < amount &&
          (selectedGroup?.creatorId != userData.uid)) {
        return "Insufficient member balance in the group.";
      } else if (!isIncomeSelected &&
          (selectedGroup?.creatorId == userData.uid) &&
          groupBalance < amount) {
        return "Insufficient group balance.";
      }
    }

    // Date and time validation
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (selectedDateTime.isAfter(now)) {
      return "Date and time cannot be in the future.";
    }

    return null; // No validation errors
  }

  Transaction? _prepareTransactionData(UserData userData) {
    final amount =
        "${(isIncomeSelected) ? "" : "-"}${_amountController.text.replaceAll('-', '').trim()}";
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();
    final paymentMode = _paymentModeController.text.trim();
    final groupId = selectedGroup?.gid;
    final groupName = selectedGroup?.name;
    final payee = _payeeController.text.trim(); // Added Payee

    return Transaction(
      uid: userData.uid ?? "",
      amount: amount,
      category: category,
      date: _selectedDate,
      time: _selectedTime,
      description: description.isEmpty ? category : description,
      methodOfPayment: paymentMode,
      isGroupTransaction: _groupController.text.isNotEmpty,
      gid: groupId,
      groupName: groupName,
      bankAccountId: selectedBank?.bid,
      bankAccountName: selectedBank?.bankAccountName,
      payee: payee, // Added Payee
      transactionType:
          (isIncomeSelected) ? TransactionType.income.displayName : TransactionType.expense.displayName,
    );
  }

  Future<bool> _saveTransaction(String uid, Transaction transactionData,
      WidgetRef ref, UserFinanceData userFinanceData) async {
    final success = await ref
        .read(userFinanceDataNotifierProvider.notifier)
        .addTransactionToUserData(
          uid: uid,
          transactionData: transactionData,
        );

    if (success) {
      // Update cash balance if payment mode is "Cash"
      if (transactionData.methodOfPayment == "Cash") {
        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateUserCashAmount(
              uid: uid,
              amount: (double.parse(transactionData.amount ?? "0") +
                      (double.parse(userFinanceData.cash!.amount ?? '0')))
                  .toString(),
            );
      }

      // Update bank account balance if payment mode is "Bank Account"
      if (transactionData.methodOfPayment == "Bank Account" &&
          transactionData.bankAccountId != null) {
        final updatedAvailableBalance =
            (double.parse(selectedBank?.availableBalance ?? '0') +
                    double.parse(transactionData.amount ?? "0"))
                .toString();
        final updatedTotalBalance =
            (double.parse(selectedBank?.totalBalance ?? '0') +
                    double.parse(transactionData.amount ?? "0"))
                .toString();
        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateBankAccountBalance(
              uid: transactionData.uid ?? "",
              bankAccountId: transactionData.bankAccountId!,
              availableBalance: updatedAvailableBalance,
              totalBalance: updatedTotalBalance,
            );
      }

      // Update group amount if it's a group transaction
      if (transactionData.isGroupTransaction) {
        final String updatedMemberAmount =
            (double.parse(transactionData.amount ?? "0") +
                    (double.parse(userFinanceData.listOfGroups!
                        .where((group) => group.gid == transactionData.gid)
                        .first
                        .membersBalance![uid]!)))
                .toString();
        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupAmount(
              gid: transactionData.gid ?? '',
              amount: (double.parse(transactionData.amount ?? "0") +
                      (double.parse(userFinanceData.listOfGroups
                              ?.where(
                                  (group) => group.gid == transactionData.gid)
                              .first
                              .totalAmount ??
                          '0')))
                  .toString(),
              uid: uid,
              memberAmount: updatedMemberAmount,
            );
      }
    }

    return success;
  }

  void _resetButtonState() {
    setState(() {
      isButtonDisabled = false;
      isButtonLoading = false;
    });
  }
}

Widget textfield({
  required TextEditingController controller,
  String? hintText,
  String? lableText,
  IconData? prefixIconData,
  IconData? sufixIconData,
  bool isSufixWidget = false,
  Widget? sufixWidget,
  bool readOnly = false,
  void Function()? onTap,
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    onTap: (onTap != null) ? onTap : null,
    keyboardType:
        (lableText == "Amount") ? TextInputType.numberWithOptions() : null,
    decoration: InputDecoration(
      labelText: (lableText != null) ? lableText : null,
      hintText: (hintText != null) ? hintText : null,
      labelStyle: TextStyle(
        color: color1,
      ),
      prefixIcon: (prefixIconData != null)
          ? Icon(
              prefixIconData,
              color: color3,
            )
          : null,
      suffixIcon: (isSufixWidget)
          ? sufixWidget
          : (sufixIconData != null)
              ? Icon(
                  sufixIconData,
                  color: color3,
                  size: 30,
                )
              : null,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: color1),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: color3,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}
