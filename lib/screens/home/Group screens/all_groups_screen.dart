import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Group%20screens/create_group.dart';
import 'package:finmate/screens/home/Group%20screens/group_overview.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    List<Group> groupsList = List.from(userFinanceData.listOfGroups ?? []);
    // Sort transactions by date and time in descending order
    groupsList.sort((a, b) {
      int dateComparison = b.date!.compareTo(a.date!);
      if (dateComparison != 0) {
        return dateComparison;
      } else {
        return b.time!.format(context).compareTo(a.time!.format(context));
      }
    });

    return Scaffold(
      backgroundColor: color4,
      appBar: _appBar(userData),
      body: _body(userData, userFinanceData, groupsList),
    );
  }

  PreferredSizeWidget _appBar(UserData userData) {
    return AppBar(
      backgroundColor: color4,
      title: const Text('Groups'),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: color1,
        fontSize: 25,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () async {
            Navigate().push(AddGroupDetails());
          },
          icon: (isLoading)
              ? CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(color1),
                )
              : Icon(
                  Icons.add,
                  color: color3,
                  size: 30,
                ),
        ),
        sbw15,
      ],
    );
  }

  Widget _body(
    UserData userData,
    UserFinanceData userFinanceData,
    List<Group> groupsList,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: (groupsList.isEmpty)
          ? Center(
              child: Text("No groups found"),
            )
          : ListView.separated(
              itemCount: groupsList.length,
              itemBuilder: (context, index) {
                return _groupTile(groupsList[index], userData);
              },
              separatorBuilder: (context, index) => sbh15,
            ),
    );
  }

  Widget _groupTile(Group group, UserData userData) {
    final List<UserData>? groupMembers = group.listOfMembers;
    final List<String> memberPfpics =
        groupMembers?.map((member) => member.pfpURL ?? '').toList() ?? [];
    final sortMembersPfpics = memberPfpics.take(5).toList();
    return InkWell(
      onTap: () {
        Navigate().push(GroupOverview(group: group));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: color1.withAlpha(200),
          border: Border.all(color: color1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group Name & Delete Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Group Name
                Text(
                  group.name ?? "Group Name",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                // Delete Button
                (userData.uid == group.creatorId)
                    ? InkWell(
                        onTap: () {
                          showYesNoDialog(
                            context,
                            title: "Delete Group?",
                            contentWidget: SizedBox(),
                            onTapYes: () async {
                              await ref
                                  .read(
                                      userFinanceDataNotifierProvider.notifier)
                                  .deleteGroupProfile(group: group)
                                  .then((value) {
                                if (value) {
                                  snackbarToast(
                                    context: context,
                                    text: "Group deleted successfully!",
                                    icon: Icons.check_circle_outline_rounded,
                                  );
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
                        child: CircleAvatar(
                          backgroundColor: color4,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                        ),
                      )
                    : SizedBox(),
              ],
            ),
            sbh20,
            // Group Amount
            Text(
              "${group.totalAmount ?? 0.0} ₹",
              style: TextStyle(
                color: color4,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            sbh20,
            // Group Members
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    for (var memberPfp in (sortMembersPfpics.reversed))
                      Padding(
                        padding: EdgeInsets.only(
                          right: 30.0 * memberPfpics.indexOf(memberPfp),
                        ),
                        child: userProfilePicInCircle(
                          imageUrl: memberPfp.toString(),
                          outerRadius: 23,
                          innerRadius: 20,
                        ),
                      ),
                    (sortMembersPfpics.length > 4)
                        ? userProfilePicInCircle(
                            outerRadius: 23,
                            innerRadius: 20,
                            isNumber: true,
                            textNumber: "+${sortMembersPfpics.length - 3}",
                          )
                        : SizedBox(),
                  ],
                ),
                IconButton(
                    onPressed: () {
                      snackbarToast(
                          context: context,
                          text: "This functionality is in development!",
                          icon: Icons.developer_mode_rounded);
                    },
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: color3,
                      size: 35,
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
