import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupSettings extends ConsumerStatefulWidget {
  const GroupSettings({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends ConsumerState<GroupSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: _appBar(),
      body: _body(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: color4,
      title: Text("Group Settings"),
      centerTitle: true,
    );
  }

  Widget _body() {
    final UserData userData = ref.watch(userDataNotifierProvider);

    return Padding(
      padding: EdgeInsets.all(15),
      child: SingleChildScrollView(
        child: Column(
          children: [
            (userData.uid == widget.group.creatorId)
                ? borderedContainer([
                    settingsTile(
                      iconData: Icons.delete_forever_outlined,
                      text: "Delete Group",
                      isLogoutTile: true,
                      onTap: () {
                        showYesNoDialog(
                          context,
                          title: "Delete Group?",
                          contentWidget: SizedBox(),
                          onTapYes: () async {
                            await ref
                                .read(userFinanceDataNotifierProvider.notifier)
                                .deleteGroupProfile(group: widget.group)
                                .then((value) {
                              if (value) {
                                snackbarToast(
                                  context: context,
                                  text: "Group deleted successfully!",
                                  icon: Icons.check_circle_outline_rounded,
                                );
                                Navigate().goBack();
                                Navigate().goBack();
                                Navigate().goBack();
                              } else {
                                snackbarToast(
                                  context: context,
                                  text: "Failed to delete group!",
                                  icon: Icons.error_outline_rounded,
                                );
                              }
                            });
                          },
                          onTapNo: () {
                            Navigate().goBack();
                          },
                        );
                      },
                    )
                  ])
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
