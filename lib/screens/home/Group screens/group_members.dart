import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Group%20screens/add_members.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/fullscreen_image_viewer.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class GroupMembers extends ConsumerStatefulWidget {
  const GroupMembers({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupMembers> createState() => _GroupMembersState();
}

class _GroupMembersState extends ConsumerState<GroupMembers> {
  bool _isAdminExpanded = false;
  bool _isRemovingMember = false;

  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    final List<UserData> groupMembersData = userFinanceData.listOfGroups!
            .firstWhere((g) => g.gid == widget.group.gid)
            .listOfMembers
            ?.toList() ??
        [];

    // Sort members - admin first, then alphabetical
    final sortedMembers = _getSortedMembers(groupMembersData);
    // Find admin user
    final adminUser = sortedMembers.firstWhere(
      (member) => member.uid == widget.group.creatorId,
      orElse: () => sortedMembers.first,
    );
    // Get regular members (excluding admin)
    final regularMembers = sortedMembers
        .where((member) => member.uid != widget.group.creatorId)
        .toList();

    return Scaffold(
      backgroundColor: color4,
      body: _buildMembersBody(adminUser, regularMembers, userData),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewMembers(groupMembersData),
        backgroundColor: color3,
        tooltip: 'Add Members',
        child: Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  List<UserData> _getSortedMembers(List<UserData> members) {
    final List<UserData> sortedList = List.from(members);
    sortedList.sort((a, b) {
      // Admin first
      if (a.uid == widget.group.creatorId) return -1;
      if (b.uid == widget.group.creatorId) return 1;

      // Then alphabetical by name
      return (a.name ?? '').compareTo(b.name ?? '');
    });
    return sortedList;
  }

  Future<void> _addNewMembers(List<UserData> currentMembers) async {
    try {
      final List<UserData> selectedMembers =
          await Navigate().push(AddMembers(selectedUsers: currentMembers));

      if (selectedMembers.isNotEmpty) {
        setState(() {
          currentMembers.addAll(selectedMembers);
        });

        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .updateGroupMembers(
                gid: widget.group.gid ?? '', groupMembersList: currentMembers);

        snackbarToast(
          context: context,
          text: "Members added successfully",
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      Logger().e("Error adding members: $e");
    }
  }

  Widget _buildMembersBody(
      UserData adminUser, List<UserData> regularMembers, UserData currentUser) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "Group Members (${regularMembers.length + 1})",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color3,
              ),
            ),
          ),

          // Admin section with dropdown containing all members
          _buildAdminSection(adminUser, regularMembers, currentUser),
        ],
      ),
    );
  }

  Widget _buildAdminSection(
      UserData admin, List<UserData> regularMembers, UserData currentUser) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color3.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Admin Card
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Hero(
              tag: 'admin_${admin.uid}',
              child: Stack(
                children: [
                  userProfilePicInCircle(
                    imageUrl: admin.pfpURL ?? '',
                    outerRadius: 28,
                    innerRadius: 26,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: color3,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  admin.name ?? "Group Admin",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 4),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color3.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Admin",
                    style: TextStyle(
                      color: color3,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  admin.email ?? 'No email provided',
                  style: TextStyle(fontSize: 14),
                ),
                if (admin.uid == currentUser.uid)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "This is you",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                  _isAdminExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isAdminExpanded = !_isAdminExpanded;
                });
              },
            ),
          ),

          // Expanded content - Admin powers and members list
          if (_isAdminExpanded)
            Container(
              color: Colors.grey.withOpacity(0.03),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Powers Section
                  Text(
                    "Admin Powers",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color3,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAdminPowerRow(
                    Icons.delete_outline,
                    "Delete group",
                    "Remove this group and all its data",
                  ),
                  _buildAdminPowerRow(
                    Icons.person_remove_outlined,
                    "Remove members",
                    "Remove members from the group",
                  ),
                  _buildAdminPowerRow(
                    Icons.edit_outlined,
                    "Edit group details",
                    "Change group name, description, etc.",
                  ),

                  // Divider between sections
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child:
                        Divider(height: 1, color: Colors.grey.withOpacity(0.3)),
                  ),

                  // Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Group Members",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color3,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "${regularMembers.length + 1} Members",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Admin user card in members list
                  _buildMemberTile(admin, currentUser, isAdmin: true),

                  // Regular members list
                  if (regularMembers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...regularMembers
                        .map((member) => _buildMemberTile(member, currentUser)),
                  ] else ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        "No other members yet",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  // Admin note at bottom
                  const SizedBox(height: 16),
                  admin.uid == currentUser.uid
                      ? Text(
                          "You have admin privileges in this group",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          "Only the admin can perform administration actions",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminPowerRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(UserData member, UserData currentUser,
      {bool isAdmin = false}) {
    final bool isCurrentUser = member.uid == currentUser.uid;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0.5,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: () {
            if (member.pfpURL != null && member.pfpURL!.isNotEmpty) {
              Navigate().push(
                FullScreenImageViewer(
                  imageUrl: member.pfpURL!,
                  heroTag: isAdmin
                      ? 'admin_${member.uid}_list'
                      : 'member_${member.uid}',
                ),
              );
            }
          },
          child: Hero(
            tag: isAdmin ? 'admin_${member.uid}_list' : 'member_${member.uid}',
            child: Stack(
              children: [
                userProfilePicInCircle(
                  imageUrl: member.pfpURL ?? '',
                  outerRadius: 22,
                  innerRadius: 20,
                ),
                if (isAdmin)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: color3,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Icon(
                        Icons.star,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name ?? "Member",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: isAdmin ? 14 : 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isAdmin)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color3.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Admin",
                  style: TextStyle(
                    color: color3,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isCurrentUser)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "You",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          member.email ?? "",
          style: TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: (!isAdmin &&
                widget.group.creatorId == currentUser.uid &&
                !isCurrentUser)
            ? _isRemovingMember
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color3))
                : PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: color2, size: 20),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => <PopupMenuItem<String>>[
                      PopupMenuItem(
                        value: "Remove",
                        child: Row(
                          children: [
                            Icon(Icons.person_remove,
                                color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text("Remove", style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        onTap: () {
                          // Add a small delay to allow the menu to close before showing the dialog
                          Future.delayed(Duration(milliseconds: 100), () {
                            _confirmRemoveMember(member);
                          });
                        },
                      ),
                    ],
                  )
            : null,
      ),
    );
  }

  /// Shows confirmation dialog before removing a member
  void _confirmRemoveMember(UserData member) {
    showYesNoDialog(
      context,
      title: "Remove Member",
      contentWidget: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to remove ${member.name} from this group?",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              "This action cannot be undone.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
      onTapYes: () => _removeMember(member),
      onTapNo: () => Navigate().goBack(),
    );
  }

  /// Removes a member from the group
  Future<void> _removeMember(UserData member) async {
    Navigate().goBack(); // Close the dialog first

    setState(() {
      _isRemovingMember = true;
    });

    try {
      final success = await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .removeGroupMember(
            gid: widget.group.gid ?? "",
            memberUid: member.uid ?? "",
          );

      if (success) {
        snackbarToast(
          context: context,
          text: "${member.name} removed from the group",
          icon: Icons.check_circle_outline,
        );
      } else {
        throw Exception("Failed to remove member");
      }
    } catch (e) {
      snackbarToast(
        context: context,
        text: "Failed to remove member",
        icon: Icons.error_outline,
      );
    } finally {
      setState(() {
        _isRemovingMember = false;
      });
    }
  }
}
