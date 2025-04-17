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
  bool viewPassword = false;

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
      body: Container(
        alignment: Alignment.bottomCenter,
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
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color4,
            borderRadius: BorderRadius.circular(20),
          ),
          child: loginForm(),
        ),
      ),
    );
  }

  Widget loginForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          sbh10,
          Image.asset(
            appLogo,
            height: 100,
          ),
          sbh5,
          Text(
            "Sign In",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          Text(
            'to "Enter The Voult"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          sbh10,
          customTextField(
            controller: _emailController,
            text: "Email Address",
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
          sbh10,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text("Forgot Password?"),
            ),
          ),
          Center(
            child: authButton(
              text: "Sign In",
              onTap: _onTapLogin,
              isloading: isLoginLoading,
            ),
          ),
          sbh5,
          Center(
            child: googleButton(onTap: _onTapGoogle),
          ),
          sbh10,
          bottomText(),
          sbh10,
        ],
      ),
    );
  }

  Widget bottomText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an Account? ",
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
            "Sign Up",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
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

  void _onTapGoogle() async {
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
