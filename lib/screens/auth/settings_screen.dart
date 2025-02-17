import 'package:finmate/constants/colors.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorWhite,
      appBar: customAppBar("Settings"),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            borderedContainer([
              listTile(
                iconData: Icons.edit_document,
                text: "Edit Personal Information",
              ),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              listTile(
                iconData: Icons.language,
                text: "Language",
                isLanguageTile: true,
              ),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              listTile(
                iconData: Icons.light_mode_rounded,
                text: "App Theme",
                isThemeTile: true,
              ),
            ]),
            borderedContainer([
              listTile(iconData: Icons.security_rounded, text: "Security"),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              listTile(
                  iconData: Icons.help_outline_rounded, text: "Help & Support"),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              listTile(iconData: Icons.chat_outlined, text: "Contact Us"),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              listTile(iconData: Icons.policy_outlined, text: "Privacy Policy"),
            ]),
            borderedContainer([
              listTile(
                iconData: Icons.logout,
                text: "Logout",
                isLogoutTile: true,
                onTap: () {
                  widget.authService.logoutDilog(context);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget borderedContainer(List<Widget> listOfTiles) {
    return Container(
      margin: EdgeInsets.all(15),
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
          ...listOfTiles.map((listTile) => listTile),
        ],
      ),
    );
  }

  Widget listTile({
    required IconData iconData,
    required String text,
    bool isLanguageTile = false,
    bool isThemeTile = false,
    bool isLogoutTile = false,
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
      trailing: (isLanguageTile)
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
}
