import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

void snackbarToast({
  required BuildContext context,
  required String text,
  required IconData icon,
  bool autoDismiss = true,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  // Get colors based on toast type
  final (Color bgColor, Color borderColor, Color iconColor) =
      _getToastColors(type);

  return DelightToastBar(
    position: DelightSnackbarPosition.top,
    autoDismiss: autoDismiss,
    snackbarDuration: duration,
    builder: (context) => Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withAlpha(100), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: bgColor.withAlpha(250),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: snackBarBody(
        icon: icon,
        text: text,
        iconColor: iconColor,
        textColor: Colors.grey.shade800,
      ),
    ),
  ).show(context);
}

// Helper function to get colors based on toast type
(Color, Color, Color) _getToastColors(ToastType type) {
  switch (type) {
    case ToastType.success:
      return (
        Colors.green.shade50,
        Colors.green.shade300,
        Colors.green.shade600
      );
    case ToastType.error:
      return (Colors.red.shade50, Colors.red.shade300, Colors.red.shade600);
    case ToastType.warning:
      return (
        Colors.amber.shade50,
        Colors.amber.shade300,
        Colors.amber.shade600
      );
    case ToastType.info:
      return (color4, color3, color3);
  }
}

Widget snackBarBody({
  required IconData icon,
  required String text,
  required Color iconColor,
  required Color textColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: Row(
      children: [
        // Leading icon in a circle
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Message text
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),

        // Close button
        SizedBox(
          height: 24,
          width: 24,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.close,
              size: 18,
              color: Colors.grey.shade500,
            ),
            onPressed: () {
              DelightToastBar.removeAll();
            },
          ),
        ),
      ],
    ),
  );
}

// Convenience methods for common toast types
void successToast({
  required BuildContext context,
  required String text,
  IconData icon = Icons.check_circle_outline,
}) {
  snackbarToast(
    context: context,
    text: text,
    icon: icon,
    type: ToastType.success,
  );
}

void errorToast({
  required BuildContext context,
  required String text,
  IconData icon = Icons.error_outline,
}) {
  snackbarToast(
    context: context,
    text: text,
    icon: icon,
    type: ToastType.error,
  );
}

void warningToast({
  required BuildContext context,
  required String text,
  IconData icon = Icons.warning_amber_outlined,
}) {
  snackbarToast(
    context: context,
    text: text,
    icon: icon,
    type: ToastType.warning,
  );
}

void infoToast({
  required BuildContext context,
  required String text,
  IconData icon = Icons.info_outline,
}) {
  snackbarToast(
    context: context,
    text: text,
    icon: icon,
    type: ToastType.info,
  );
}
