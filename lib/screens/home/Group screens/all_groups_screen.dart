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
  final TextEditingController searchController = TextEditingController();
  String searchQuery = ""; // Store the search query

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);

    // Get the list of groups and filter it based on the search query
    final List<Group> groupsList = userFinanceData.listOfGroups ?? [];
    final List<Group> filteredGroupsList = groupsList
        .where((group) =>
            group.name?.toLowerCase().contains(searchQuery.toLowerCase()) ??
            false)
        .toList();

    return Scaffold(
      backgroundColor: color4,
      appBar: _appBar(userData),
      body: _body(userData, filteredGroupsList),
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

  Widget _body(UserData userData, List<Group> filteredGroupsList) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          _searchField(),
          _groupsList(filteredGroupsList, userData),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 30, right: 30),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value; // Update the search query
          });
        },
        decoration: InputDecoration(
          hintText: "Search groups...",
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color3),
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color2),
          ),
          prefixIcon: Icon(Icons.search, color: color3),
        ),
      ),
    );
  }

  Widget _groupsList(List<Group> groupsList, UserData userData) {
    return (groupsList.isEmpty)
        ? Center(
            child: Text(
              "No groups found",
              style: TextStyle(
                color: color3,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : Expanded(
            child: ListView.separated(
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
                Expanded(
                  child: Text(
                    group.name ?? "Group Name",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                sbw10,
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
                _buildMemberAvatars(groupMembers),
                IconButton(
                  onPressed: () {
                    snackbarToast(
                      context: context,
                      text: "This functionality is in development!",
                      icon: Icons.developer_mode_rounded,
                    );
                  },
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: color3,
                    size: 35,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a row of overlapping member avatars
  Widget _buildMemberAvatars(List<UserData>? members) {
    if (members == null || members.isEmpty) {
      return SizedBox(height: 46, width: 46);
    }

    const double avatarSize = 46.0; // Full avatar diameter
    const double overlap = 18.0; // How much each avatar overlaps
    const double maxWidth = 200.0; // Maximum width for avatars row

    // Limit number of visible avatars
    final int maxVisibleAvatars = 4;
    final int totalMembers = members.length;
    final int displayCount = totalMembers > maxVisibleAvatars 
        ? maxVisibleAvatars 
        : totalMembers;

    // Calculate width based on number of avatars
    final double totalWidth = displayCount * (avatarSize - overlap) + overlap*3;
    
    return Container(
      width: totalWidth.clamp(0, maxWidth),
      height: avatarSize,
      decoration: BoxDecoration(
        color: Colors.transparent,
        // border: Border.all(color: color1.withAlpha(200), width: 2),
      ),
      child: Stack(
        children: [
          // Display visible avatars
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // border: Border.all(color: color1.withAlpha(200), width: 2),
                ),
                child: userProfilePicInCircle(
                  imageUrl: members[i].pfpURL ?? '',
                  outerRadius: avatarSize/2 - 2, // Account for border
                  innerRadius: avatarSize/2 - 4,
                ),
              ),
            ),
          
          // Display "+X" indicator if there are more members
          if (totalMembers > maxVisibleAvatars)
            Positioned(
              left: (maxVisibleAvatars - 0.5) * (avatarSize - overlap) +15,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color1.withAlpha(200), width: 2),
                  color: color3,
                ),
                width: avatarSize,
                height: avatarSize,
                child: Center(
                  child: Text(
                    "+${totalMembers - maxVisibleAvatars }",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
