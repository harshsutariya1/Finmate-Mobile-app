import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/accounts_screen.dart';
import 'package:finmate/screens/auth/edit_user_details.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    return Scaffold(
      backgroundColor: color4,
      appBar: customAppBar("Settings"),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            borderedContainer([
              settingsTile(
                iconData: Icons.edit_document,
                text: "Edit Personal Information",
                onTap: () => Navigate().push(EditUserDetails(
                  userData: userData,
                )),
              ),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              settingsTile(
                iconData: Icons.language,
                text: "Language",
                isLanguageTile: true,
              ),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              settingsTile(
                iconData: Icons.light_mode_rounded,
                text: "App Theme",
                isThemeTile: true,
              ),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              settingsTile(
                iconData: Icons.account_balance_rounded,
                text: "Accounts",
                onTap: () => Navigate().push(AccountsScreen()),
              ),
            ]),
            borderedContainer([
              settingsTile(iconData: Icons.security_rounded, text: "Security"),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              settingsTile(
                  iconData: Icons.help_outline_rounded, text: "Help & Support"),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              settingsTile(iconData: Icons.chat_outlined, text: "Contact Us"),
              Divider(
                indent: 15,
                endIndent: 15,
              ),
              settingsTile(iconData: Icons.policy_outlined, text: "Privacy Policy"),
            ]),
            borderedContainer([
              settingsTile(
                iconData: Icons.logout,
                text: "Logout",
                isLogoutTile: true,
                onTap: () {
                  AuthService().logoutDilog(context, ref);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

 

}
