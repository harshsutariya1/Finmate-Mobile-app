import 'package:finmate/Models/user.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userData,
    required this.authService,
  });
  final UserData userData;
  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        // leading: IconButton(
        //   onPressed: _onTapLogout,
        //   icon: Icon(Icons.logout_outlined),
        // ),
        actions: [
          IconButton(
            onPressed: _onTapLogout,
            icon: Icon(Icons.logout_outlined),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(widget.userData.name ?? "No Name found"),
          Text(widget.userData.email ?? "No Email found"),
          Divider(),
          Center(
            child: Text("FinMate App Home"),
          ),
        ],
      ),
    );
  }

  void _onTapLogout() async {
    if (await widget.authService.logout()) {
      Navigator.pushNamed(context, '/auth');
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
