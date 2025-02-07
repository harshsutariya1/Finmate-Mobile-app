import 'package:finmate/Models/user.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/database_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.userData,
    required this.userFinanceData,
    required this.authService,
  });
  final UserData userData;
  final UserFinanceData userFinanceData;
  final AuthService authService;
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add Transaction'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 250,
        child: ElevatedButton(
          onPressed: () {
            addTransaction(
              widget.userData.uid ?? "",
              Transaction(tid: "transactionId"),
            );
          },
          child: const Text("Add Transaction"),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Center(
            child: Text("Scan QR Code"),
          ),
        ],
      ),
    );
  }

  void addTransaction(String uid, Transaction transactionData) async {
    // Add transaction logic here
    final result = await addTransactionToUserData(
        uid: uid, transactionData: transactionData);
    if (result) {
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
  }
}
