import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/chat.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart' as transaction_model;
import 'package:finmate/models/user.dart';

final firebaseFirestore = FirebaseFirestore.instance;

CollectionReference<UserData> userCollection =
    firebaseFirestore.collection('users').withConverter<UserData>(
          fromFirestore: (snapshots, _) => UserData.fromJson(snapshots.data()!),
          toFirestore: (userData, _) => userData.toJson(),
        );

CollectionReference<Group> groupsCollection =
    firebaseFirestore.collection('groups').withConverter<Group>(
          fromFirestore: (snapshots, _) => Group.fromJson(snapshots.data()!),
          toFirestore: (group, _) => group.toJson(),
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

CollectionReference<transaction_model.Transaction> groupTansactionCollection(
    String gid) {
  return groupsCollection
      .doc(gid)
      .collection("group_transactions")
      .withConverter<transaction_model.Transaction>(
        fromFirestore: (snapshots, _) =>
            transaction_model.Transaction.fromJson(snapshots.data()!),
        toFirestore: (transaction, _) => transaction.toJson(),
      );
}

DocumentReference<Cash> userCashDocument(String uid) {
  return userCollection.doc(uid).collection("Cash").doc("Cash").withConverter(
        fromFirestore: (snapshot, options) => Cash.fromJson(snapshot.data()!),
        toFirestore: (cash, options) => cash.toJson(),
      );
}

CollectionReference<BankAccount> bankAccountsCollectionReference(String uid) {
  return userCollection.doc(uid).collection("BankAccounts").withConverter(
        fromFirestore: (snapshot, options) =>
            BankAccount.fromJson(snapshot.data()!),
        toFirestore: (bankAccount, options) => bankAccount.toJson(),
      );
}

// CollectionReference<Wallet> walletCollectionReference(String uid) {
//   return userCollection.doc(uid).collection("Wallets").withConverter(
//         fromFirestore: (snapshot, options) => Wallet.fromJson(snapshot.data()!),
//         toFirestore: (wallet, options) => wallet.toJson(),
//       );
// }

CollectionReference<Chat> groupChatCollection(String gid) {
  final collectionref =
      groupsCollection.doc(gid).collection("group_chats").withConverter<Chat>(
            fromFirestore: (snapshots, _) => Chat.fromJson(snapshots.data()!),
            toFirestore: (chat, _) => chat.toJson(),
          );
  return collectionref;
}
