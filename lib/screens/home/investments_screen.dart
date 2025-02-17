import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorWhite,
      appBar: AppBar(
        backgroundColor: backgroundColorWhite,
        title: const Text('Investments'),
      ),
      body: Center(
        child: Text("Investments Screen"),
      ),
    );
  }
}