import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';

void snackbarToast({
  required BuildContext context,
  required String text,
  required IconData icon,
}) {
  return DelightToastBar(
    position: DelightSnackbarPosition.top,
    autoDismiss: true,
    snackbarDuration: const Duration(seconds: 3),
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
        border: Border.all(color: color3),
        borderRadius: BorderRadius.circular(10),
        color: color4,
      ),
      child: Row(
        spacing: 30,
        children: [
          Icon(
            icon,
            color: color3,
          ),
          Text(
            text,
            style: TextStyle(
              color: color2,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  ).show(context);
}
