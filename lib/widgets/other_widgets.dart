import 'package:cached_network_image/cached_network_image.dart';
import 'package:finmate/constants/assets.dart';
import 'package:finmate/constants/colors.dart';
import 'package:flutter/material.dart';

Widget userProfilePicInCircle({
  String imageUrl = "",
  double outerRadius = 25,
  double innerRadius = 20,
  bool isNumber = false,
  String textNumber = "1",
}) {
  return CircleAvatar(
    radius: outerRadius,
    backgroundColor: color2,
    child: CircleAvatar(
      radius: innerRadius,
      backgroundColor: color4,
      child: (isNumber)
          ? Text(textNumber)
          : CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: innerRadius,
                backgroundImage: imageProvider,
              ),
              errorWidget: (context, url, error) => CircleAvatar(
                radius: innerRadius,
                backgroundImage: AssetImage(blankProfileImage),
              ),
              placeholder: (context, url) => Padding(
                padding: const EdgeInsets.all(3),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
    ),
  );
}
