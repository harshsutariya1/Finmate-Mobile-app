import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorWhite,
      appBar: AppBar(
        backgroundColor: backgroundColorWhite,
        title: const Text('Groups'),
      ),
      body: Center(
        child: Text("Groups Screen"),
      ),
    );
  }
}