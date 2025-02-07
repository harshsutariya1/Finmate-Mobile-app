import 'package:finmate/Models/user.dart';
import 'package:finmate/models/user_finance_data_provider.dart';
import 'package:finmate/models/user_provider.dart';
import 'package:finmate/screens/auth/auth.dart';
import 'package:finmate/screens/home/bnb_pages.dart';
import 'package:finmate/services/database_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

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
            return const Loader();
          }
          if (snapshot.hasData) {
            user = snapshot.data;
            final uid = user?.uid;

            if (uid != null && uid.isNotEmpty) {
              ref
                  .read(userDataNotifierProvider.notifier)
                  .fetchCurrentUserData(uid);
              ref
                  .read(userFinanceDataNotifierProvider.notifier)
                  .fetchUserFinanceData(uid);
            } else {
              logger
                  .e("Error: UID is null or empty: retuning to signup screen");
              return const AuthScreen();
            }

            loggerNoStack.i(
                "User email: ${user?.email}\nUser is signed in: to home screen, name: ${user?.displayName}");

            return const BnbPages();
          } else {
            loggerNoStack.i("User is not signed in: to auth screen");
            return const AuthScreen();
          }
        },
      );
    });
  }

  Future<bool> login(String email, String password, WidgetRef ref) async {
    print("login function called");
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        user = credential.user;
        ref
            .read(userDataNotifierProvider.notifier)
            .fetchCurrentUserData(user?.uid);
        ref
            .read(userFinanceDataNotifierProvider.notifier)
            .fetchUserFinanceData(user!.uid);
        return true;
      }
    } catch (e) {
      loggerNoStack.w("Login failed");
      logger.w("Error: $e");
      return false;
    }
    return false;
  }

  Future<String> signup(
    String name,
    String email,
    String password,
    WidgetRef ref,
  ) async {
    print("signup function called");
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        user = credential.user;
        createUserProfile(
            userProfile: UserData(
          uid: user?.uid,
          name: name,
          email: email,
        ));
        ref
            .read(userDataNotifierProvider.notifier)
            .fetchCurrentUserData(user?.uid);
        ref
            .read(userFinanceDataNotifierProvider.notifier)
            .fetchUserFinanceData(user!.uid);
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
    try {
      final userCredential = await signInWithGoogle();
      final user = userCredential?.user;
      final uid = user?.uid;
      final pfpicUrl = user?.photoURL;
      final email = user?.email;
      final name = user?.displayName;
      print("UID: $uid, \nemail: $email,");

      bool userExists = await checkExistingUser(uid!);

      if (user != null) {
        if (!userExists) {
          await createUserProfile(
              userProfile: UserData(
            uid: uid,
            name: name,
            pfpURL: pfpicUrl,
            email: email,
          ));
        }
        await ref
            .read(userDataNotifierProvider.notifier)
            .fetchCurrentUserData(uid);
        await ref
            .read(userFinanceDataNotifierProvider.notifier)
            .fetchUserFinanceData(uid);

        this.user = user;
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

  Future<bool> logout() async {
    print("logout function called");
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      user = null;
      return true;
    } catch (e) {
      print("Error: $e");
    }
    return false;
  }

  void logoutDilog(BuildContext context) {
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
                    logout();
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
        });
  }
}
