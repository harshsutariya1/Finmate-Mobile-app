import 'package:finmate/constants/assets.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/services/navigation_services.dart';
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
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      // right widget
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
  bool isloading = false,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color1,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(80, 0, 0, 0),
            offset: Offset(3, 3),
            blurRadius: 5,
          )
        ],
      ),
      child: (isloading)
          ? CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Text(
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
  bool isloading = false,
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
          (isloading)
              ? CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Image.asset(
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

PreferredSizeWidget customAppBar(
  String title, {
  bool isEditProfileScreen = false,
}) {
  return AppBar(
    backgroundColor: (isEditProfileScreen) ? Colors.transparent : color4,
    leading: IconButton(
      onPressed: () {
        Navigate().goBack();
      },
      icon: Icon(
        Icons.arrow_back_ios_rounded,
        color: (isEditProfileScreen) ? color4 : color1,
      ),
    ),
    centerTitle: true,
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: (isEditProfileScreen) ? color4 : color1,
      ),
    ),
  );
}

Widget editButton({void Function()? onTap}) {
  return InkWell(
    onTap: onTap ?? () {},
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(83, 158, 158, 158),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(
          Icons.edit_rounded,
          color: color3,
        ),
      ),
    ),
  );
}

Future showYesNoDialog(
  BuildContext context, {
  required String title,
  required Widget contentWidget,
  required void Function() onTapYes,
  required void Function() onTapNo,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog.adaptive(
        title: Text(title),
        content: contentWidget,
        actions: [
          ElevatedButton(
            onPressed: onTapYes,
            child: const Text("Yes"),
          ),
          ElevatedButton(
            onPressed: onTapNo,
            child: const Text("No"),
          ),
        ],
      );
    },
  );
}
