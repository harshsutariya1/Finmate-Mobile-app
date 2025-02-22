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
