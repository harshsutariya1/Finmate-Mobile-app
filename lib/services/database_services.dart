import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/transaction.dart' as transaction_model;
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/database_references.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

final ImagePicker _picker = ImagePicker();
final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

Future<List<UserData>> getAllAppUsers() async {
  try {
    QuerySnapshot<UserData> querySnapshot = await userCollection.get();
    List<UserData> users = querySnapshot.docs.map((doc) => doc.data()).toList();
    // Logger().i("Got all the users of app: ${users.length}");
    return users;
  } catch (e) {
    Logger().w("Error getting all app users: $e");
    return [];
  }
}

Future<void> createUserProfile({required UserData userProfile}) async {
  try {
    if (userProfile.uid != null) {
      await userCollection.doc(userProfile.uid).set(userProfile);
      await userCashDocument(userProfile.uid!).set(Cash());
    } else {
      print("Error: userProfile.uid is null");
    }
  } catch (e) {
    print("Error creating user profile: $e");
  }
}

Future<bool> checkExistingUser(String uid) {
  CollectionReference blogsRef = FirebaseFirestore.instance.collection('users');
  return blogsRef.doc(uid).get().then((doc) {
    if (doc.exists) {
      return true;
    } else {
      return false;
    }
  });
}

Future<UserData> getUserDetailsFromUid(String uid) async {
  try {
    final docSnapshot = await userCollection.doc(uid).get();

    if (docSnapshot.exists) {
      UserData userDetails = docSnapshot.data()!;
      return userDetails;
    } else {
      return Future.error("User not found");
    }
  } catch (e) {
    return Future.error("Failed to fetch user data : $e");
  }
}

Future<File?> getImageFromGallery() async {
  final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
  if (file != null) {
    return File(file.path);
  }
  return null;
}

Future<String?> uploadUserPfpic({
  required File file,
  required String uid,
}) async {
  try {
    print("uploading profile pic...");
    Reference fileReference = firebaseStorage
        .ref('users/pfpics')
        .child("$uid${path.extension(file.path)}");

    UploadTask uploadTask = fileReference.putFile(file);

    return uploadTask.then((p) {
      if (p.state == TaskState.success) {
        print("File Uploaded: ${fileReference.getDownloadURL().toString()}");
        return fileReference.getDownloadURL();
      }
      print("error while uploading profile pic");
      return null;
    });
  } catch (e) {
    print("Error uploading user profile pic: $e");
    return null;
  }
}

Future<String?> uploadGroupChatPics({
  required File file,
  required String uid,
  required String gid,
}) async {
  try {
    print("uploading pic...");
    Reference fileReference = firebaseStorage.ref('groups/$gid/chatImages').child(
        "${uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}");

    UploadTask uploadTask = fileReference.putFile(file);

    return uploadTask.then((p) {
      if (p.state == TaskState.success) {
        Logger()
            .i("File Uploaded: ${fileReference.getDownloadURL().toString()}");
        return fileReference.getDownloadURL();
      }
      Logger().e("error while uploading pic");
      return null;
    });
  } catch (e) {
    Logger().e("Error uploading pic: $e");
    return null;
  }
}

Stream<QuerySnapshot> getTransactionsSnapshot(String uid) {
  try {
    return userCollection.doc(uid).collection('user_transactions').snapshots();
  } catch (e) {
    Logger().e("Error while getting transactions snapshots: $e");
    return const Stream.empty();
  }
}

Future<bool> deleteTransactionFromUserData({
  required String uid,
  required String tid,
  required WidgetRef ref,
}) async {
  try {
    List<String>? currentIds =
        ref.read(userDataNotifierProvider).transactionIds ?? [];
    currentIds.remove(tid);
    await ref
        .read(userDataNotifierProvider.notifier)
        .updateCurrentUserData(transactionIds: currentIds);
    await ref
        .read(userFinanceDataNotifierProvider.notifier)
        .deleteTransaction(uid, tid);

    print("Transaction deleted from user");
    return true;
  } catch (e) {
    print("Error deleting transaction from user: $e");
    return false;
  }
}
