import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
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
    List<String> memberPfpics = [
      userData.pfpURL.toString(),
      userData.pfpURL.toString(),
      userData.pfpURL.toString(),
      userData.pfpURL.toString(),
    ];

    return Scaffold(
      backgroundColor: color4,
      appBar: _appBar(userData),
      body: _body(userData, userFinanceData, groupsList, memberPfpics),
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
            setState(() {
              isLoading = true;
            });
            await ref
                .read(userFinanceDataNotifierProvider.notifier)
                .createGroupProfile(
                    groupProfile: Group(
                  creatorId: userData.uid,
                  name: "Office Group",
                  description: "Group for Office friends",
                  totalAmount: "2000",
                  memberIds: [if (userData.uid != null) userData.uid!],
                ));
            setState(() {
              isLoading = false;
            });
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
    List<String> memberPfpics,
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
                return _groupTile(groupsList[index], userData, memberPfpics);
              },
              separatorBuilder: (context, index) => sbh15,
            ),
    );
  }

  Widget _groupTile(Group group, UserData userData, List<String> memberPfpics) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: color2,
        border: Border.all(color: color1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.name ?? "Group Name",
                style: TextStyle(
                  color: color4,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                onPressed: () {
                  ref
                      .read(userFinanceDataNotifierProvider.notifier)
                      .deleteGroupProfile(group: group);
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          sbh20,
          Text(
            "${group.totalAmount ?? 0.0} INR",
            style: TextStyle(
              color: color4,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          sbh20,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 100),
                    child: userProfilePicInCircle(
                      imageUrl: userData.pfpURL.toString(),
                      outerRadius: 25,
                      innerRadius: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 75),
                    child: userProfilePicInCircle(
                      imageUrl: userData.pfpURL.toString(),
                      outerRadius: 25,
                      innerRadius: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 50),
                    child: userProfilePicInCircle(
                      imageUrl: userData.pfpURL.toString(),
                      outerRadius: 25,
                      innerRadius: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 25),
                    child: userProfilePicInCircle(
                      imageUrl: userData.pfpURL.toString(),
                      outerRadius: 25,
                      innerRadius: 20,
                    ),
                  ),
                  userProfilePicInCircle(
                    outerRadius: 25,
                    innerRadius: 20,
                    isNumber: true,
                    textNumber: "+3",
                  ),
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
    );
  }
}
