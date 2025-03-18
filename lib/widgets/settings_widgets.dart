import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';

Widget borderedContainer(
  List<Widget> listOfWidgets, {
  EdgeInsetsGeometry? customMargin,
  EdgeInsetsGeometry? customPadding,
}) {
  return Container(
    margin: customMargin ?? EdgeInsets.all(15),
    padding: customPadding,
    decoration: BoxDecoration(
      border: Border.all(
        color: const Color.fromARGB(50, 57, 62, 70),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...listOfWidgets.map((listTile) => listTile),
      ],
    ),
  );
}

Widget settingsTile({
  required IconData iconData,
  required String text,
  bool isLanguageTile = false,
  bool isThemeTile = false,
  bool isLogoutTile = false,
  bool isSufixIcon = false,
  IconData? sufixIcon,
  void Function()? onSufixTap,
  void Function()? onTap,
}) {
  return ListTile(
    leading: Icon(
      iconData,
      color: (isLogoutTile) ? const Color.fromARGB(255, 188, 58, 58) : color3,
      size: 28,
    ),
    title: Text(
      text,
      style: TextStyle(
        color: color2,
        fontWeight: (isLogoutTile) ? FontWeight.bold : null,
      ),
    ),
    trailing: (isSufixIcon)
        ? IconButton(
            icon: Icon(sufixIcon),
            color: color3,
            onPressed: onSufixTap,
          )
        : (isLanguageTile)
            ? trailingText("English")
            : (isThemeTile)
                ? trailingText("Light Mode")
                : null,
    onTap: onTap ?? () {},
  );
}

Widget trailingText(String text) {
  return Text(
    text,
    style: TextStyle(
      color: color3,
      fontSize: 15,
    ),
  );
}
