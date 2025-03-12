import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Group%20screens/add_members.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupMembers extends ConsumerStatefulWidget {
  const GroupMembers({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupMembers> createState() => _GroupMembersState();
}

class _GroupMembersState extends ConsumerState<GroupMembers> {
  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    final List<UserData> groupMembersData = widget.group.listOfMembers ?? [];

    return Scaffold(
      backgroundColor: color4,
      body: _body(groupMembersData: groupMembersData, userData: userData),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final List<UserData> selectedMembers = await Navigate()
              .push(AddMembers(selectedUsers: groupMembersData));
          setState(() {
            groupMembersData.addAll(selectedMembers);
          });
          await ref
              .read(userFinanceDataNotifierProvider.notifier)
              .updateGroupMembers(
                  gid: widget.group.gid ?? '',
                  groupMembersList: groupMembersData);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _body({
    List<UserData> groupMembersData = const [],
    required UserData userData,
  }) {
    return Column(
      children: [
        ...groupMembersData.map((member) {
          return ListTile(
            leading: userProfilePicInCircle(
              imageUrl: member.pfpURL.toString(),
              outerRadius: 23,
              innerRadius: 21,
            ),
            title: Text(member.name ?? ""),
            subtitle: Text(member.email ?? ""),
            trailing: Text(
              (member.uid == widget.group.creatorId) ? "Admin" : "",
              style: TextStyle(
                color: color3,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
      ],
    );
  }
}
