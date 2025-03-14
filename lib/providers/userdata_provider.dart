import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/services/database_references.dart';
import 'package:finmate/services/database_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for UserDataNotifier
final userDataNotifierProvider =
    StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier();
});

class UserDataNotifier extends StateNotifier<UserData> {
  UserDataNotifier() : super(UserData(uid: "", name: ""));
  var logger = Logger(
    printer: PrettyPrinter(methodCount: 2),
  );

  Future<bool> fetchCurrentUserData(String? uid) async {
    final sp = await SharedPreferences.getInstance();
    try {
      logger.i("checking document of: $uid");
      final docSnapshot = await userCollection.doc(uid).get();

      if (docSnapshot.exists) {
        state = docSnapshot.data()!;
        logger.i(
            "✅ User data loaded successfully for $uid. \nUserName: ${state.userName} \nName: ${state.name} \nEmail: ${state.email} \nImage: ${state.pfpURL}");

        return true;
      } else {
        await FirebaseAuth.instance.signOut();
        sp.setString("userId", "");
        logger.w("⚠️ User with uid $uid not found. Logging out...");
        return false;
      }
    } catch (e) {
      logger.w("❌ Error fetching user data: $e");
      return false;
    }
  }

  Future<bool> updateCurrentUserData({
    String? firstName,
    String? lastName,
    String? name,
    String? userName,
    String? pfpURL,
    String? email,
    String? gender,
    DateTime? dob,
    // List<String>? groupIds,
    // List<String>? bankAccountIds,
    // List<String>? walletIds,
    // List<String>? cardIds,
  }) async {
    try {
      final userRef = userCollection.doc(state.uid);

      Map<String, dynamic> updatedData = {};

      // Update fields if provided
      if (firstName != null) {
        updatedData['firstName'] = firstName;
      }
      if (lastName != null) {
        updatedData['lastName'] = lastName;
      }
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
      if (dob != null) {
        updatedData['dob'] = dob.toIso8601String();
      }
      // if (groupIds != null) {
      //   updatedData['groupIds'] = groupIds;
      // }
      // if (bankAccountIds != null) {
      //   updatedData['bankAccountIds'] = bankAccountIds;
      // }
      // if (walletIds != null) {
      //   updatedData['walletIds'] = walletIds;
      // }
      // if (cardIds != null) {
      //   updatedData['cardIds'] = cardIds;
      // }

      // Update Firestore document
      await userRef.update(updatedData).then((value) {
        // Update local state
        state = UserData(
          uid: state.uid,
          firstName: firstName ?? state.firstName,
          lastName: lastName ?? state.lastName,
          name: name ?? state.name,
          userName: userName ?? state.userName,
          pfpURL: pfpURL ?? state.pfpURL,
          email: email ?? state.email,
          gender: gender ?? state.gender,
          dob: dob ?? state.dob,
          // groupIds: groupIds ?? state.groupIds,
          // bankAccountIds: bankAccountIds ?? state.bankAccountIds,
          // walletIds: walletIds ?? state.walletIds,
          // cardIds: cardIds ?? state.cardIds,
        );
        logger.i('✅ User data updated successfully!');
      });

      return true;
    } catch (e) {
      logger.w("❌ Error updating user data: $e");
      return false;
    }
  }

  void reset() {
    state = UserData(uid: "", name: "");
    print("user data reset");
  }
}

final FutureProvider<List<UserData>> allAppUsers =
    FutureProvider<List<UserData>>((ref) async {
  List<UserData> listOfUsers = await getAllAppUsers();
  Logger().i("Got all users of application: ${listOfUsers.length}");
  return listOfUsers;
});

final FutureProviderFamily<UserData, String> userDataProvider =
    FutureProvider.family<UserData, String>((ref, uid) async {
  await ref.read(userDataNotifierProvider.notifier).fetchCurrentUserData(uid);
  await ref
      .read(userFinanceDataNotifierProvider.notifier)
      .fetchUserFinanceData(uid);
  ref.read(allAppUsers);
  final UserData userData = ref.watch(userDataNotifierProvider);

  return userData;
});
