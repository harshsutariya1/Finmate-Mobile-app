import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorWhite,
      appBar: AppBar(
        backgroundColor: backgroundColorWhite,
        title: const Text('Analytics'),
      ),
      body: Center(
        child: Text("FinMate App Analytics"),
      ),
    );
  }
}
