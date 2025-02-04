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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController(text: "harsh@gmail.com");
  final TextEditingController _passwordController =
      TextEditingController(text: "password");
  final TextEditingController _confirmPasswordController =
      TextEditingController(text: "password");
  final TextEditingController _nameController =
      TextEditingController(text: "Harsh");

  bool isSignupLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
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
        title: const Text('SignUp'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 20,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: _onTapSignin,
              child: (isSignupLoading)
                  ? const CircularProgressIndicator()
                  : const Text('SignUp'),
            ),
          ),
          ElevatedButton(
            onPressed: _onTapGoogle,
            child: (isGoogleLoading)
                ? const CircularProgressIndicator()
                : Text("SignIn With Google"),
          ),
        ],
      ),
    );
  }

  void _onTapSignin() async {
    setState(() {
      isSignupLoading = true;
    });
    final result = await _authService.signup(_nameController.text,
        _emailController.text, _passwordController.text, ref);
    if (result == "Success") {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/home",
        (Route<dynamic> route) => false, // This removes all the previous routes
      );
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
    setState(() {
      isSignupLoading = false;
    });
  }

  void _onTapGoogle() async {
    setState(() {
      isGoogleLoading = true;
    });
    _authService.handleGoogleSignIn().then((value) {
      if (value) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/home",
          (Route<dynamic> route) =>
              false, // This removes all the previous routes
        );
        snackbarToast(
            context: context,
            text: "Signin Successfully",
            icon: Icons.done_all_outlined,
          );
      } else {
        snackbarToast(
          context: context,
          text: "Error Signing User",
          icon: Icons.error_rounded,
        );
      }
    });
    setState(() {
      isGoogleLoading = false;
    });
  }
}
