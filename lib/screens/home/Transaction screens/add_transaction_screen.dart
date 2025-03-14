import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/accounts_screen.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
  });
  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  Group? selectedGroup;
  BankAccount? selectedBank;
  Wallet? selectedWallet;
  final TextEditingController _paymentModeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int indexOfTabbar = 0;
  bool isIncomeSelected = false;
  bool isButtonDisabled = false;
  bool isButtonLoading = false;
  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: color4,
        appBar: _appbar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _floatingButton(userData, userFinanceData),
        body: _body(userFinanceData, userData),
      ),
    );
  }

  PreferredSizeWidget _appbar() {
    return AppBar(
      backgroundColor: color4,
      centerTitle: true,
      title: const Text('Add New Transaction'),
      bottom: TabBar(
        // onTap: (value) => setState(() {
        //   indexOfTabbar = value;
        //   print("index of tabbar: $indexOfTabbar");
        // }),
        tabs: [
          Tab(
            text: "Expense / Income",
          ),
          Tab(
            text: "Transfer",
          ),
        ],
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: color3,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          color: Colors.blueGrey,
        ),
        indicatorColor: color3,
      ),
    );
  }

  Widget _body(UserFinanceData userFinanceData, UserData userData) {
    return TabBarView(
      children: <Widget>[
        _expenceIncomeFields(userFinanceData, userData),
        _transferFields(),
      ],
    );
  }

  Widget _expenceIncomeFields(
      UserFinanceData userFinanceData, UserData userData) {
    return Container(
      padding: EdgeInsets.only(
        top: 30,
        right: 20,
        left: 20,
        bottom: 0,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            _dateTimePicker(),
            _textfield(
              controller: _amountController,
              hintText: "00.00",
              lableText: "Amount",
              prefixIconData: Icons.currency_rupee_sharp,
              isSufixWidget: true,
              sufixWidget: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color3.withAlpha(150),
                      ),
                      child: Row(
                        spacing: 5,
                        children: [
                          Icon(
                            (isIncomeSelected) ? Icons.add : Icons.remove,
                            color: color4,
                          ),
                          Text(
                            (isIncomeSelected) ? "Income" : "Expense",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color4,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () => setState(() {
                        isIncomeSelected = !isIncomeSelected;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            _textfield(
              controller: _descriptionController,
              hintText: "Description",
              lableText: "Description",
              prefixIconData: Icons.description_outlined,
            ),
            _textfield(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Select Category"),
                                  IconButton(
                                    onPressed: () {
                                      snackbarToast(
                                          context: context,
                                          text:
                                              "This Function is in development",
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
                                  if (category == "Balance Adjustment") {
                                    return SizedBox.shrink();
                                  }
                                  return ChoiceChip(
                                    label: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      spacing: 20,
                                      children: [
                                        Icon(
                                          transactionCategoriesAndIcons[
                                              category],
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
            _textfield(
              controller: _paymentModeController,
              prefixIconData: Icons.payments_rounded,
              hintText: "Select Payment Mode",
              lableText: "Payment Mode",
              readOnly: true,
              sufixIconData: Icons.arrow_drop_down_circle_outlined,
              onTap: () {
                // show modal bottom sheet to select payment mode
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
                              selectedBank: selectedBank?.bankAccountName ?? '',
                              onTapBank: (BankAccount bankAccount) {
                                setState(() {
                                  _paymentModeController.text =
                                      (_paymentModeController.text ==
                                              "Bank Account")
                                          ? ""
                                          : "Bank Account";
                                  selectedBank = (_paymentModeController.text ==
                                          "Bank Account")
                                      ? bankAccount
                                      : null;
                                  selectedWallet = null;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            walletsContainer(
                              context: context,
                              userFinanceData: userFinanceData,
                              isSelectable: true,
                              selectedWallet: selectedWallet?.walletName ?? "",
                              onTapWallet: (Wallet wallet) {
                                setState(() {
                                  _paymentModeController.text =
                                      (_paymentModeController.text == "Wallet")
                                          ? ""
                                          : "Wallet";
                                  selectedWallet =
                                      (_paymentModeController.text == "Wallet")
                                          ? wallet
                                          : null;
                                  selectedBank = null;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            cashContainer(
                              isSelectable: true,
                              isSelected: _paymentModeController.text == "Cash",
                              userFinanceData: userFinanceData,
                              onTap: () {
                                setState(() {
                                  _paymentModeController.text =
                                      (_paymentModeController.text == "Cash")
                                          ? ""
                                          : "Cash";
                                  selectedBank = null;
                                  selectedWallet = null;
                                  if (userData.uid !=
                                      selectedGroup?.creatorId) {
                                    _groupController.text =
                                        (_paymentModeController.text.isNotEmpty)
                                            ? ""
                                            : _groupController.text;
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
              },
            ),
            _textfield(
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
                                      if (userData.uid !=
                                          selectedGroup?.creatorId) {
                                        _paymentModeController.text =
                                            groupSelected
                                                ? ""
                                                : _paymentModeController.text;
                                      }
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _transferFields() {
    return Center(
      child: Text("Transfer fields"),
    );
  }

// _______________________________________________________________________ //
// _______________________________________________________________________ //

  Widget _dateTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: [
        Expanded(
          child: _textfield(
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
          child: _textfield(
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

  Widget _textfield({
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
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _floatingButton(UserData userData, UserFinanceData userFinanceData,
      {bool isTransferSec = false}) {
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

// __________________________________________________________________________ //

  void addTransaction(String uid, UserData userData, WidgetRef ref,
      UserFinanceData userFinanceData,
      {bool isTransferSec = false}) async {
    setState(() {
      isButtonDisabled = true;
      isButtonLoading = true;
    });

    // Validate inputs
    final validationError = _validateInputs(userFinanceData);
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

  String? _validateInputs(UserFinanceData userFinanceData) {
    final amountText = _amountController.text.trim();
    final category = _categoryController.text.trim();
    final paymentMode = _paymentModeController.text.trim();

    // Amount validation
    if (amountText.isEmpty) return "Amount cannot be empty.";
    final amount = double.tryParse(amountText);
    if (amount == null) return "Invalid amount entered.";
    if (amount == 0) return "Amount cannot be zero.";

    // Payment mode validation
    if (paymentMode.isEmpty) {
      return "Please select a payment mode.";
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

    if (paymentMode == "Wallet" &&
        !isIncomeSelected &&
        amount > double.parse(selectedWallet?.balance ?? '0')) {
      return "Insufficient wallet balance.";
    }

    // Category validation
    if (category.isEmpty) return "Please select a category.";

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
      type:
          (isIncomeSelected) ? TransactionType.income : TransactionType.expense,
      bankAccountId: selectedBank?.bid,
      walletId: selectedWallet?.wid,
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
        final updatedBalance =
            (double.parse(selectedBank?.availableBalance ?? '0') +
                    double.parse(transactionData.amount ?? "0"))
                .toString();
        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateBankAccountBalance(
              uid: transactionData.uid ?? "",
              bankAccountId: transactionData.bankAccountId!,
              newBalance: updatedBalance,
            );
      }

      // Update wallet balance if payment mode is "Wallet"
      if (transactionData.methodOfPayment == "Wallet" &&
          transactionData.walletId != null) {
        final updatedBalance = (double.parse(selectedWallet?.balance ?? '0') +
                double.parse(transactionData.amount ?? "0"))
            .toString();
        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateWalletBalance(
              uid: transactionData.uid ?? "",
              walletId: transactionData.walletId!,
              newBalance: updatedBalance,
            );
      }

      // Update group amount if it's a group transaction
      if (transactionData.isGroupTransaction) {
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
