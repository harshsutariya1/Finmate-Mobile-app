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
            "User with uid $uid found. \nemail: ${state.email} \nphoneNum: ${state.phoneNumber} \nname: ${state.name} \nimage: ${state.pfpURL}");
        // print("User with uid $uid found.");
        // print("email: ${state.email}");
        // print("phoneNum: ${state.phoneNumber}");
        // print("name: ${state.name}");
        // print("image: ${state.pfpURL}");
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

  // void updateCurrentUserData({
  //   String? uid,
  //   String? name,
  //   String? email,
  //   bool? isOnline,
  //   String? phoneNumber,
  //   String? profilePicUrl,
  //   int? noOfGroups,
  //   List<String>? groupIds,
  //   int? noOfChats,
  //   List<String>? chatIds,
  //   // String? dateOfBirth,
  //   String? gender,
  // }) async {
  //   try {
  //     final userRef = userCollection.doc(state.uid!.isEmpty ? uid : state.uid);

  //     Map<String, dynamic> updatedData = {
  //       'name': name ?? state.name,
  //       'email': email ?? state.email,
  //       'isOnline': isOnline ?? state.isOnline,
  //       'phoneNumber': phoneNumber ?? state.phoneNumber,
  //       'pfpURL': profilePicUrl ?? state.pfpURL,
  //       'noOfGroups': noOfGroups ?? state.noOfGroups,
  //       'groupIds': groupIds ?? state.groupIds,
  //       'noOfChats': noOfChats ?? state.noOfChats,
  //       'chatIds': chatIds ?? state.chatIds,
  //       // 'dateOfBirth': dateOfBirth ?? state.chatIds,
  //       'gender': gender ?? state.gender,
  //     };
  //     await userRef.update(updatedData);
  //     state = UserData(
  //       uid: state.uid!.isEmpty ? uid : state.uid,
  //       name: name ?? state.name,
  //       email: email ?? state.email,
  //       isOnline: isOnline ?? state.isOnline,
  //       phoneNumber: phoneNumber ?? state.phoneNumber,
  //       pfpURL: profilePicUrl ?? state.pfpURL,
  //       noOfGroups: noOfGroups ?? state.noOfGroups,
  //       groupIds: groupIds ?? state.groupIds,
  //       noOfChats: noOfChats ?? state.noOfChats,
  //       chatIds: chatIds ?? state.chatIds,
  //       // dateOfBirth: dateOfBirth ?? state.dateOfBirth,
  //       gender: gender ?? state.gender,
  //     );
  //     print('Document updated successfully!');
  //   } catch (e) {
  //     print('Error updating document: $e');
  //   }
  // }
}
