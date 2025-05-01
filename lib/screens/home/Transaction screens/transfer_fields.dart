import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/transaction_category.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class TransferFields extends ConsumerStatefulWidget {
  const TransferFields({super.key});

  @override
  ConsumerState<TransferFields> createState() => _TransferFieldsState();
}

class _TransferFieldsState extends ConsumerState<TransferFields>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController =
      TextEditingController(text: SystemCategory.transfer.displayName);
  final TextEditingController _paymentModeOneController =
      TextEditingController();
  final TextEditingController _paymentModeTwoController =
      TextEditingController();
  final Logger _logger = Logger();

  // Focus nodes
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  BankAccount? selectedBank1;
  BankAccount? selectedBank2;

  // Format for currency display
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  // Button states
  double _animatedButtonWidth = 300;
  bool isButtonDisabled = false;
  bool isButtonLoading = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuad,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _paymentModeOneController.dispose();
    _paymentModeTwoController.dispose();
    _amountFocus.dispose();
    _descriptionFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: color4,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: color4,
          // appBar: _buildAppBar(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _buildSaveButton(userData, userFinanceData),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBody(userData, userFinanceData),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(UserData userData, UserFinanceData userFinanceData) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Transfer amount card
          _buildAmountCard(),

          const SizedBox(height: 20),

          // Date and time section
          _buildDateTimeSection(),

          const SizedBox(height: 20),

          // Description field
          _buildDescriptionCard(),

          const SizedBox(height: 24),

          // Account selection section
          _buildAccountSelectionSection(
            "From",
            true,
            userData,
            userFinanceData,
          ),

          _buildConnectionIndicator(),

          _buildAccountSelectionSection(
            "To",
            false,
            userData,
            userFinanceData,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Amount",
              style: TextStyle(
                color: color2,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            // Simplified amount field
            TextField(
              controller: _amountController,
              focusNode: _amountFocus,
              style: TextStyle(
                color: color1,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "0.00",
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: color3, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee,
                  color: color3,
                  size: 28,
                ),
                suffixIcon: _amountController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _amountController.clear();
                          });
                        },
                        icon: Icon(
                          Icons.cancel,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      )
                    : null,
                contentPadding: EdgeInsets.zero,
              ),
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_descriptionFocus);
              },
              inputFormatters: [
                // Allow only numbers and decimal point
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            if (_amountController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _descriptionController.text.isEmpty
                      ? "Transfer"
                      : _descriptionController.text,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date selection
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: color3,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM').format(_selectedDate),
                            style: TextStyle(
                              color: color1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: color2,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Time selection
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: color3,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: TextStyle(
                              color: color1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: color2,
                        size: 18,
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
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Description",
              style: TextStyle(
                color: color2,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              style: TextStyle(color: color1),
              decoration: InputDecoration(
                hintText: "What's this transfer for?",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon:
                    Icon(Icons.description_outlined, color: color3, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color3, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelectionSection(String title, bool isSource,
      UserData userData, UserFinanceData userFinanceData) {
    final isSelected = isSource
        ? _paymentModeOneController.text.isNotEmpty
        : _paymentModeTwoController.text.isNotEmpty;

    final bankAccount = isSource ? selectedBank1 : selectedBank2;
    final controller =
        isSource ? _paymentModeOneController : _paymentModeTwoController;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSource
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: isSource ? Colors.red : Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: color2,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, size: 12, color: color3),
                    ),
                    onPressed: () => _showPaymentModeSelectionBottomSheet(
                      userData,
                      userFinanceData,
                      isSource,
                    ),
                    tooltip: "Change ${isSource ? 'source' : 'destination'}",
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isSelected)
              // Selection button when nothing is selected
              _buildSelectionButton(
                isSource,
                userData,
                userFinanceData,
              )
            else if (controller.text == PaymentModes.cash.displayName)
              // Cash selection
              _buildCashSelection(userFinanceData.cash?.amount ?? '0')
            else if (controller.text == PaymentModes.bankAccount.displayName &&
                bankAccount != null)
              // Bank account selection
              _buildBankAccountSelection(bankAccount)
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionButton(
    bool isSource,
    UserData userData,
    UserFinanceData userFinanceData,
  ) {
    return InkWell(
      onTap: () => _showPaymentModeSelectionBottomSheet(
        userData,
        userFinanceData,
        isSource,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color3.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color3.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: color3,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Select Account",
              style: TextStyle(
                color: color3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashSelection(String amount) {
    final parsedAmount = double.tryParse(amount) ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color3.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: color3,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cash",
                  style: TextStyle(
                    color: color1,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Available: ${_currencyFormat.format(parsedAmount)}",
                  style: TextStyle(
                    color: color2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountSelection(BankAccount account) {
    final availableBalance =
        double.tryParse(account.availableBalance ?? '0') ?? 0.0;
    final totalBalance = double.tryParse(account.totalBalance ?? '0') ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color3.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              color: color3,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.bankAccountName ?? "Bank Account",
                  style: TextStyle(
                    color: color1,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Available: ${_currencyFormat.format(availableBalance)}",
                  style: TextStyle(
                    color: color2,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Total: ${_currencyFormat.format(totalBalance)}",
                  style: TextStyle(
                    color: color2.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    final bool isComplete = _paymentModeOneController.text.isNotEmpty &&
        _paymentModeTwoController.text.isNotEmpty;

    return Container(
      height: 50,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 2,
            height: 30,
            color: isComplete ? color3 : Colors.grey.shade300,
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isComplete ? color3 : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_vert_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(UserData userData, UserFinanceData userFinanceData) {
    // Determine button state based on form completion
    final bool isFormCompleted = _amountController.text.isNotEmpty &&
        _paymentModeOneController.text.isNotEmpty &&
        _paymentModeTwoController.text.isNotEmpty;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: _animatedButtonWidth,
      height: 60,
      margin: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormCompleted ? color3 : Colors.grey.shade400,
          foregroundColor: Colors.white,
          elevation: isFormCompleted ? 2 : 0,
          shadowColor:
              isFormCompleted ? color3.withOpacity(0.5) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isButtonDisabled || !isFormCompleted
            ? null
            : () => _handleSaveTransaction(userData, userFinanceData),
        child: isButtonLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "Transfer Money",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showPaymentModeSelectionBottomSheet(
    UserData userData,
    UserFinanceData userFinanceData,
    bool isPaymentModeOne,
  ) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color3.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPaymentModeOne
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: isPaymentModeOne ? Colors.red : Colors.green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Select ${isPaymentModeOne ? 'Source' : 'Destination'}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color1,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: color2,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade200),

              // List of account options
              Expanded(
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  children: [
                    // Bank accounts section
                    if (userFinanceData.listOfBankAccounts != null &&
                        userFinanceData.listOfBankAccounts!.isNotEmpty) ...[
                      _buildSectionHeader("Bank Accounts"),
                      ...userFinanceData.listOfBankAccounts!.map((account) {
                        return _buildAccountOption(
                          isPaymentModeOne,
                          account: account,
                          onTap: () {
                            setState(() {
                              if (isPaymentModeOne) {
                                _paymentModeOneController.text =
                                    PaymentModes.bankAccount.displayName;
                                selectedBank1 = account;
                              } else {
                                _paymentModeTwoController.text =
                                    PaymentModes.bankAccount.displayName;
                                selectedBank2 = account;
                              }
                            });
                            Navigator.pop(context);
                          },
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    // Cash option
                    _buildSectionHeader("Cash"),
                    _buildCashOption(
                      isPaymentModeOne,
                      amount: userFinanceData.cash?.amount ?? '0',
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: color2,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildAccountOption(
    bool isSource, {
    required BankAccount account,
    required VoidCallback onTap,
  }) {
    final bool isSelected = isSource
        ? selectedBank1?.bid == account.bid
        : selectedBank2?.bid == account.bid;

    final availableBalance =
        double.tryParse(account.availableBalance ?? '0') ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(color: color3, width: 2)
            : Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color3.withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: isSelected ? color3 : color2,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.bankAccountName ?? "Bank Account",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Available: ${_currencyFormat.format(availableBalance)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: color2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color3,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashOption(
    bool isSource, {
    required String amount,
    required VoidCallback onTap,
  }) {
    final bool isSelected = isSource
        ? _paymentModeOneController.text == PaymentModes.cash.displayName
        : _paymentModeTwoController.text == PaymentModes.cash.displayName;

    final parsedAmount = double.tryParse(amount) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(color: color3, width: 2)
            : Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color3.withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: isSelected ? color3 : color2,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cash",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Available: ${_currencyFormat.format(parsedAmount)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: color2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color3,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showInfoDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: color3),
            const SizedBox(width: 10),
            Text(
              "Transfer Information",
              style: TextStyle(
                color: color1,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "Cash to Bank",
              "Transfer money from your cash to any bank account.",
              Icons.account_balance,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "Bank to Cash",
              "Withdraw money from your bank account to cash.",
              Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "Bank to Bank",
              "Transfer money between your bank accounts.",
              Icons.swap_horiz_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(
                color: color3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color3.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color3,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color1,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: color3,
              onPrimary: Colors.white,
              onSurface: color1,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: color3,
              onPrimary: Colors.white,
              onSurface: color1,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _handleSaveTransaction(
      UserData userData, UserFinanceData userFinanceData) {
    FocusScope.of(context).unfocus();

    // Don't modify the controller text, just animate the button
    setState(() {
      _animatedButtonWidth = 160; // Shrink button during processing
      isButtonDisabled = true;
      isButtonLoading = true;
    });

    addTransaction(userData.uid ?? '', userData, ref, userFinanceData);
  }

  void addTransaction(
    String uid,
    UserData userData,
    WidgetRef ref,
    UserFinanceData userFinanceData,
  ) async {
    try {
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
        setState(() {
          _showConfetti = true;
        });

        _showSnackbar("Transfer completed successfully", Icons.check_circle);

        // Add short delay before navigation for better UX
        await Future.delayed(Duration(milliseconds: 1000));
        Navigate().toAndRemoveUntil(BnbPages());
      } else {
        _showSnackbar("Failed to complete transfer", Icons.error);
        _resetButtonState();
      }
    } catch (e) {
      _logger.e("Error during transfer transaction: $e");
      _showSnackbar("An unexpected error occurred", Icons.error);
      _resetButtonState();
    }
  }

  String? _validateInputs(UserFinanceData userFinanceData) {
    UserData userData = ref.watch(userDataNotifierProvider);
    // Get cleaned amount text without modifying the controller
    final amountText =
        _amountController.text.trim().replaceAll('₹', '').replaceAll(',', '');
    final paymentMode1 = _paymentModeOneController.text.trim();
    final paymentMode2 = _paymentModeTwoController.text.trim();

    // Amount validation
    if (amountText.isEmpty) return "Please enter transfer amount";

    final amount = double.tryParse(amountText);
    if (amount == null) return "Please enter a valid number";
    if (amount <= 0) return "Amount must be greater than zero";

    // Payment mode validation
    if (paymentMode1.isEmpty) return "Please select source account";
    if (paymentMode2.isEmpty) return "Please select destination account";

    // Ensure selected payment modes are not the same entity
    if (paymentMode1 == PaymentModes.cash.displayName &&
        paymentMode2 == PaymentModes.cash.displayName) {
      return "Cannot transfer from cash to cash";
    }

    if (paymentMode1 == PaymentModes.bankAccount.displayName &&
        paymentMode2 == PaymentModes.bankAccount.displayName &&
        selectedBank1?.bid == selectedBank2?.bid) {
      return "Source and destination cannot be the same bank account";
    }

    // Check for sufficient balance in the selected payment mode
    if (paymentMode1 == PaymentModes.cash.displayName) {
      final cashBalance = double.parse(userFinanceData.cash?.amount ?? '0');
      if (amount > cashBalance) {
        return "Insufficient cash balance (${_currencyFormat.format(cashBalance)})";
      }
    }

    if (paymentMode1 == PaymentModes.bankAccount.displayName) {
      final availableBalance =
          double.parse(selectedBank1?.availableBalance ?? '0');
      if (amount > availableBalance) {
        return "Insufficient bank balance (${_currencyFormat.format(availableBalance)})";
      }
    }

    // Date validation
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (selectedDateTime.isAfter(now)) {
      return "Transfer date cannot be in the future";
    }

    return null; // No validation errors
  }

  Transaction? _prepareTransactionData(UserData userData) {
    // Get cleaned amount without modifying the controller
    final amount =
        _amountController.text.trim().replaceAll('₹', '').replaceAll(',', '');
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();
    final paymentMode1 = _paymentModeOneController.text.trim();
    final paymentMode2 = _paymentModeTwoController.text.trim();
    final bankAccountId1 = selectedBank1?.bid;
    final bankAccountName = selectedBank1?.bankAccountName;
    final bankAccountId2 = selectedBank2?.bid;
    final bankAccountName2 = selectedBank2?.bankAccountName;

    final finalDescription = description.isEmpty
        ? "Transfer: ${paymentMode1 == PaymentModes.cash.displayName ? 'Cash' : selectedBank1?.bankAccountName} to ${paymentMode2 == PaymentModes.cash.displayName ? 'Cash' : selectedBank2?.bankAccountName}"
        : description;

    _logger.i(
        "Preparing transaction data: Amount=$amount, From=$paymentMode1, To=$paymentMode2");

    return Transaction(
      uid: userData.uid ?? "",
      amount: amount,
      category: category,
      date: _selectedDate,
      time: _selectedTime,
      description: finalDescription,
      methodOfPayment: paymentMode1,
      methodOfPayment2: paymentMode2,
      isGroupTransaction: false,
      bankAccountId: bankAccountId1,
      bankAccountName: bankAccountName,
      transactionType: TransactionType.transfer.displayName,
      isTransferTransaction: true,
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
    } catch (e) {
      _logger.e("Error in _saveTransaction: $e");
      return false;
    }
  }

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
        await _handleCashToBankTransfer(
          uid: uid,
          bankAccountId: transactionData.bankAccountId2,
          amount: amount,
          ref: ref,
          userFinanceData: userFinanceData,
        );
      } else {
        _logger.w("Unsupported payment mode combination");
      }
    } catch (e) {
      _logger.e("Error in _updateBalances: $e");
      rethrow; // Re-throw to be caught by the caller
    }
  }

  // The following three methods remain unchanged except for better logging
  Future<void> _handleBankToBankTransfer({
    required String uid,
    required String bankAccountId1,
    required String bankAccountId2,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    // ...existing code...
    try {
      final bankAccount1 = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId1);
      final bankAccount2 = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId2);

      if (bankAccount1 == null || bankAccount2 == null) {
        throw Exception("One or both bank accounts not found");
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

      // Update source account
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId1,
            availableBalance: updatedAvailableBalance1,
            totalBalance: updatedTotalBalance1,
            ref: ref,
          );

      // Update destination account
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId2,
            availableBalance: updatedAvailableBalance2,
            totalBalance: updatedTotalBalance2,
            ref: ref,
          );

      _logger.i("Bank to bank transfer completed successfully: $amount ₹");
    } catch (e) {
      _logger.e("Error in bank to bank transfer: $e");
      throw e;
    }
  }

  Future<void> _handleBankToCashTransfer({
    required String uid,
    required String? bankAccountId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    // ...existing code...
    try {
      final bankAccount = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);

      if (bankAccount == null) {
        throw Exception("Bank account not found");
      }

      // Calculate new balances
      final updatedAvailableBalance =
          (double.parse(bankAccount.availableBalance ?? '0') - amount)
              .toString();
      final updatedTotalBalance =
          (double.parse(bankAccount.totalBalance ?? '0') - amount).toString();
      final updatedCashAmount =
          (double.parse(userFinanceData.cash?.amount ?? '0') + amount)
              .toString();

      // Update bank account balance
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId!,
            availableBalance: updatedAvailableBalance,
            totalBalance: updatedTotalBalance,
            ref: ref,
          );

      // Update cash balance
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateUserCashAmount(
            uid: uid,
            amount: updatedCashAmount,
            ref: ref,
          );

      _logger.i("Bank to cash transfer completed successfully: $amount ₹");
    } catch (e) {
      _logger.e("Error in bank to cash transfer: $e");
      throw e;
    }
  }

  Future<void> _handleCashToBankTransfer({
    required String uid,
    required String? bankAccountId,
    required double amount,
    required WidgetRef ref,
    required UserFinanceData userFinanceData,
  }) async {
    // ...existing code...
    try {
      final bankAccount = userFinanceData.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);

      if (bankAccount == null) {
        throw Exception("Bank account not found");
      }

      // Calculate new balances
      final updatedAvailableBalance =
          (double.parse(bankAccount.availableBalance ?? '0') + amount)
              .toString();
      final updatedTotalBalance =
          (double.parse(bankAccount.totalBalance ?? '0') + amount).toString();
      final updatedCashAmount =
          (double.parse(userFinanceData.cash?.amount ?? '0') - amount)
              .toString();

      // Update bank account balance
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateBankAccountBalance(
            uid: uid,
            bankAccountId: bankAccountId!,
            availableBalance: updatedAvailableBalance,
            totalBalance: updatedTotalBalance,
            ref: ref,
          );

      // Update cash balance
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .updateUserCashAmount(
            uid: uid,
            amount: updatedCashAmount,
            ref: ref,
          );

      _logger.i("Cash to bank transfer completed successfully: $amount ₹");
    } catch (e) {
      _logger.e("Error in cash to bank transfer: $e");
      throw e;
    }
  }

  void _showSnackbar(String message, IconData icon) {
    snackbarToast(
      context: context,
      text: message,
      icon: icon,
    );
  }

  void _resetButtonState() {
    setState(() {
      _animatedButtonWidth = 300; // Restore original width
      isButtonDisabled = false;
      isButtonLoading = false;
    });
  }
}
