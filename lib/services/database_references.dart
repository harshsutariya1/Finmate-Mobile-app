import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/budget.dart';
import 'package:finmate/models/group_chat.dart';
import 'package:finmate/models/goal.dart';
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

// Collection reference for budget documents
CollectionReference<Budget> userBudgetsCollection(String uid) {
  return userCollection.doc(uid).collection('budgets').withConverter<Budget>(
        fromFirestore: (snapshot, _) => Budget.fromJson(snapshot.data()!),
        toFirestore: (budget, _) => budget.toJson(),
      );
}

// Collection reference for goal documents
CollectionReference<Goal> userGoalsCollection(String uid) {
  return userCollection.doc(uid).collection('goals').withConverter<Goal>(
        fromFirestore: (snapshot, _) => Goal.fromJson(snapshot.data()!),
        toFirestore: (goal, _) => goal.toJson(),
      );
}

CollectionReference<Chat> groupChatCollection(String gid) {
  final collectionref =
      groupsCollection.doc(gid).collection("group_chats").withConverter<Chat>(
            fromFirestore: (snapshots, _) => Chat.fromJson(snapshots.data()!),
            toFirestore: (chat, _) => chat.toJson(),
          );
  return collectionref;
}
