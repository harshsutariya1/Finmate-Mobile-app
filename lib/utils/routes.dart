
import 'package:finmate/screens/auth/auth.dart';
import 'package:finmate/screens/auth/login.dart';
import 'package:finmate/screens/auth/signup.dart';
import 'package:finmate/screens/home/home_page.dart';
import 'package:flutter/material.dart';

class Routes {
  static Map<String, WidgetBuilder> routes = {
    // '/splash': (context) => const SplashScreen(),
    '/auth': (context) => const AuthScreen(),
    '/signup' : (context) => const SignUpScreen(),
    '/login' : (context) => const LoginScreen(),
    '/home': (context) => const HomePage(),
    // '/userProfile': (context) => const UserProfile(),
  };
}
