import 'package:finmate/constants/colors.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';

class EditUserDetails extends StatefulWidget {
  const EditUserDetails({super.key});

  @override
  State<EditUserDetails> createState() => _EditUserDetailsState();
}

class _EditUserDetailsState extends State<EditUserDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorWhite,
      appBar: customAppBar("Edit Profile"),
      // body: ,
    );
  }

  
}