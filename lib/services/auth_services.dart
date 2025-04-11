import 'package:finmate/models/user.dart';
import 'package:finmate/providers/auth_provider.dart';
import 'package:finmate/providers/budget_provider.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/auth/auth.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/database_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/loading_error_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  var logger = Logger(
    printer: PrettyPrinter(),
  );
  var loggerNoStack = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  User? user;

  Widget checkLogin() {
    loggerNoStack.i("Login checking...");
    return Consumer(builder: (context, ref, child) {
      return StreamBuilder<User?>(
        stream: _firebaseAuth.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (snapshot.hasData) {
            user = snapshot.data;
            final uid = user?.uid;

            if (uid != null && uid.isNotEmpty) {
              return FutureBuilder(
                future: Future.wait([
                  // ref.read(userDataNotifierProvider.notifier).getUserData(uid),
                  // ref
                  //     .read(userFinanceDataNotifierProvider.notifier)
                  //     .getUserFinanceData(uid),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return LoadingScreen(); // Loading screen
                  } else if (snapshot.hasData &&
                      snapshot.data![0] != null &&
                      snapshot.data![1] != null) {
                    // Future(() {
                    //   ref
                    //       .read(userDataNotifierProvider.notifier)
                    //       .setUserData(snapshot.data![0] as UserData);
                    // });
                    // Future(() {
                    //   ref
                    //       .read(userFinanceDataNotifierProvider.notifier)
                    //       .setUserFinanceData(
                    //           snapshot.data![1] as UserFinanceData);
                    // });
                    return BnbPages();
                  } else {
                    logger.i(
                        "Error getting user data: ${!(snapshot.data![0] != null && snapshot.data![1] != null)} and going to auth screen.");
                    logout(ref);
                    return const AuthScreen(); // User is not logged in
                  }
                },
              );
            } else {
              logger
                  .e("Error: UID is null or empty: returning to signup screen");
              return const AuthScreen();
            }
          } else {
            loggerNoStack.i("User is not signed in: to auth screen");
            return const AuthScreen();
          }
        },
      );
    });
  }

  Future<bool> login(String email, String password, WidgetRef ref) async {
    print("login function running");
    final sp = await SharedPreferences.getInstance();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        user = credential.user;
        sp.setString("userId", user!.uid);
        ref.watch(userDataProvider(user!.uid));
        await Future.delayed(Duration(seconds: 3));
        return true;
      } else {
        return false;
      }
    } catch (e) {
      loggerNoStack.w("Login failed, user id not found");
      logger.w("Error: $e");
      return false;
    }
  }

  Future<String> signup(
    String name,
    String email,
    String password,
    WidgetRef ref,
  ) async {
    print("signup function running");
    final sp = await SharedPreferences.getInstance();
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        user = credential.user;
        await createUserProfile(
            userProfile: UserData(
          uid: user?.uid,
          name: name,
          userName: user?.email,
          email: email,
        )).then((value) async {
          ref.watch(userDataProvider(user!.uid));
          await Future.delayed(Duration(seconds: 3));
        });
        sp.setString("userId", user!.uid);
        return "Success";
      } else {
        return "Error";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("___Error: Email is already in use___");
        return "Email already in use";
      } else {
        print("Error: $e");
        return "Error";
      }
    } catch (e) {
      print("Error: $e");
      return "Error";
    }
  }

  Future<bool> handleGoogleSignIn(WidgetRef ref) async {
    print("handleGoogleSignIn function called");
    final sp = await SharedPreferences.getInstance();
    try {
      final userCredential = await signInWithGoogle();
      final user = userCredential?.user;
      final uid = user?.uid;
      final pfpicUrl = user?.photoURL;
      final email = user?.email;
      final name = user?.displayName;
      print("UID: $uid, \nemail: $email,");
      this.user = user;

      bool userExists = await checkExistingUser(uid!);

      if (user != null) {
        if (!userExists) {
          await createUserProfile(
              userProfile: UserData(
            uid: uid,
            userName: email,
            name: name,
            pfpURL: pfpicUrl,
            email: email,
          ));
        }
        ref.watch(userDataProvider(uid));
        await Future.delayed(Duration(seconds: 3));
        sp.setString("userId", user.uid);
        // go to HomeScreen
        print('Google Signed in as: ${user.displayName}');
        return true;
      } else {
        print("Gooogle signin failed");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    print("signInWithGoogle function called");
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        return null;
      }
    } catch (e) {
      print("Error: $e");
    }
    return null;
  }

  Future<bool> logout(WidgetRef ref) async {
    print("logout function called");
    final sp = await SharedPreferences.getInstance();
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      sp.setString("userId", "");
      ref.read(userDataNotifierProvider.notifier).reset();
      ref.read(userFinanceDataNotifierProvider.notifier).reset();
      ref.read(budgetNotifierProvider.notifier).reset();

      user = null;
      return true;
    } catch (e) {
      print("Error: $e");
    }
    return false;
  }

  void logoutDilog(BuildContext context, WidgetRef ref) {
    print("logoutDilog function called");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            ElevatedButton(
                onPressed: () {
                  logout(ref);
                  Navigate().toAndRemoveUntil(AuthScreen());
                },
                child: const Text("Yes")),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("No")),
          ],
        );
      },
    );
  }
}
