import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
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
            "✅ User data loaded successfully for $uid. \nUserName: ${state.userName} \nName: ${state.name} \nEmail: ${state.email} \nImage: ${state.pfpURL} \nNo of Transactios: ${state.transactionIds?.length}");

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
    String? name,
    String? userName,
    String? pfpURL,
    String? email,
    String? gender,
    // int? cash,
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
      // if (cash != null) {
      //   updatedData['cash'] = cash;
      // }
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
          // cash: cash ?? state.cash,
          dob: dob ?? state.dob,
          transactionIds: transactionIds ?? state.transactionIds,
          groupIds: groupIds ?? state.groupIds,
        );
        logger.i('✅ User data updated successfully!');
      }).then((value) {
        return true;
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

final allAppUsers = FutureProvider<List<UserData>>((ref) async {
  List<UserData> listOfUsers = await getAllAppUsers();
  Logger().i("Got all users of application: ${listOfUsers.length}");
  return listOfUsers;
});

final userDataProvider =
    FutureProvider.family<UserData, String>((ref, uid) async {
  final userNotifier = ref.read(userDataNotifierProvider.notifier);
  await userNotifier.fetchCurrentUserData(uid);
  final userFinanceNotifier =
      ref.read(userFinanceDataNotifierProvider.notifier);
  await userFinanceNotifier.fetchUserFinanceData(uid);
  ref.read(allAppUsers);
  return ref.read(userDataNotifierProvider);
});
