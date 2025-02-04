import 'package:flutter/material.dart';

class ScaningScreen extends StatefulWidget {
  const ScaningScreen({super.key});

  @override
  State<ScaningScreen> createState() => _ScaningScreenState();
}

class _ScaningScreenState extends State<ScaningScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
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
}
