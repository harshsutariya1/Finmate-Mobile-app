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

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabTitles,
    required this.onTap,
  });

  final int selectedIndex;
  final List<String> tabTitles;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: kToolbarHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: color2.withAlpha(150),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(tabTitles.length, (index) {
            return GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                margin: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: color2),
                  color: selectedIndex == index ? color2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  tabTitles[index],
                  style: TextStyle(
                    color: selectedIndex == index ? whiteColor : color2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
