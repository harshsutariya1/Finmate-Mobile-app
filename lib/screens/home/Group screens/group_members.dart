import 'package:finmate/models/group.dart';
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
    return Scaffold(
      body: Center(
        child: Text('No members yet'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your onPressed code here!
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
