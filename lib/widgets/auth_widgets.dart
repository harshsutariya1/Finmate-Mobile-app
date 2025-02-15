import 'package:finmate/constants/assets.dart';
import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';

Widget customTextField({
  required TextEditingController controller,
  required String text,
  bool viewPassword = false,
  required IconData iconData,
  bool passwordField = false,
  void Function()? onTapVisibilityIcon,
}) {
  return Stack(
    children: [
      TextFormField(
        controller: controller,
        obscureText: (passwordField) ? !viewPassword : false,
        decoration: InputDecoration(
          labelText: text,
          labelStyle: TextStyle(
            color: color1,
          ),
          prefixIcon: Icon(
            iconData,
            color: color1,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(
          top: 3,
          right: 5,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: (passwordField)
              ? (viewPassword)
                  ? IconButton(
                      onPressed: onTapVisibilityIcon,
                      icon: Icon(Icons.visibility),
                    )
                  : IconButton(
                      onPressed: onTapVisibilityIcon,
                      icon: Icon(Icons.visibility_off),
                    )
              : null,
        ),
      ),
    ],
  );
}

Widget authButton({
  required String text,
  required void Function() onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: authButtonBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(80, 0, 0, 0),
            offset: Offset(3, 3),
            blurRadius: 5,
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
  );
}

Widget googleButton({
  required void Function() onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(80, 0, 0, 0),
              offset: Offset(3, 3),
              blurRadius: 5,
            )
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          Image.asset(
            googleLogo,
            height: 25,
          ),
          Text(
            "Continue with Google",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    ),
  );
}


