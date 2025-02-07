import 'package:finmate/Models/user.dart';
import 'package:finmate/services/database_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

//	dart run build_runner watch -d
@riverpod
class UserDataNotifier extends _$UserDataNotifier {
  var logger = Logger(
    printer: PrettyPrinter(methodCount: 2),
  );

  @override
  UserData build() {
    // Initial empty user state
    return UserData(uid: "", name: "");
  }

  Future<bool> fetchCurrentUserData(String? uid) async {
    if (uid == null || uid.isEmpty) {
      logger.w("Error: UID is null or empty");
      return false; // Exit the function early if the UID is invalid
    }

    try {
      logger.i("checking document of: $uid");
      final docSnapshot = await userCollection.doc(uid).get();

      if (docSnapshot.exists) {
      state = docSnapshot.data()!;
      logger.i(
          "User with uid $uid found. \nemail: ${state.email} \nname: ${state.name} \nimage: ${state.pfpURL}");

      return true;
      } else {
        logger.w("User with uid $uid not found.");
        await FirebaseAuth.instance.signOut();
        return false;
      }
    } catch (e) {
      logger.w("Failed to fetch current user data: $e");
      return false;
    }
  }

  void updateCurrentUserData({
    // required String uid,
    String? name,
    String? pfpURL,
    String? email,
    String? gender,
    int? cash,
    DateTime? dob,
    List<String>? transactionIds,
    List<String>? groupIds,
  }) async {
    try {
      final userRef = userCollection.doc(state.uid);

      Map<String, dynamic> updatedData = {
        'name': name ?? state.name,
        'pfpURL': pfpURL ?? state.pfpURL,
        'email': email ?? state.email,
        'gender': gender ?? state.gender,
        'cash': cash ?? state.cash,
        'dob': dob ?? state.dob,
        'transactionIds': transactionIds ?? state.transactionIds,
        'groupIds': groupIds ?? state.groupIds,
      };
      await userRef.update(updatedData).then((value) {
        state = UserData(
          uid: state.uid,
          name: name ?? state.name,
          pfpURL: pfpURL ?? state.pfpURL,
          email: email ?? state.email,
          gender: gender ?? state.gender,
          cash: cash ?? state.cash,
          dob: dob ?? state.dob,
          transactionIds: transactionIds ?? state.transactionIds,
          groupIds: groupIds ?? state.groupIds,
        );
        logger.i('Document updated successfully!');
      });
    } catch (e) {
      logger.w("Error updating document: $e");
    }
  }
}
