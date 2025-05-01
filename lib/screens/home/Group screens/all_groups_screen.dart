import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Group%20screens/add_members.dart';
import 'package:finmate/screens/home/Group%20screens/create_group.dart';
import 'package:finmate/screens/home/Group%20screens/group_overview.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

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
      body: RefreshIndicator.adaptive(
        child: _body(userData, filteredGroupsList),
        onRefresh: () async {
          await ref
              .read(userFinanceDataNotifierProvider.notifier)
              .refetchAllGroupData(userData.uid!);
          userFinanceData.listOfGroups?.map((group){
            Logger().i(group.name);
          });
        },
      ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: searchController,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          style: TextStyle(
            color: color1,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: "Search groups...",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search_rounded,
                color: color3,
                size: 22,
              ),
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                      FocusScope.of(context).unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.cancel,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: color3.withAlpha(100),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupsList(List<Group> groupsList, UserData userData) {
    return (groupsList.isEmpty)
        ? _buildEmptyGroupsState()
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

  Widget _buildEmptyGroupsState() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with background
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color3.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_rounded,
                    size: 60,
                    color: color3,
                  ),
                ),
                const SizedBox(height: 24),

                // Main title
                Text(
                  searchQuery.isNotEmpty
                      ? "No matching groups"
                      : "No groups yet",
                  style: TextStyle(
                    color: color1,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Description text
                Text(
                  searchQuery.isNotEmpty
                      ? "We couldn't find any groups matching '$searchQuery'"
                      : "Create your first group to start tracking expenses with friends and family",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Create group button
                if (searchQuery.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () => Navigate().push(AddGroupDetails()),
                    icon: Icon(Icons.add_circle_outline, color: Colors.white),
                    label: Text(
                      "Create a Group",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color3,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                // Clear search button
                if (searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                    icon: Icon(Icons.search_off, color: color3),
                    label: Text(
                      "Clear Search",
                      style: TextStyle(
                        color: color3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupTile(Group group, UserData userData) {
    final List<UserData>? groupMembers = group.listOfMembers;
    final bool isCreator = userData.uid == group.creatorId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      elevation: 3,
      shadowColor: color1.withAlpha(77), // Changed from withOpacity(0.3)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigate().push(GroupOverview(group: group)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color1.withAlpha(230), // Changed from withOpacity(0.9)
                color1.withAlpha(179), // Changed from withOpacity(0.7)
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with name and delete button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
                child: Row(
                  children: [
                    // Group icon with indicator
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withAlpha(51), // Changed from withOpacity(0.2)
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.group_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Group name with admin badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  group.name ?? "Group Name",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCreator)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color4.withAlpha(
                                        77), // Changed from withOpacity(0.3)
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            "${groupMembers?.length ?? 0} members",
                            style: TextStyle(
                              color: Colors.white.withAlpha(
                                  179), // Changed from withOpacity(0.7)
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delete button (if creator)
                    if (isCreator)
                      InkWell(
                        onTap: () => _showDeleteDialog(context, group),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withAlpha(51), // Changed from withOpacity(0.2)
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white
                    .withAlpha(38), // Changed from withOpacity(0.15)
              ),

              // Amount section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Balance",
                            style: TextStyle(
                              color: Colors.white.withAlpha(
                                  179), // Changed from withOpacity(0.7)
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${group.totalAmount ?? 0.0} ₹",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color4
                            .withAlpha(77), // Changed from withOpacity(0.3)
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            group.date != null
                                ? "${group.date!.day}/${group.date!.month}/${group.date!.year}"
                                : "Created Today",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Members section
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMemberAvatars(groupMembers),
                    if (isCreator)
                      Material(
                        color: color3,
                        borderRadius: BorderRadius.circular(50),
                        child: InkWell(
                          onTap: () {
                            _addNewMembers(group);
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.person_add_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addNewMembers(Group group) async {
    try {
      final currentMembers = group.listOfMembers ?? [];
      final List<UserData> selectedMembers =
          await Navigate().push(AddMembers(selectedUsers: currentMembers));

      if (selectedMembers.isNotEmpty) {
        currentMembers.addAll(selectedMembers);

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupMembers(
                gid: group.gid ?? '', groupMembersList: currentMembers);

        successToast(context: context, text: "Members added successfully");
      }
    } catch (e) {
      Logger().e("Error adding members: $e");
    }
  }

  /// Shows delete confirmation dialog
  void _showDeleteDialog(BuildContext context, Group group) {
    showYesNoDialog(
      context,
      title: "Delete Group?",
      contentWidget: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          "Are you sure you want to delete '${group.name}'? This action cannot be undone.",
          style: TextStyle(fontSize: 15),
        ),
      ),
      onTapYes: () async {
        Navigator.pop(context); // Close dialog

        setState(() {
          isLoading = true;
        });

        final success = await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .deleteGroupProfile(group: group);

        setState(() {
          isLoading = false;
        });

        if (success) {
          snackbarToast(
            context: context,
            text: "Group deleted successfully!",
            icon: Icons.check_circle_outline_rounded,
          );
        } else {
          snackbarToast(
            context: context,
            text: "Failed to delete group!",
            icon: Icons.error_outline_rounded,
          );
        }
      },
      onTapNo: () => Navigator.pop(context),
    );
  }

  /// Builds a row of overlapping member avatars
  Widget _buildMemberAvatars(List<UserData>? members) {
    if (members == null || members.isEmpty) {
      return const SizedBox(height: 35, width: 35);
    }

    const double avatarSize = 35.0; // Full avatar diameter
    const double overlap = 14.0; // How much each avatar overlaps
    const double maxWidth = 200.0; // Maximum width for avatars row

    // Limit number of visible avatars
    final int maxVisibleAvatars = 4;
    final int totalMembers = members.length;
    final int displayCount =
        totalMembers > maxVisibleAvatars ? maxVisibleAvatars : totalMembers;

    // Calculate width based on number of avatars
    final double totalWidth =
        displayCount * (avatarSize - overlap) + overlap * 3;

    return SizedBox(
      width: totalWidth.clamp(0, maxWidth),
      height: avatarSize,
      child: Stack(
        children: [
          // Display visible avatars
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color1, width: 2),
                ),
                child: userProfilePicInCircle(
                  imageUrl: members[i].pfpURL ?? '',
                  outerRadius: avatarSize / 2 - 2,
                  innerRadius: avatarSize / 2 - 4,
                ),
              ),
            ),

          // Display "+X" indicator if there are more members
          if (totalMembers > maxVisibleAvatars)
            Positioned(
              left: displayCount * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color1, width: 2),
                  color: color3,
                ),
                child: Center(
                  child: Text(
                    "+${totalMembers - maxVisibleAvatars}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
