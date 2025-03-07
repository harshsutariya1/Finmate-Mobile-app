import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
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
    final groupMembersData = ref.read(allAppUsers).whenData(
          (value) => value.where(
              (user) => widget.group.memberIds?.contains(user.uid) ?? false),
        );
    return Scaffold(
      backgroundColor: color4,
      body: _body(groupMembersData, userData),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your onPressed code here!
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _body(
      AsyncValue<Iterable<UserData>> groupMembersData, UserData userData) {
    return groupMembersData.when(
      data: (members) {
        return Column(
          children: [
            ...members.map((member) {
              return ListTile(
                leading: userProfilePicInCircle(
                  imageUrl: member.pfpURL.toString(),
                  outerRadius: 23,
                  innerRadius: 21,
                ),
                title: Text(member.name ?? ""),
                subtitle: Text(member.email ?? ""),
                trailing: Text(
                  (member.uid == userData.uid) ? "Admin" : "",
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
      },
      loading: () => CircularProgressIndicator.adaptive(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
