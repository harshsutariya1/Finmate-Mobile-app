import 'dart:io';

import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/services/upi_payment_service.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final UpiPaymentService _upiService = UpiPaymentService();
  final Logger _logger = Logger();

  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _error;
  List<Map<String, dynamic>> _upiApps = [];
  bool _appsLoaded = false;

  Map<String, String> _upiData = {};

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _loadUpiApps();
    } else {
      setState(() {
        _error = "UPI QR scanning only supported on Android";
      });
    }
  }

  Future<void> _loadUpiApps() async {
    try {
      final apps = await _upiService.getUpiApps();
      if (mounted) {
        setState(() {
          _upiApps = apps;
          _appsLoaded = true;
        });
      }
    } catch (e) {
      _logger.e("Error loading UPI apps: $e");
      if (mounted) {
        setState(() {
          _error = "Failed to load UPI apps";
          _appsLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              _scannerController.torchEnabled ? Icons.flash_on : Icons.flash_on,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {});
            },
            color: whiteColor,
          ),
          IconButton(
            icon: Icon(
              _scannerController.facing == CameraFacing.front
                  ? Icons.camera_front
                  : Icons.camera_rear,
            ),
            onPressed: () => _scannerController.switchCamera(),
            color: whiteColor,
          ),
        ],
      ),
      body: _error != null ? _buildErrorView() : _buildScannerView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 70, color: Colors.red),
            SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: color1,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _hasScanned = false;
                });
                _loadUpiApps();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color2.withAlpha(50),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Retry",
                style: TextStyle(
                  color: whiteColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQRDetect,
        ),

        // Scanner overlay
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: color3, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Bottom instructions
        Positioned(
          left: 0,
          right: 0,
          bottom: 30,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Align the UPI QR code within the frame to scan",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Processing indicator
        if (_isProcessing)
          Container(
            color: Colors.black45,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: color3),
                    SizedBox(height: 20),
                    Text(
                      "Processing QR code...",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onQRDetect(BarcodeCapture capture) async {
    if (_hasScanned || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrCode = barcodes.first.rawValue;
    Logger().i("QR Code: $qrCode");
    if (qrCode == null) return;

    _hasScanned = true;
    setState(() => _isProcessing = true);

    try {
      // Pause scanner
      await _scannerController.stop();

      // Parse UPI data from QR code
      final result = _parseUpiQRCode(qrCode);

      if (result == null) {
        setState(() {
          _isProcessing = false;
          _hasScanned = false;
          _error = "Invalid UPI QR code";
        });
        await _scannerController.start();
        // snackbarToast(
        //   context: context,
        //   text: "Invalid UPI QR code format",
        //   icon: Icons.error_outline,
        // );
        return;
      }

      // Show app selector for payment
      setState(() {
        _isProcessing = false;
        _upiData = result;
      });

      _showUpiAppSelector();
    } catch (e) {
      _logger.e("Error processing QR code: $e");
      setState(() {
        _isProcessing = false;
        _hasScanned = false;
      });
      await _scannerController.start();
      snackbarToast(
        context: context,
        text: "Error processing QR code: $e",
        icon: Icons.error_outline,
      );
    }
  }

  Map<String, String>? _parseUpiQRCode(String qrData) {
    // Check if it's a UPI QR code
    if (!qrData.toLowerCase().startsWith('upi://')) {
      return null;
    }
    Logger().i("QR Data: $qrData");
    // upi://pay?pa=harsh77471@slc&am=&pn=Mr%20HARSH%20RANCHHODBHAI%20SUTARIYA&mc=0000&mode=02&purpose=00

    try {
      final uri = Uri.parse(qrData);
      final Map<String, String> result = {};

      // Required parameters
      result['pa'] = uri.queryParameters['pa'] ?? ''; // Payee Address (UPI ID)
      result['pn'] = uri.queryParameters['pn'] ?? ''; // Payee Name
      result['am'] = uri.queryParameters['am'] ?? ''; // Amount

      // Additional parameters
      result['tn'] = uri.queryParameters['tn'] ?? ''; // Transaction note
      result['cu'] = uri.queryParameters['cu'] ?? 'INR'; // Currency
      result['mc'] = uri.queryParameters['mc'] ?? ''; // Merchant code
      result['mode'] = uri.queryParameters['mode'] ?? ''; // Transaction mode
      result['purpose'] = uri.queryParameters['purpose'] ?? ''; // Purpose code

      return result;
    } catch (e) {
      _logger.e("Error parsing UPI QR code: $e");
      return null;
    }
  }

  void _showUpiAppSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Payment Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetScanner();
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              Divider(),
              sbh10,

              // Display payment details
              _buildPaymentDetails(),
              sbh20,

              Text(
                "Select Payment App",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
              ),
              sbh10,

              // UPI apps list
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
        );
      }),
    );
  }

  Widget _buildPaymentDetails() {
    final TextEditingController amountController = TextEditingController(
      text: _upiData['am'] ?? '',
    );

    return Column(
      children: [
        // Payee information
        ListTile(
          title: Text("Paying to"),
          subtitle: Text(_upiData['pn'] ?? 'Unknown Merchant'),
          leading: CircleAvatar(
            backgroundColor: color2.withAlpha(50),
            child: Icon(Icons.store),
          ),
        ),
        Divider(),

        // UPI ID
        ListTile(
          title: Text("UPI ID"),
          subtitle: Text(_upiData['pa'] ?? ''),
          dense: true,
        ),

        // Amount field (editable if not provided in QR)
        if (_upiData['am']?.isEmpty != false)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: "Amount (₹)",
                labelStyle: TextStyle(color: color1),
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              // inputFormatters: [
              //   FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              // ],
              onChanged: (value) {
                _upiData['am'] = value;
              },
            ),
          )
        else
          ListTile(
            title: Text("Amount"),
            subtitle: Text("₹${_upiData['am']}"),
            dense: true,
          ),

        // Note
        if (_upiData['tn']?.isNotEmpty == true)
          ListTile(
            title: Text("Note"),
            subtitle: Text(_upiData['tn']!),
            dense: true,
          ),
      ],
    );
  }

  Future<void> _initiatePayment(Map<String, dynamic> app) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Verify we have all required information
      if (_upiData['pa']?.isEmpty == true) {
        throw Exception("Invalid UPI ID");
      }

      if (_upiData['am']?.isEmpty == true) {
        throw Exception("Amount is required");
      }

      final result = await _upiService.initiateTransaction(
        appPackageName: app['packageName'],
        receiverUpiId: _upiData['pa']!,
        receiverName: _upiData['pn'] ?? 'Payment Recipient',
        transactionNote: _upiData['tn'] ?? 'QR Code Payment',
        amount: _upiData['am']!,
        currency: _upiData['cu'],
        // Add the new parameters
        mode: _upiData['mode'],
        purpose: _upiData['purpose'],
        merchantCode: _upiData['mc'],
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
      _resetScanner();
    }
  }

  void _handlePaymentResponse(Map<String, dynamic> response) {
    final bool success = response['success'] == true;
    final String status = response['status'] as String? ?? 'UNKNOWN';

    if (success) {
      // Show success message
      snackbarToast(
        context: context,
        text: "Payment successful! Status: $status",
        icon: Icons.check_circle,
      );

      // You could save the transaction in your app's database here
      _saveTransaction(response);

      // Navigate back after successful payment
      Navigate().goBack();
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
    // Here you would save the transaction in your app's database
    // Similar to your UpiPaymentScreen implementation
    _logger.i("Transaction completed: ${response['rawData']}");
  }

  void _resetScanner() async {
    setState(() {
      _hasScanned = false;
    });
    await _scannerController.start();
  }
}
