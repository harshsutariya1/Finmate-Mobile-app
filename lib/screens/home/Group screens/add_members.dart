import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: color4,
      elevation: 0,
      title: Text(
        "Add Members",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color1,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigate().goBack(),
        icon: Icon(Icons.arrow_back, color: color2),
        tooltip: 'Cancel',
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context, selectedUsers);
          },
          icon: Icon(
            Icons.check_circle_outline,
            color: color3,
            size: 20,
          ),
          label: Text(
            "Done",
            style: TextStyle(
              color: color3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final UserData loggedinUser = ref.watch(userDataNotifierProvider);
    final List<UserData>? listOfMembers = ref.watch(allAppUsers).value;
    
    // Remove current user and already selected users from the list
    final List<UserData> availableMembers = [];
    if (listOfMembers != null) {
      for (var user in listOfMembers) {
        if (user.uid != loggedinUser.uid && 
            !widget.selectedUsers.any((selected) => selected.uid == user.uid)) {
          availableMembers.add(user);
        }
      }
    }
    
    // Filter by search query
    final filteredMembers = availableMembers.where((user) {
      final lowerCaseQuery = searchQuery.toLowerCase();
      return (user.name?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
          (user.email?.toLowerCase().contains(lowerCaseQuery) ?? false);
    }).toList();

    return Column(
      children: [
        _buildSearchField(),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Available Members",
                style: TextStyle(
                  color: color2,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                "${filteredMembers.length} found",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: filteredMembers.isEmpty
              ? _buildEmptyState()
              : _buildMembersList(filteredMembers),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? "No members available" : "No matching members found",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          if (searchQuery.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Try a different search term",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search by name or email',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: color3),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildMembersList(List<UserData> members) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final user = members[index];
        final bool isSelected = selectedUsers.contains(user);
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? color3.withAlpha(100) : Colors.transparent,
              width: 1.5,
            ),
          ),
          color: isSelected ? color3.withAlpha(20) : Colors.white,
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedUsers.remove(user);
                } else {
                  selectedUsers.add(user);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  userProfilePicInCircle(
                    imageUrl: user.pfpURL ?? "",
                    outerRadius: 24,
                    innerRadius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'User',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: color1,
                          ),
                        ),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? color3 : Colors.grey.shade300,
                        width: 2,
                      ),
                      color: isSelected ? color3 : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    if (selectedUsers.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color3,
                shape: BoxShape.circle,
              ),
              child: Text(
                selectedUsers.length.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              "Members selected",
              style: TextStyle(
                color: color1,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selectedUsers);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color3,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text("Add Members"),
            ),
          ],
        ),
      ),
    );
  }
}
