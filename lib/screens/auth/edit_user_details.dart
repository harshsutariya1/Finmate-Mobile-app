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
  var logger = Logger(
    printer: PrettyPrinter(methodCount: 2),
  );
  bool isEditing = false;
  bool imageLoader = false;

  late TextEditingController _nameController;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData.name);
    _usernameController = TextEditingController(text: widget.userData.userName);
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = ref.watch(userDataNotifierProvider);
    return Scaffold(
      backgroundColor: color4,
      extendBodyBehindAppBar: true,
      appBar: customAppBar("Edit Profile", isEditProfileScreen: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 20,
        children: [
          editImageAndUserName(userData),
          editDetailsForm(userData),
        ],
      ),
    );
  }

  Widget editImageAndUserName(UserData userData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 260,
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 55),
              decoration: BoxDecoration(
                color: color2,
                border: Border.all(),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                  bottomLeft: Radius.elliptical(200, 150),
                  bottomRight: Radius.elliptical(200, 150),
                ),
              ),
            ),
            Align(
              // Image Picker
              alignment: Alignment.bottomCenter,
              child: CircleAvatar(
                backgroundColor: color1,
                radius: 63,
                child: CachedNetworkImage(
                  imageUrl: userData.pfpURL.toString(),
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 60,
                    backgroundImage: imageProvider,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FloatingActionButton.small(
                        onPressed: () {
                          onTapEditImage(userData);
                        },
                        backgroundColor: Colors.white,
                        shape: CircleBorder(),
                        child: (imageLoader)
                            ? Padding(
                                padding: const EdgeInsets.all(5),
                                child: CircularProgressIndicator.adaptive(),
                              )
                            : Icon(
                                Icons.edit_rounded,
                                color: color3,
                              ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage(blankProfileImage),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: FloatingActionButton.small(
                          onPressed: () {
                            onTapEditImage(userData);
                          },
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          child: Icon(
                            Icons.edit_rounded,
                            color: color3,
                          ),
                        ),
                      ),
                    );
                  },
                  placeholder: (context, url) =>
                      CircularProgressIndicator.adaptive(),
                ),
              ),
            ),
          ],
        ),
        sbh15,
        Stack(
          // Username
          alignment: Alignment.centerRight,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                userData.userName == ""
                    ? "Add username"
                    : userData.userName ?? "",
                textAlign: TextAlign.center,
                style: TextTheme.of(context).headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 50),
              child: editButton(onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          customTextField(
                            controller: _usernameController,
                            text: "User Name",
                            iconData: Icons.person_add_alt_1,
                          ),
                          InkWell(
                            onTap: () {
                              showYesNoDialog(
                                context,
                                title: 'Edit Username ?',
                                contentWidget: Text(
                                  '${userData.userName ?? "username"} ➡️ ${_usernameController.text}',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                onTapYes: () {
                                  setState(() {
                                    isEditing = true;
                                  });
                                  ref
                                      .read(userDataNotifierProvider.notifier)
                                      .updateCurrentUserData(
                                          userName: _usernameController.text)
                                      .then((value) {
                                    (value)
                                        ? snackbarToast(
                                            context: context,
                                            text: "Value Updated!",
                                            icon: Icons.done_all)
                                        : snackbarToast(
                                            context: context,
                                            text: "Error Updating value!",
                                            icon: Icons.error_outline_rounded);
                                    setState(() {
                                      Navigate().goBack();
                                    });
                                    Navigate().goBack();
                                  });
                                  setState(() {
                                    isEditing = false;
                                  });
                                },
                                onTapNo: () {
                                  Navigate().goBack();
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              decoration: BoxDecoration(
                                border: Border.all(color: color3),
                                borderRadius: BorderRadius.circular(15),
                                color: color4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                spacing: 20,
                                children: [
                                  Text(
                                    "Save",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: color3),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        Text(
          // email
          userData.email == "" ? "No email found" : userData.email ?? "",
          style: TextStyle(
            fontSize: 18,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget editDetailsForm(UserData userData) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              sbh10,
              textFieldWithEditButton(
                customTextField(
                  controller: _nameController,
                  text: "Full Name",
                  iconData: Icons.person,
                ),
                onTapEdit: () {
                  showYesNoDialog(
                    context,
                    title: 'Edit Name ?',
                    contentWidget: Text(
                      '${userData.name ?? "Name"} ➡️ ${_nameController.text}',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    onTapYes: () {
                      setState(() {
                        isEditing = true;
                      });
                      ref
                          .read(userDataNotifierProvider.notifier)
                          .updateCurrentUserData(name: _nameController.text)
                          .then((value) {
                        (value)
                            ? snackbarToast(
                                context: context,
                                text: "Value Updated!",
                                icon: Icons.done_all)
                            : snackbarToast(
                                context: context,
                                text: "Error Updating value!",
                                icon: Icons.error_outline_rounded);
                        setState(() {
                          Navigate().goBack();
                        });
                      });
                      setState(() {
                        isEditing = false;
                      });
                    },
                    onTapNo: () {
                      Navigate().goBack();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget textFieldWithEditButton(
    Widget textField, {
    void Function()? onTapEdit,
  }) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        textField,
        Padding(
          padding: const EdgeInsets.only(right: 25),
          child: editButton(
            onTap: onTapEdit,
          ),
        ),
      ],
    );
  }

  void onTapEditImage(UserData userData) async {
    setState(() {
      imageLoader = true;
    });
    try {
      File? imageFile = await getImageFromGallery();
      if (imageFile != null) {
        final imageUrl = await uploadUserPfpic(
            file: imageFile, uid: userData.uid.toString());
        logger.i('Image Selected: $imageUrl');
        if (imageUrl != null) {
          ref
              .read(userDataNotifierProvider.notifier)
              .updateCurrentUserData(pfpURL: imageUrl);
        } else {
          logger.e("Error uploading image");
        }
      } else {
        logger.w("No image selected");
      }
      setState(() {
        imageLoader = false;
      });
    } catch (e) {
      logger.e("Error while editing image: $e");
      setState(() {
        imageLoader = false;
      });
    }
  }
}
