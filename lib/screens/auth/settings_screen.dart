import 'package:finmate/screens/auth/auth.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigate().goBack();
          },
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        centerTitle: true,
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () {
              _onTapLogout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: const Text("Settings Screen")),
        ],
      ),
    );
  }

  void _onTapLogout() async {
    if (await widget.authService.logout()) {
      Navigate().push(AuthScreen());
      snackbarToast(
        context: context,
        text: "Logout successful",
        icon: Icons.done_all_outlined,
      );
    } else {
      snackbarToast(
        context: context,
        text: "Error logging out",
        icon: Icons.error_rounded,
      );
    }
  }
}
