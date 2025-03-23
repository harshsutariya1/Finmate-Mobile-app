import 'package:flutter/material.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Cards Screen Content'),
      ),
    );
  }
}
