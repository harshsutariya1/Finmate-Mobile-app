import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:upi_pay/upi_pay.dart';

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
  bool _isProcessing = false;

  // Platform check
  final bool _isAndroid = defaultTargetPlatform == TargetPlatform.android;

  // UPI Apps
  final upiPay = UpiPay();
  List<ApplicationMeta>? _apps;
  bool _loadingApps = true;
  String? _upiError;

  @override
  void initState() {
    super.initState();

    // Only fetch UPI apps on Android
    if (_isAndroid) {
      _fetchUpiApps();
    } else {
      setState(() {
        _loadingApps = false;
        _upiError = "UPI payments are only supported on Android devices";
      });
    }
  }

  Future<void> _fetchUpiApps() async {
    try {
      final apps = await upiPay.getInstalledUpiApplications(
          paymentType: UpiApplicationDiscoveryAppPaymentType.nonMerchant);
      if (mounted) {
        setState(() {
          _apps = apps;
          _loadingApps = false;
        });
      }
    } catch (e) {
      Logger().e("Error fetching UPI apps: $e");
      if (mounted) {
        setState(() {
          _loadingApps = false;
          _upiError = "Could not load UPI apps. Please try again later.";
          _apps = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiIdController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // UPI ID validation regex pattern
  bool _isValidUpiId(String upiId) {
    // Basic UPI ID format: username@provider
    final RegExp upiRegex = RegExp(r'^[a-zA-Z0-9_.]{3,}@[a-zA-Z]{3,}$');
    return upiRegex.hasMatch(upiId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform warning if not Android
                if (!_isAndroid) _buildPlatformWarning(),

                // Form fields section
                _buildFormFields(),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (_isProcessing || !_isAndroid) ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color3,
                      foregroundColor: whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _isProcessing
                        ? CircularProgressIndicator(color: whiteColor)
                        : Text(
                            "Pay Now",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                sbh20,

                // Payment Information
                _buildInformationSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformWarning() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(50),
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

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount Field
        TextFormField(
          controller: _amountController,
          decoration: _buildInputDecoration("Amount (₹)", Icons.currency_rupee),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid amount';
            }
            if (double.parse(value) <= 0) {
              return 'Amount must be greater than zero';
            }
            return null;
          },
        ),
        sbh20,

        // UPI ID Field
        TextFormField(
          controller: _upiIdController,
          decoration:
              _buildInputDecoration("UPI ID", Icons.account_balance_wallet)
                  .copyWith(helperText: "e.g. username@upi"),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a UPI ID';
            }
            if (!_isValidUpiId(value)) {
              return 'Please enter a valid UPI ID';
            }
            return null;
          },
        ),
        sbh20,

        // Note Field (Optional)
        TextFormField(
          controller: _noteController,
          decoration: _buildInputDecoration("Note (Optional)", Icons.note_alt),
          maxLength: 50,
          maxLines: 2,
        ),
        sbh20,
      ],
    );
  }

  Widget _buildInformationSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color2.withAlpha(150)),
        borderRadius: BorderRadius.circular(10),
        color: color2.withAlpha(50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Take Note:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          sbh10,
          _buildInfoText("Transaction is secure and encrypted"),
          _buildInfoText(
              "Money will be deducted from your selected UPI account"),
          _buildInfoText("Transaction might take a few seconds to process"),

          // Show UPI apps status
          if (_isAndroid) ...[
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
            if (_loadingApps)
              _buildInfoText("Loading UPI apps...")
            else if (_upiError != null)
              _buildInfoText("Error: $_upiError", color: Colors.red)
            else if (_apps?.isEmpty ?? true)
              _buildInfoText("No UPI apps found on your device",
                  color: Colors.orange[800])
            else
              _buildInfoText("Found ${_apps!.length} UPI apps on your device",
                  color: Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoText(String text, {Color? color}) {
    return Text(
      "• $text",
      style: TextStyle(color: color ?? color2),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color3, width: 2),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      if (_apps?.isNotEmpty ?? false) {
        await _showUpiApps();
      } else {
        // No UPI apps available
        snackbarToast(
          context: context,
          text: "No UPI apps found on your device.",
          icon: Icons.error_outline,
        );
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showUpiApps() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color4,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select UPI App",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: color1),
                  ),
                ],
              ),
              sbh20,
              Expanded(
                child: ListView.builder(
                  itemCount: _apps?.length ?? 0,
                  itemBuilder: (context, index) {
                    final app = _apps![index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      child: ListTile(
                        leading: app.iconImage(48),
                        title: Text(app.upiApplication.getAppName()),
                        onTap: () => _initiateUpiTransaction(app),
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

  Future<void> _initiateUpiTransaction(ApplicationMeta app) async {
    try {
      final transactionRef = DateTime.now().millisecondsSinceEpoch.toString();

      final UpiTransactionResponse response = await upiPay.initiateTransaction(
        app: app.upiApplication,
        receiverUpiAddress: _upiIdController.text.trim(),
        receiverName: 'Receiver',
        transactionRef: transactionRef,
        amount: _amountController.text.trim(),
        transactionNote: _noteController.text.trim(),
      );

      Logger().i("UPI Response: $response");
      Navigate().goBack; // Close bottom sheet

      // _handleSuccessfulPayment(response.status, transactionRef);
    } catch (e) {
      Logger().e("UPI transaction error: $e");
      Navigator.pop(context); // Close bottom sheet
      snackbarToast(
        context: context,
        text: "Transaction failed: ${e.toString()}",
        icon: Icons.error_outline,
      );
    }
  }

  void _handleSuccessfulPayment(bool responseStatus, String transactionRef) {
    if (!responseStatus) {
      snackbarToast(
        context: context,
        text: "Transaction failed. Please try again.",
        icon: Icons.error_outline,
      );
      return;
    } else {
      // Reset form
      _formKey.currentState!.reset();
      _amountController.clear();
      _upiIdController.clear();
      _noteController.clear();

      // Show success message
      snackbarToast(
        context: context,
        text: "Payment initiated! Transaction reference: $transactionRef",
        icon: Icons.check_circle,
      );
    }
  }
}
