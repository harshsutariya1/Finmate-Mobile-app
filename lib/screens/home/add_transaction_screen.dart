import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/accounts_screen.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/database_services.dart';
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
  final TextEditingController _paymentModeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int indexOfTabbar = 0;
  bool isCashSelected = false;
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
        backgroundColor: color4,
        appBar: _appbar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _floatingButton(userData, userFinanceData),
        body: _body(userFinanceData),
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
            text: "Expence / Income",
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

  Widget _body(UserFinanceData userFinanceData) {
    return TabBarView(
      children: <Widget>[
        _expenceIncomeFields(userFinanceData),
        _transferFields(),
      ],
    );
  }

  Widget _expenceIncomeFields(UserFinanceData userFinanceData) {
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
                        // height: 500,
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        child: Wrap(
                          spacing: 8.0,
                          children: categoryList.map((category) {
                            return ChoiceChip(
                              label: Text(category),
                              selected: _categoryController.text == category,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          bankAccountContainer(
                            context: context,
                            userFinanceData: userFinanceData,
                            isSelectable: true,
                            onTap: () {},
                          ),
                          walletsContainer(
                            context: context,
                            userFinanceData: userFinanceData,
                            isSelectable: true,
                            onTap: () {},
                          ),
                          cashContainer(
                            isSelectable: true,
                            isSelected: isCashSelected,
                            userFinanceData: userFinanceData,
                            onTap: () {
                              setState(() {
                                isCashSelected = !isCashSelected;
                                _paymentModeController.text =
                                    (isCashSelected) ? "Cash" : "";
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
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
        suffixIcon: (sufixIconData != null)
            ? Icon(
                sufixIconData,
                color: color3,
                size: 30,
              )
            : null,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color1),
          borderRadius: BorderRadius.circular(15),
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

  Widget _floatingButton(UserData userData, UserFinanceData userFinanceData) {
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
                setState(() {
                  isButtonDisabled = true;
                  isButtonLoading = true;
                });
                final amount = _amountController.text;
                final date = _selectedDate;
                final time = _selectedTime;
                final description = _descriptionController.text;
                final category = _categoryController.text;
                final paymentMode = _paymentModeController.text;
                if (indexOfTabbar == 0) {
                  // Expence / Income
                  if (amount.isEmpty ||
                      category.isEmpty ||
                      paymentMode.isEmpty) {
                    snackbarToast(
                      context: context,
                      text: "Please fill all the fields",
                      icon: Icons.error,
                    );
                    setState(() {
                      isButtonDisabled = false;
                      isButtonLoading = false;
                    });
                    return;
                  } else if (double.parse(amount) == 0) {
                    snackbarToast(
                      context: context,
                      text: "Amount can't be zero",
                      icon: Icons.error,
                    );
                    setState(() {
                      isButtonDisabled = false;
                      isButtonLoading = false;
                    });
                  } else if (double.parse(amount) < 0 &&
                      paymentMode == "Cash" &&
                      double.parse(amount).abs() >
                          (double.parse(userFinanceData.cash!.amount ?? '0'))) {
                    snackbarToast(
                      context: context,
                      text: "Insufficient cash balance",
                      icon: Icons.error,
                    );
                    setState(() {
                      isButtonDisabled = false;
                      isButtonLoading = false;
                    });
                  } else {
                    addTransaction(
                      userData.uid ?? '',
                      Transaction(
                        uid: userData.uid ?? "",
                        amount: amount,
                        category: category,
                        date: date,
                        time: time,
                        description: description,
                        methodOfPayment: paymentMode,
                        type: (double.parse(amount) < 0)
                            ? TransactionType.expense
                            : TransactionType.income,
                      ),
                      ref,
                      userFinanceData,
                    );
                  }
                } else {
                  // Transfer fields
                }
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

  void addTransaction(
    String uid,
    Transaction transactionData,
    WidgetRef ref,
    UserFinanceData userFinanceData,
  ) async {
    await addTransactionToUserData(
      uid: uid,
      transactionData: transactionData,
      ref: ref,
    ).then((value) {
      String paymentMode = transactionData.methodOfPayment ?? "Cash";
      if (paymentMode == "Cash") {
        ref.read(userFinanceDataNotifierProvider.notifier).updateCashAmount(
            uid: uid,
            amount: (double.parse(transactionData.amount ?? "0") +
                    (double.parse(userFinanceData.cash!.amount ?? '0')))
                .toString());
      }
      if (value) {
        snackbarToast(
          context: context,
          text: "Transaction Added",
          icon: Icons.check_circle,
        );
        Navigate().toAndRemoveUntil(BnbPages());
      } else {
        snackbarToast(
          context: context,
          text: "Error adding transaction",
          icon: Icons.error,
        );
      }
    });
    setState(() {
      isButtonDisabled = false;
      isButtonLoading = false;
    });
  }
}
