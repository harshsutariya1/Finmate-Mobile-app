// import 'package:finmate/models/user.dart';
// import 'package:finmate/models/user_finance_data_provider2.dart';
// import 'package:finmate/models/user_provider2.dart';
// import 'package:finmate/screens/auth/auth.dart';
// import 'package:finmate/screens/home/bnb_pages.dart';
// import 'package:finmate/services/auth_services.dart';
// import 'package:finmate/widgets/loading_Error_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get_it/get_it.dart';
// import 'package:logger/logger.dart';

// class Logincheck extends ConsumerWidget {
//   Logincheck({super.key});
//   final AuthService _authService = GetIt.instance.get<AuthService>();
//   final logger = Logger(
//     printer: PrettyPrinter(),
//   );
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       body: FutureBuilder(
//         future: _firebaseAuth.authStateChanges().first,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return LoadingScreen(); // Loading screen
//           } else if (snapshot.hasData && snapshot.data?.uid != null) {
//             logger.i("User Logged in.\nGot userId: ${snapshot.data?.uid}");
//             final uid = snapshot.data?.uid;
//             return FutureBuilder(
//               future: Future.wait([
//                 ref.read(userDataNotifierProvider.notifier).getUserData(uid!),
//                 ref
//                     .read(userFinanceDataNotifierProvider.notifier)
//                     .getUserFinanceData(uid),
//               ]),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return LoadingScreen(); // Loading screen
//                 } else if (snapshot.hasData &&
//                     snapshot.data![0] != null &&
//                     snapshot.data![1] != null) {
//                   // Future(() {
//                   //   ref
//                   //       .read(userDataNotifierProvider.notifier)
//                   //       .setUserData(snapshot.data![0] as UserData);
//                   // });
//                   // Future(() {
//                   //   ref
//                   //       .read(userFinanceDataNotifierProvider.notifier)
//                   //       .setUserFinanceData(
//                   //           snapshot.data![1] as UserFinanceData);
//                   // });
//                   logger.i("Got UserData: ${(snapshot.data?[0] as UserData).email}");
//                   return BnbPages();
//                 } else {
//                   logger.i(
//                       "Error getting user data: ${!(snapshot.data![0] != null && snapshot.data![1] != null)} and going to auth screen.");
//                   _authService.logout();
//                   return const AuthScreen(); // User is not logged in
//                 }
//               },
//             );
//           } else {
//             logger.i("Error getting uid: and to auth screen.");
//             _authService.logout();
//             return const AuthScreen(); // User is not logged in
//           }
//         },
//       ),
//     );
//   }
// }
