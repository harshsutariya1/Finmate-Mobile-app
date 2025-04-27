import 'package:finmate/providers/auth_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/auth.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/screens/onboarding/intro_slider.dart'; // Import the intro slider
import 'package:finmate/widgets/loading_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheckWidget extends ConsumerStatefulWidget {
  const AuthCheckWidget({super.key});

  @override
  ConsumerState<AuthCheckWidget> createState() => _AuthCheckWidgetState();
}

class _AuthCheckWidgetState extends ConsumerState<AuthCheckWidget> {
  bool _hasSeenIntro = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstOpen();
  }

  Future<void> _checkFirstOpen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    // Show intro slider if this is the first time
    if (!_hasSeenIntro) {
      return const IntroSlider();
    }
    
    // Otherwise proceed with regular auth check
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AuthScreen(); // User not logged in
        } else {
          return UserDataLoader(uid: user.uid);
        }
      },
      loading: () => const LoadingScreen(),
      error: (err, stack) => ErrorScreen(error: err.toString()),
    );
  }
}

class UserDataLoader extends ConsumerWidget {
  final String uid;
  const UserDataLoader({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataState = ref.watch(userDataProvider(uid));

    return userDataState.when(
      data: (userData) {
        if (userData.uid == null || userData.uid == "") {
          return const AuthScreen(); // Handle case where user data is missing
        }
        return const BnbPages(); // Show home screen after data is loaded
      },
      loading: () => const LoadingScreen(),
      error: (err, stack) => ErrorScreen(error: err.toString()),
    );
  }
}
