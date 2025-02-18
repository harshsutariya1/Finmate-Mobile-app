import 'package:finmate/constants/assets.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
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

  final TextEditingController _nameController =
      TextEditingController(text: "Harsh Sutariya");
  final TextEditingController _emailController =
      TextEditingController(text: "harsh@gmail.com");
  final TextEditingController _passwordController =
      TextEditingController(text: "password");
  final TextEditingController _confirmPasswordController =
      TextEditingController(text: "password");

  bool isSignupLoading = false;
  bool isGoogleLoading = false;
  bool viewPassword = false;

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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage(backgroundImage),
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 60,
            left: 15,
            right: 15,
            bottom: 20,
          ),
          alignment: Alignment.center,
          height: double.infinity,
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color4,
            borderRadius: BorderRadius.circular(20),
          ),
          child: signupForm(),
        ),
      ),
    );
  }

  Widget signupForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Image.asset(appLogo),
          Text(
            "Join Us",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          Text(
            "Take control of your finances now",
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          sbh10,
          customTextField(
            controller: _nameController,
            text: "Full Name",
            iconData: Icons.person,
          ),
          sbh5,
          customTextField(
            controller: _emailController,
            text: "Email",
            iconData: Icons.email_rounded,
          ),
          sbh5,
          customTextField(
            controller: _passwordController,
            text: "Password",
            passwordField: true,
            viewPassword: viewPassword,
            iconData: Icons.password_rounded,
            onTapVisibilityIcon: () {
              setState(() {
                viewPassword = !viewPassword;
              });
            },
          ),
          sbh5,
          customTextField(
            controller: _confirmPasswordController,
            text: "Confirm Password",
            iconData: Icons.password_rounded,
          ),
          sbh10,
          Center(
            child: authButton(
              text: "SignUp",
              onTap: _onTapSignUp,
            ),
          ),
          sbh5,
          Center(
            child: googleButton(onTap: _onTapGoogle),
          ),
          sbh10,
          bottomText(),
        ],
      ),
    );
  }

  Widget bottomText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an Account? ",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigate().goBack();
          },
          child: Text(
            "Sign In",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  void _onTapSignUp() async {
    setState(() {
      isSignupLoading = true;
    });
    final result = await _authService.signup(_nameController.text,
        _emailController.text, _passwordController.text, ref);
    if (result == "Success") {
      Navigate().toAndRemoveUntil(BnbPages());
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
    _authService.handleGoogleSignIn(ref).then((value) {
      if (value) {
        Navigate().toAndRemoveUntil(BnbPages());
        snackbarToast(
          context: context,
          text: "SignUp Successfully",
          icon: Icons.done_all_outlined,
        );
      } else {
        snackbarToast(
          context: context,
          text: "Error SigningUp User",
          icon: Icons.error_rounded,
        );
      }
    });
    setState(() {
      isGoogleLoading = false;
    });
  }
}
