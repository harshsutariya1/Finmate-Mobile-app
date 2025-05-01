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
          ? Text(
              textNumber,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: innerRadius * 0.7,
                color: color2,
              ),
            )
          : (imageUrl.isNotEmpty)
              ? CachedNetworkImage(
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
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: innerRadius,
                  backgroundImage: AssetImage(blankProfileImage),
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

class CustomTabBar extends StatefulWidget {
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
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Initial scroll position for first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTab();
    });
  }

  @override
  void didUpdateWidget(CustomTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selected index changed, scroll to make it visible
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedTab();
      });
    }
  }

  void _scrollToSelectedTab() {
    // Approximate width of each tab - adjust based on your UI
    final double tabWidth = 110.0;

    // Calculate target scroll offset
    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetPosition =
        (widget.selectedIndex * tabWidth) - (screenWidth / 2) + (tabWidth / 2);

    // Ensure we don't scroll out of bounds
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: List.generate(widget.tabTitles.length, (index) {
            return GestureDetector(
              onTap: () => widget.onTap(index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                margin: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: color2),
                  color: widget.selectedIndex == index
                      ? color2
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  widget.tabTitles[index],
                  style: TextStyle(
                    color: widget.selectedIndex == index ? whiteColor : color2,
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
