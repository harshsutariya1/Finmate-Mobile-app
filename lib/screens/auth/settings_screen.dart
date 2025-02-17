import 'package:finmate/constants/colors.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
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
      appBar: appBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          borderedContainer([
            listTile(
              iconData: Icons.edit_document,
              text: "Edit Personal Information",
            ),
            listTile(
              iconData: Icons.language,
              text: "Language",
              isLanguageTile: true,
            ),
          ]),
        ],
      ),
    );
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      backgroundColor: backgroundColorWhite,
      leading: IconButton(
        onPressed: () {
          Navigate().goBack();
        },
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: color1,
        ),
      ),
      centerTitle: true,
      title: Text(
        'Settings',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color1,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            widget.authService.logoutDilog(context);
          },
          icon: const Icon(
            Icons.logout_rounded,
            color: color1,
          ),
        ),
      ],
    );
  }

  Widget borderedContainer(List<Widget> listOfTiles) {
    return Container(
      margin: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: color2),
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
  }) {
    return ListTile(
      leading: Icon(
        iconData,
        color: color3,
        size: 28,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: color2,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: (isLanguageTile)
          ? Text(
              "English",
              style: TextStyle(
                color: color3,
                fontSize: 15,
              ),
            )
          : null,
    );
  }
}
