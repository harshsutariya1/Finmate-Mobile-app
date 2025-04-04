import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class UpiPaymentService {
  static const platform = MethodChannel('com.finmate/upi_payment');
  final Logger _logger = Logger();

  /// Get a list of all installed UPI apps on the device
  Future<List<Map<String, dynamic>>> getUpiApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getUpiApps');
      return List<Map<String, dynamic>>.from(
        result.map((app) => Map<String, dynamic>.from(app)),
      );
    } on PlatformException catch (e) {
      _logger.e('Failed to get UPI apps: ${e.message}');
      return [];
    } catch (e) {
      _logger.e('Error getting UPI apps: $e');
      return [];
    }
  }

  /// Initiate a transaction with a specific UPI app
  Future<Map<String, dynamic>> initiateTransaction({
    required String appPackageName,
    required String receiverUpiId,
    required String receiverName,
    required String transactionNote,
    required String amount,
    String? currency,
    String? mode, // Added mode parameter
    String? purpose, // Added purpose parameter
    String? merchantCode, // Added merchant code parameter
  }) async {
    try {
      final Map<String, dynamic> args = {
        'appPackageName': appPackageName,
        'receiverUpiId': receiverUpiId,
        'receiverName': receiverName,
        'transactionNote': transactionNote,
        'amount': amount,
        'currency': currency ?? 'INR',
        'transactionRefId': DateTime.now().millisecondsSinceEpoch.toString(),
        'mode': mode, // Add mode to arguments
        'purpose': purpose, // Add purpose to arguments
        'mc': merchantCode, // Add merchant code to arguments
      };

      _logger.i('Initiating UPI transaction with args: $args');
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('initiateUpiTransaction', args);
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      _logger.e('UPI Payment Error: ${e.message}');
      return {
        'success': false,
        'error': e.message ?? 'Unknown error occurred',
      };
    } catch (e) {
      _logger.e('UPI Payment Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
