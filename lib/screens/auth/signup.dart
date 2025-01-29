import 'package:finmate/services/auth_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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
        title: const Text('SignUp'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await _authService.signup(
                "Admin", "admin@gmail.com", "password", ref);
            if (result == "Success") {
              Navigator.pushNamed(context, '/home');
              snackbarToast(
                context: context,
                text: "Signin successful",
                icon: Icons.done_all_outlined,
              );
            } else if (result == "Error") {
              snackbarToast(
                context: context,
                text: "Error signing user",
                icon: Icons.error_rounded,
              );
            } else if (result == "Email already in use") {
              snackbarToast(
                context: context,
                text: "Email already in use, Please Login",
                icon: Icons.error_rounded,
              );
            }
          },
          child: const Text('SignUp'),
        ),
      ),
    );
  }
}
