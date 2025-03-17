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

Widget simpleBorderContainer({
  Key? key,
  AlignmentGeometry? alignment,
  EdgeInsetsGeometry? padding,
  Color? color,
  Decoration? decoration,
  Decoration? foregroundDecoration,
  double? width,
  double? height,
  BoxConstraints? constraints,
  EdgeInsetsGeometry? margin,
  Matrix4? transform,
  AlignmentGeometry? transformAlignment,
  Widget? child,
  Clip clipBehavior = Clip.none,
}) {
  return Container(
    key: key,
    alignment: alignment,
    padding: padding,
    color: color,
    width: width,
    height: height,
    constraints: constraints,
    margin: margin,
    transform: transform,
    transformAlignment: transformAlignment,
    clipBehavior: clipBehavior,
    foregroundDecoration: foregroundDecoration,
    decoration: decoration ??
        BoxDecoration(
          border: Border.all(color: color2),
          borderRadius: BorderRadius.circular(10),
        ),
    child: child,
  );
}
