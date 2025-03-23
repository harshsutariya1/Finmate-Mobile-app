import 'package:flutter/material.dart';

Widget sbh5 = const SizedBox(height: 5);
Widget sbh10 = const SizedBox(height: 10);
Widget sbh15 = const SizedBox(height: 15);
Widget sbh20 = const SizedBox(height: 20);
Widget sbw5 = const SizedBox(width: 5);
Widget sbw10 = const SizedBox(width: 10);
Widget sbw15 = const SizedBox(width: 15);
Widget sbw20 = const SizedBox(width: 20);

Widget sb(double? height, double? width) {
  return SizedBox(height: height ?? 0, width: width ?? 0);
}

BorderRadiusGeometry? borderRadius5 = BorderRadius.circular(5);
BorderRadiusGeometry? borderRadius10 = BorderRadius.circular(10);
BorderRadiusGeometry? borderRadius15 = BorderRadius.circular(15);
BorderRadiusGeometry? borderRadius20 = BorderRadius.circular(20);
BorderRadiusGeometry? borderRadius25 = BorderRadius.circular(25);
BorderRadiusGeometry? borderRadius30 = BorderRadius.circular(30);
BorderRadiusGeometry? borderRadius50 = BorderRadius.circular(50);

BorderRadiusGeometry borderRadius(double? radius) {
  return BorderRadius.circular(radius ?? 0);
}