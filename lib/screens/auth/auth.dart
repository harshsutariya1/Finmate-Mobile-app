import 'package:finmate/constants/assets.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorWhite,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 40,
          children: [
            imageAndText(),
            buttonAndText(),
          ],
        ),
      ),
    );
  }

  Widget imageAndText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 15,
      children: [
        Image.asset(authImage),
        sbh10,
        Text(
          "Financial freedom is not a dream, it’s a plan. Start yours today.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: color1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buttonAndText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 15,
      children: [
        button(
          text: "Sign In",
          ontap: () => Navigator.pushNamed(context, '/login'),
        ),
        button(
          text: "Join Us",
          ontap: () => Navigator.pushNamed(context, '/signup'),
        ),
        sbh10,
        Text(
          "By continuing you agree with our terms & conditions",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget button({
    required String text,
    required void Function() ontap,
  }) {
    return InkWell(
      onTap: ontap,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color2,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
