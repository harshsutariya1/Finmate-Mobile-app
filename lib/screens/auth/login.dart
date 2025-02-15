import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController(text: "harsh@gmail.com");
  final TextEditingController _passwordController =
      TextEditingController(text: "password");

  bool isLoginLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 20,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: _onTapLogin,
              child: (isLoginLoading)
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _onTapGoogle(ref);
            },
            child: (isGoogleLoading)
                ? const CircularProgressIndicator()
                : Text("Login With Google"),
          ),
        ],
      ),
    );
  }

  void _onTapLogin() async {
    // if (_formKey.currentState!.validate()) {
    setState(() {
      isLoginLoading = true;
    });
    if (await _authService.login(
        _emailController.text, _passwordController.text, ref)) {
      Navigate().toAndRemoveUntil(BnbPages());
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
    setState(() {
      isLoginLoading = false;
    });
    // }
  }

  void _onTapGoogle(WidgetRef ref) async {
    setState(() {
      isGoogleLoading = true;
    });

    _authService.handleGoogleSignIn(ref).then(
      (value) {
        if (value) {
          snackbarToast(
            context: context,
            text: "Login successful",
            icon: Icons.done_all_outlined,
          );
          Navigate().toAndRemoveUntil(BnbPages());
        } else {
          snackbarToast(
            context: context,
            text: "Error logging user",
            icon: Icons.error_rounded,
          );
        }
      },
    );

    setState(() {
      isGoogleLoading = false;
    });
  }
}
