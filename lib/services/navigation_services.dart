import 'package:flutter/material.dart';

class Navigate {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final Navigate _instance = Navigate._internal();
  factory Navigate() => _instance;

  Navigate._internal();

  Future<dynamic> push(Widget route) {
    return navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (context) {
          return route;
        },
      ),
    );
  }

  Future<dynamic> toAndRemoveUntil(Widget route) {
    return navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) {
          return route;
        },
      ),
      (route) => false,
    );
  }

  Future<dynamic> pushReplacement(Widget route) {
    return navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return route;
        },
      ),
    );
  }

  void goBack() {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
    }
  }
}
