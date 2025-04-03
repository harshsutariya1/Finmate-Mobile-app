import 'dart:io';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/services/upi_payment_service.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class UpiPaymentScreen extends StatefulWidget {
  const UpiPaymentScreen({super.key});

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final Logger _logger = Logger();
  final UpiPaymentService _upiService = UpiPaymentService();

  bool _isProcessing = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _upiApps = [];
  String? _error;

  // Platform check
  final bool _isAndroid = Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      _loadUpiApps();
    } else {
      setState(() {
        _isLoading = false;
        _error = "UPI payments are only supported on Android devices";
      });
    }
  }

  Future<void> _loadUpiApps() async {
    try {
      final apps = await _upiService.getUpiApps();
      setState(() {
        _upiApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e("Error loading UPI apps: $e");
      setState(() {
        _isLoading = false;
        _error = "Failed to load UPI apps: $e";
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiIdController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _isValidUpiId(String upiId) {
    final RegExp upiRegex = RegExp(r'^[a-zA-Z0-9_.]{3,}@[a-zA-Z]{3,}$');
    return upiRegex.hasMatch(upiId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isAndroid) _buildPlatformWarning(),
            if (_error != null) _buildErrorMessage(),

            // Form Fields
            _buildAmountField(),
            sbh20,
            _buildUpiIdField(),
            sbh20,
            _buildNoteField(),
            sbh20,

            // Payment Button
            _buildPayButton(),
            sbh20,

            // Information Section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformWarning() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "UPI payments are only supported on Android devices.",
              style: TextStyle(color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: "Amount (₹)",
        prefixIcon: Icon(Icons.currency_rupee),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null || double.parse(value) <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildUpiIdField() {
    return TextFormField(
      controller: _upiIdController,
      decoration: InputDecoration(
        labelText: "UPI ID",
        prefixIcon: Icon(Icons.account_balance_wallet),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        helperText: "e.g. yourname@upi",
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a UPI ID';
        }
        // if (!_isValidUpiId(value)) {
        //   return 'Please enter a valid UPI ID';
        // }
        return null;
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: "Note (Optional)",
        prefixIcon: Icon(Icons.note_alt),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      maxLength: 50,
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color3,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isAndroid && !_isProcessing && _upiApps.isNotEmpty
            ? _showUpiAppSelector
            : null,
        child: _isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "Pay Now",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color2.withAlpha(100)),
        borderRadius: BorderRadius.circular(10),
        color: color2.withAlpha(50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Information:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          sbh10,
          _buildInfoItem("Payment is secure and encrypted"),
          _buildInfoItem("Transaction may take a few seconds to process"),
          _buildInfoItem(
              "You'll receive a confirmation after successful payment"),
          sbh10,
          Divider(),
          sbh10,
          Text(
            "UPI Apps Status:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          sbh10,
          _buildInfoItem(
            _isLoading
                ? "Loading UPI apps..."
                : _upiApps.isEmpty
                    ? "No UPI apps found on your device"
                    : "Found ${_upiApps.length} UPI apps on your device",
            color: _isLoading
                ? Colors.blue
                : _upiApps.isEmpty
                    ? Colors.red
                    : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("•", style: TextStyle(color: color ?? color2, fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color ?? color2),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpiAppSelector() {
    if (_formKey.currentState!.validate()) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select UPI App",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              Divider(),
              sbh10,
              Text(
                "Choose an app to make your payment:",
                style: TextStyle(color: color2),
              ),
              sbh20,
              Expanded(
                child: ListView.builder(
                  itemCount: _upiApps.length,
                  itemBuilder: (context, index) {
                    final app = _upiApps[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.payment),
                        title: Text(app['appName']),
                        onTap: () {
                          Navigator.pop(context);
                          _initiatePayment(app);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _initiatePayment(Map<String, dynamic> app) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _upiService.initiateTransaction(
        appPackageName: app['packageName'],
        receiverUpiId: _upiIdController.text.trim(),
        receiverName: "Payment Receiver", // Change as needed
        transactionNote: _noteController.text.trim(),
        amount: _amountController.text.trim(),
      );

      _handlePaymentResponse(result);
    } catch (e) {
      _logger.e("Payment error: $e");
      snackbarToast(
        context: context,
        text: "Payment failed: $e",
        icon: Icons.error_outline,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _handlePaymentResponse(Map<String, dynamic> response) {
    final bool success = response['success'] == true;
    final String status = response['status'] as String? ?? 'UNKNOWN';

    if (success) {
      // Reset form fields on success
      _formKey.currentState?.reset();
      _amountController.clear();
      _upiIdController.clear();
      _noteController.clear();

      // Show success message
      snackbarToast(
        context: context,
        text: "Payment successful! Status: $status",
        icon: Icons.check_circle,
      );

      // You could save the transaction in your app's database here
      _saveTransaction(response);
    } else {
      String errorMessage = "Payment failed";
      if (status == "USER_CANCELLED") {
        errorMessage = "Payment was cancelled";
      } else if (response['error'] != null) {
        errorMessage = "Payment failed: ${response['error']}";
      }

      snackbarToast(
        context: context,
        text: errorMessage,
        icon: Icons.error_outline,
      );
    }
  }

  void _saveTransaction(Map<String, dynamic> response) {
    // Here you would typically:
    // 1. Create a Transaction object
    // 2. Save it to your database using your existing provider
    // 3. Update any relevant UI

    // Example (pseudocode):
    // final transaction = Transaction(
    //   uid: currentUserData.uid,
    //   amount: _amountController.text,
    //   description: _noteController.text,
    //   category: "UPI Payment",
    //   transactionType: TransactionType.expense.displayName,
    //   methodOfPayment: "UPI",
    //   // Include reference IDs from the response
    //   transactionRefId: response['transactionId'],
    // );

    // ref.read(userFinanceDataNotifierProvider.notifier).addTransactionToUserData(
    //   uid: currentUserData.uid!,
    //   transactionData: transaction,
    // );

    _logger.i("Transaction completed: ${response['rawData']}");
  }
}
