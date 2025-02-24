import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart' as transaction_model;
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

final ImagePicker _picker = ImagePicker();
final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

CollectionReference<UserData> userCollection =
    FirebaseFirestore.instance.collection('users').withConverter<UserData>(
          fromFirestore: (snapshots, _) => UserData.fromJson(snapshots.data()!),
          toFirestore: (userData, _) => userData.toJson(),
        );

CollectionReference<transaction_model.Transaction> userTransactionsCollection(
    String uid) {
  return userCollection
      .doc(uid)
      .collection('user_transactions')
      .withConverter<transaction_model.Transaction>(
        fromFirestore: (snapshots, _) =>
            transaction_model.Transaction.fromJson(snapshots.data()!),
        toFirestore: (transaction, _) => transaction.toJson(),
      );
}

DocumentReference<Cash> userCashDocument(String uid) {
  return userCollection
      .doc(uid)
      .collection("payment_modes")
      .doc("Cash")
      .withConverter(
        fromFirestore: (snapshot, options) => Cash.fromJson(snapshot.data()!),
        toFirestore: (cash, options) => cash.toJson(),
      );
}

CollectionReference<Group> userGroupsCollection(String uid) {
  return userCollection.doc(uid).collection('user_groups').withConverter<Group>(
        fromFirestore: (snapshots, _) => Group.fromJson(snapshots.data()!),
        toFirestore: (group, _) => group.toJson(),
      );
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

Stream<QuerySnapshot> getTransactionsSnapshot(String uid) {
  try {
    return userCollection.doc(uid).collection('user_transactions').snapshots();
  } catch (e) {
    Logger().e("Error while getting transactions snapshots: $e");
    return const Stream.empty();
  }
}

Future<bool> addTransactionToUserData({
  required String uid,
  required transaction_model.Transaction transactionData,
  required WidgetRef ref,
}) async {
  try {
    final result = await userTransactionsCollection(uid).add(transactionData);
    ref.read(userFinanceDataNotifierProvider.notifier).updateTransactionTidData(
          uid: uid,
          tid: result.id,
          transaction: transactionData,
        );

    List<String>? currentIds =
        ref.read(userDataNotifierProvider).transactionIds ?? [];
    currentIds.add(result.id);
    ref
        .read(userDataNotifierProvider.notifier)
        .updateCurrentUserData(transactionIds: currentIds);

    print("Transaction added to user");
    return true;
  } catch (e) {
    print("Error adding transaction to user: $e");
    return false;
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
