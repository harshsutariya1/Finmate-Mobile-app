import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddMembers extends ConsumerStatefulWidget {
  const AddMembers({super.key, required this.selectedUsers});
  final List<UserData> selectedUsers;
  @override
  ConsumerState<AddMembers> createState() => _AddMembersState();
}

class _AddMembersState extends ConsumerState<AddMembers> {
  List<UserData> selectedUsers = [];
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, selectedUsers);
          },
          icon: Icon(
            Icons.done,
            color: color3,
            size: 30,
          ),
        ),
        title: Text("Select Members"),
        centerTitle: true,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    final UserData loggedinUser = ref.watch(userDataNotifierProvider);
    final List<UserData>? listOfMembers = ref.watch(allAppUsers).value;
    listOfMembers?.removeWhere((user) => user.uid == loggedinUser.uid);
    final filteredMembers = listOfMembers?.where((user) {
      final lowerCaseQuery = searchQuery.toLowerCase();
      return user.name!.toLowerCase().contains(lowerCaseQuery) ||
          user.email!.toLowerCase().contains(lowerCaseQuery);
    }).toList();

    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search Members',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filteredMembers?.length,
              itemBuilder: (context, index) {
                final UserData? user = filteredMembers?[index];
                final bool isSelected = selectedUsers.contains(user) ||
                    widget.selectedUsers.any(
                        (selectedUser) => selectedUser.email == user?.email);

                return ListTile(
                  leading: userProfilePicInCircle(
                    imageUrl: user?.pfpURL ?? "",
                    innerRadius: 22,
                  ),
                  title: Text(user?.name ?? ''),
                  subtitle: Text(user?.email ?? ''),
                  trailing: (isSelected)
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.check_circle_outline),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedUsers.remove(user);
                      } else {
                        selectedUsers.add(user!);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
