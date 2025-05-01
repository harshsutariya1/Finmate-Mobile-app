import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finmate/constants/assets.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/database_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class EditUserDetails extends ConsumerStatefulWidget {
  const EditUserDetails({
    super.key,
    required this.userData,
  });
  final UserData userData;

  @override
  ConsumerState<EditUserDetails> createState() => _EditUserDetailsState();
}

class _EditUserDetailsState extends ConsumerState<EditUserDetails> {
  final _logger = Logger(printer: PrettyPrinter(methodCount: 2));
  
  // State variables
  bool _isEditing = false;
  bool _imageLoading = false;

  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData.name);
    _usernameController = TextEditingController(text: widget.userData.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataNotifierProvider);
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: color1),
          onPressed: () => Navigate().goBack(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildProfileHeader(userData, screenSize),
              const SizedBox(height: 24),
              _buildProfileForm(userData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserData userData, Size screenSize) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color2.withOpacity(0.8), color3.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Profile Image
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _buildProfileImage(userData),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _imageLoading
                      ? Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(color3),
                            ),
                          ),
                        )
                      : _buildEditImageButton(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // User information
            Column(
              children: [
                // Username
                GestureDetector(
                  onTap: () => _showUsernameEditBottomSheet(userData),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userData.userName?.isNotEmpty == true 
                              ? "@${userData.userName}" 
                              : "Add username",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Email
                Text(
                  userData.email ?? "No email",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(UserData userData) {
    return Hero(
      tag: 'profile-${userData.uid}',
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: userData.pfpURL ?? "",
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color3),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Image.asset(
              blankProfileImage,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditImageButton() {
    return GestureDetector(
      onTap: () => _handleImageEdit(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color3,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildProfileForm(UserData userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Text(
            "Personal Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color3,
            ),
          ),
        ),
        
        _buildFormCard(
          title: "Full Name",
          subtitle: userData.name ?? "Add your name",
          icon: Icons.person,
          onEdit: () => _showNameEditDialog(userData),
          controller: _nameController,
        ),
        
        const SizedBox(height: 8),
        
        // You can add more fields here in similar fashion
        // For example: Date of Birth, Gender, etc.
      ],
    );
  }

  Widget _buildFormCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onEdit,
    required TextEditingController controller,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color3.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color3),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color1,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: color3),
          onPressed: onEdit,
        ),
      ),
    );
  }

  void _showUsernameEditBottomSheet(UserData userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Edit Username",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color1,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: color1),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Username field with @ prefix
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: "Enter username",
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            margin: const EdgeInsets.only(right: 8),
                            child: Text(
                              "@",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color3,
                              ),
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: color1,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateUsername(userData);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color3,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNameEditDialog(UserData userData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Edit Full Name",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Enter your name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color3, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(
              fontSize: 16,
              color: color1,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _updateName(userData);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleImageEdit() async {
    setState(() {
      _imageLoading = true;
    });
    
    try {
      final File? imageFile = await getImageFromGallery();
      
      if (imageFile == null) {
        _logger.w("No image selected");
        setState(() {
          _imageLoading = false;
        });
        return;
      }
      
      final UserData userData = ref.read(userDataNotifierProvider);
      final String? imageUrl = await uploadUserPfpic(
        file: imageFile, 
        uid: userData.uid ?? "",
      );
      
      if (imageUrl != null) {
        await ref
            .read(userDataNotifierProvider.notifier)
            .updateCurrentUserData(pfpURL: imageUrl);
        
        _showSuccessMessage("Profile picture updated successfully");
      } else {
        _showErrorMessage("Failed to upload image");
      }
    } catch (e) {
      _logger.e("Error while editing image: $e");
      _showErrorMessage("Error updating profile picture: $e");
    } finally {
      setState(() {
        _imageLoading = false;
      });
    }
  }

  Future<void> _updateUsername(UserData userData) async {
    final String newUsername = _usernameController.text.trim();
    
    if (newUsername.isEmpty) {
      _showErrorMessage("Username cannot be empty");
      return;
    }
    
    setState(() {
      _isEditing = true;
    });
    
    try {
      final bool success = await ref
          .read(userDataNotifierProvider.notifier)
          .updateCurrentUserData(userName: newUsername);
      
      if (success) {
        _showSuccessMessage("Username updated successfully");
      } else {
        _showErrorMessage("Failed to update username");
      }
    } catch (e) {
      _logger.e("Error updating username: $e");
      _showErrorMessage("Error updating username: $e");
    } finally {
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _updateName(UserData userData) async {
    final String newName = _nameController.text.trim();
    
    if (newName.isEmpty) {
      _showErrorMessage("Name cannot be empty");
      return;
    }
    
    setState(() {
      _isEditing = true;
    });
    
    try {
      final bool success = await ref
          .read(userDataNotifierProvider.notifier)
          .updateCurrentUserData(name: newName);
      
      if (success) {
        _showSuccessMessage("Name updated successfully");
      } else {
        _showErrorMessage("Failed to update name");
      }
    } catch (e) {
      _logger.e("Error updating name: $e");
      _showErrorMessage("Error updating name: $e");
    } finally {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    snackbarToast(
      context: context,
      text: message,
      icon: Icons.check_circle_outline,
    );
  }

  void _showErrorMessage(String message) {
    snackbarToast(
      context: context,
      text: message,
      icon: Icons.error_outline,
    );
  }
}
