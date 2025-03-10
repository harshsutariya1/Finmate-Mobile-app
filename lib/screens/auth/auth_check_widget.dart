// import 'package:finmate/models/user_provider.dart';
import 'package:finmate/providers/auth_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/auth.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/widgets/loading_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthCheckWidget extends ConsumerWidget {
  const AuthCheckWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    // final userDataExists = ref.watch(userDataExistsProvider);
    // final authState = ref.watch(spStringKeyProvider("userId"));

    return authState.when(
      data: (user) {
        if (user == null) {
          return AuthScreen(); // User not logged in
        } else {
          return UserDataLoader(uid: user.uid);
        }
      },
      loading: () => LoadingScreen(),
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
          return AuthScreen(); // Handle case where user data is missing
        }
        return BnbPages(); // Show home screen after data is loaded
      },
      loading: () => LoadingScreen(),
      error: (err, stack) => ErrorScreen(error: err.toString()),
    );
  }
}
