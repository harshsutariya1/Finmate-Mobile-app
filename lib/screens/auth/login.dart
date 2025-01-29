import 'package:finmate/services/auth_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late AuthService _authService;
  @override
  void initState() {
    _authService = GetIt.instance.get<AuthService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            if (await _authService.login("admin@gmail.com", "password", ref)) {
              Navigator.pushNamed(context, '/home');
              snackbarToast(
                context: context,
                text: "Login successful",
                icon: Icons.done_all_outlined,
              );
            } else {
              snackbarToast(
                context: context,
                text: "Error logging user",
                icon: Icons.error_rounded,
              );
            }
          },
          child: const Text('Login'),
        ),
      ),
    );
  }
}
