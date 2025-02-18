import 'package:finmate/models/user.dart';
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
    try {
      logger.i("checking document of: $uid");
      final docSnapshot = await userCollection.doc(uid).get();

      if (docSnapshot.exists) {
        state = docSnapshot.data()!;
        logger.i(
            "User with uid $uid found. \nUserName: ${state.userName} \nName: ${state.name} \nEmail: ${state.email} \nImage: ${state.pfpURL}");

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

  Future<bool> updateCurrentUserData({
    String? name,
    String? userName,
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

      Map<String, dynamic> updatedData = {};

      if (name != null) {
        updatedData['name'] = name;
      }
      if (userName != null) {
        updatedData['userName'] = userName;
      }
      if (pfpURL != null) {
        updatedData['pfpURL'] = pfpURL;
      }
      if (email != null) {
        updatedData['email'] = email;
      }
      if (gender != null) {
        updatedData['gender'] = gender;
      }
      if (cash != null) {
        updatedData['cash'] = cash;
      }
      if (dob != null) {
        updatedData['dob'] = dob.toIso8601String();
      }
      if (transactionIds != null) {
        updatedData['transactionIds'] = transactionIds;
      }
      if (groupIds != null) {
        updatedData['groupIds'] = groupIds;
      }

      await userRef.update(updatedData).then((value) {
        state = UserData(
          uid: state.uid,
          name: name ?? state.name,
          userName: userName ?? state.userName,
          pfpURL: pfpURL ?? state.pfpURL,
          email: email ?? state.email,
          gender: gender ?? state.gender,
          cash: cash ?? state.cash,
          dob: dob ?? state.dob,
          transactionIds: transactionIds ?? state.transactionIds,
          groupIds: groupIds ?? state.groupIds,
        );
        logger.i('Document updated successfully!');
      }).then((value) {
        return true;
      });
      return true;
    } catch (e) {
      logger.w("Error updating document: $e");
      return false;
    }
  }
}
