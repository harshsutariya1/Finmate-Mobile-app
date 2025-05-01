import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Transaction%20screens/select_category.dart';
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
      resizeToAvoidBottomInset: true,
      backgroundColor: color4,
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _floatingButton(userData, userFinanceData),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          child: _bodyForm(
            userData: userData,
            userFinanceData: userFinanceData,
          ),
        ),
      ),
    );
  }

  Widget _bodyForm({
    required UserData userData,
    required UserFinanceData userFinanceData,
  }) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type selector and date/time
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction type switcher
                  _buildTransactionTypeSwitcher(),
                  const SizedBox(height: 16),
                  _dateTimePicker(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Amount and basic info
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Basic Details"),
                  const SizedBox(height: 12),
                  _buildAmountField(),
                  const SizedBox(height: 12),
                  textfield(
                    controller: _payeeController,
                    hintText: isIncomeSelected ? "From Payeer" : "To Payee",
                    lableText: isIncomeSelected ? "From Payeer" : "To Payee",
                    prefixIconData: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  textfield(
                    controller: _descriptionController,
                    hintText: "Description",
                    lableText: "Description",
                    prefixIconData: Icons.description_outlined,
                  ),
                  const SizedBox(height: 12),
                  textfield(
                    controller: _categoryController,
                    prefixIconData: Icons.category_rounded,
                    hintText: "Select Category",
                    lableText: "Category",
                    readOnly: true,
                    sufixIconData: Icons.arrow_drop_down_circle_outlined,
                    onTap: _showCategorySelection,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment details
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Payment Details"),
                  const SizedBox(height: 12),
                  textfield(
                    controller: _paymentModeController,
                    prefixIconData: Icons.payments_rounded,
                    hintText: "Select Payment Mode",
                    lableText: "Payment Mode",
                    readOnly: true,
                    sufixIconData: Icons.arrow_drop_down_circle_outlined,
                    onTap: () => showAccountSelection(),
                  ),
                  if (selectedBank != null) _buildBankDetails(),
                  const SizedBox(height: 12),
                  textfield(
                    controller: _groupController,
                    prefixIconData: Icons.group_add_rounded,
                    hintText: "Add Group Transaction",
                    lableText: "Group Transaction",
                    readOnly: true,
                    sufixIconData: Icons.arrow_drop_down_circle_outlined,
                    onTap: () => _showGroupSelection(userFinanceData, userData),
                  ),
                  if (selectedGroup != null) _buildGroupDetails(userData),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSwitcher() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Transaction Type"),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  isSelected: !isIncomeSelected,
                  text: "Expense",
                  icon: Icons.arrow_upward,
                  color: Colors.redAccent,
                  onTap: () => setState(() => isIncomeSelected = false),
                ),
              ),
              Expanded(
                child: _buildTypeButton(
                  isSelected: isIncomeSelected,
                  text: "Income",
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                  onTap: () => setState(() => isIncomeSelected = true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required bool isSelected,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color3,
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color3.withOpacity(0.1),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: Text(
              "₹",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color3,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
              decoration: InputDecoration(
                hintText: "0.00",
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCategorySelection() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.sizeOf(context).height * 0.7,
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color4,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SelectCategory(
            isIncome: isIncomeSelected,
            onTap: (selectedCategory) {
              setState(() {
                _categoryController.text = selectedCategory;
              });
              Navigator.pop(context);
            },
            selectedCategory: _categoryController.text,
          ),
        );
      },
    );
  }

  Widget _buildBankDetails() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color3.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color3.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance, color: color3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedBank?.bankAccountName ?? "Bank Account",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Available: ${selectedBank?.availableBalance ?? '0'} ₹",
                  style: TextStyle(
                    color: color2,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDetails(UserData userData) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color3.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color3.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group, color: color3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedGroup?.name ?? "Group",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Your Balance: ",
                      style: TextStyle(
                        color: color2,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "${selectedGroup?.membersBalance?[userData.uid]?['currentAmount'] ?? '0'} ₹",
                      style: TextStyle(
                        color: color2,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Date & Time"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateTimeField(
                icon: Icons.calendar_today,
                text: "${_selectedDate.toLocal()}".split(' ')[0],
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
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateTimeField(
                icon: Icons.access_time,
                text: _selectedTime.format(context),
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
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color3, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color1,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupSelection(UserFinanceData userFinanceData, UserData userData) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<Group> groupList = userFinanceData.listOfGroups!.toList();
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Group",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color3,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (groupList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No groups available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: groupList.length,
                    itemBuilder: (context, index) {
                      final group = groupList[index];
                      final isYourGroup = group.creatorId == userData.uid;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _groupController.text = group.name.toString();
                              selectedGroup = group;
                              // Clear payment mode selection
                              _paymentModeController.clear();
                              selectedBank = null;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color3.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.group,
                                    color: color3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            group.name.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color1,
                                            ),
                                          ),
                                          if (isYourGroup)
                                            Container(
                                              margin: EdgeInsets.only(left: 8),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color3.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                "Admin",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: color3,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Balance: ${group.membersBalance?[userData.uid]?['currentAmount'] ?? '0'} ₹",
                                        style: TextStyle(
                                          color: color2,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
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

  void showAccountSelection() {
    UserFinanceData userFinanceData =
        ref.read(userFinanceDataNotifierProvider);
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
                                  
                                  // Find the group safely
                                  final Group? foundGroup = userFinanceData.listOfGroups?.where(
                                    (group) => group.gid == key
                                  ).firstOrNull;
                                  
                                  final String groupName = foundGroup?.name ?? "Unknown Group";
                                  
                                  return Row(
                                    spacing: 10,
                                    children: [
                                      Text(
                                        "◗ $groupName:",
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
      
      // Access the currentAmount from the nested map
      final memberBalance =
          double.parse(selectedGroup!.membersBalance?[userData.uid]?['currentAmount'] ?? '0');
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
      transactionType: (isIncomeSelected)
          ? TransactionType.income.displayName
          : TransactionType.expense.displayName,
    );
  }

  Future<bool> _saveTransaction(String uid, Transaction transactionData,
      WidgetRef ref, UserFinanceData userFinanceData) async {
    final success = await ref
        .read(userFinanceDataNotifierProvider.notifier)
        .addTransactionToUserData(
          uid: uid,
          transactionData: transactionData,
          ref: ref,
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
              ref: ref,
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
              ref: ref,
            );
      }

      // Update group amount if it's a group transaction
      if (transactionData.isGroupTransaction) {
        // Access the currentAmount from the nested map
        final String currentMemberAmount = 
            userFinanceData.listOfGroups!
                .where((group) => group.gid == transactionData.gid)
                .first
                .membersBalance?[uid]?['currentAmount'] ?? '0';
        
        final String updatedMemberAmount =
            (double.parse(transactionData.amount ?? "0") +
                    double.parse(currentMemberAmount))
                .toString();
        
        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupAmount(
              gid: transactionData.gid ?? '',
              amount: (double.parse(transactionData.amount ?? "0") +
                      double.parse(userFinanceData.listOfGroups
                              ?.where(
                                  (group) => group.gid == transactionData.gid)
                              .first
                              .totalAmount ??
                          '0'))
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
