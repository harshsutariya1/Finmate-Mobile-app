// Provider for UserFinanceDataNotifier
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/services/database_references.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final userFinanceDataNotifierProvider =
    StateNotifierProvider<UserFinanceDataNotifier, UserFinanceData>((ref) {
  return UserFinanceDataNotifier();
});

class UserFinanceDataNotifier extends StateNotifier<UserFinanceData> {
  UserFinanceDataNotifier() : super(UserFinanceData());
  var logger = Logger(
    printer: PrettyPrinter(methodCount: 1),
  );

  Future<bool> fetchUserFinanceData(String uid) async {
    List<Transaction> transactions = [];
    List<Group> groups = [];
    // List<BankAccount> bankAccounts = [];
    Cash? cash = Cash();
    try {
      await userTransactionsCollection(uid).get().then((value) {
        for (var element in value.docs) {
          transactions.add(element.data());
        }
      }).then((value) async {
        await userCashDocument(uid).get().then((value) {
          cash = value.data();
        }).then((value) async {
          await groupsCollection.get().then((value) async {
            // fetch all the groups
            for (var element in value.docs) {
              if (element.data().memberIds?.contains(uid) ?? false) {
                final currentGroup = element.data();
                // fetch group transactions
                await groupTansactionCollection(currentGroup.gid!)
                    .get()
                    .then((transactionSnapshot) {
                  for (var transaction in transactionSnapshot.docs) {
                    currentGroup.listOfTransactions?.add(transaction.data());
                  }
                });
                Logger().i(
                    "Current Group: ${currentGroup.name},\nGroup Transactions: ${currentGroup.listOfTransactions?.length}");
                groups.add(currentGroup);
              }
            }
          }).then((value) {
            state = UserFinanceData(
              listOfGroups: groups,
              listOfUserTransactions: transactions,
              cash: cash,
            );
            logger.i(
                "✅ User Finance data fetched successfully. \nTransactions: ${state.listOfUserTransactions?.length} \nCash Amount: ${state.cash?.amount} \nGroups: ${state.listOfGroups?.length}");
          });
        });
      });

      return true;
    } catch (e) {
      logger.w("Failed to fetch user finance data: $e");
      return false;
    }
  }

  Future<bool> updateUserCashAmount(
      {required String uid, required String amount}) async {
    try {
      await userCashDocument(uid).update({
        'amount': amount,
      }).then((value) {
        state = UserFinanceData(
          listOfGroups: state.listOfGroups,
          listOfUserTransactions: state.listOfUserTransactions,
          cash: Cash(amount: amount),
        );
        logger.i("Cash amount updated successfully.");
      });
      return true;
    } catch (e) {
      logger.w("Error while updating cash amount: $e");
      return false;
    }
  }

  Future<bool> updateGroupAmount(
      {required String gid, required String amount}) async {
    try {
      await groupsCollection.doc(gid).update({
        'totalAmount': amount,
      }).then((value) {
        final group =
            state.listOfGroups?.firstWhere((group) => group.gid == gid);
        if (group != null) {
          final updatedGroup = group.copyWith(totalAmount: amount);
          final updatedGroups = state.listOfGroups?.map((g) {
            return g.gid == gid ? updatedGroup : g;
          }).toList();

          state = UserFinanceData(
            listOfGroups: updatedGroups,
            listOfUserTransactions: state.listOfUserTransactions,
            cash: state.cash,
          );
          logger.i("Group amount updated successfully.");
        }
      });
      return true;
    } catch (e) {
      logger.w("Error while updating amount: $e");
      return false;
    }
  }

  Future<bool> addTransactionToUserData({
    required String uid,
    required Transaction transactionData,
    required WidgetRef ref,
  }) async {
    try {
      final result = (transactionData.isGroupTransaction)
          ? await groupTansactionCollection(transactionData.gid)
              .add(transactionData)
          : await userTransactionsCollection(uid).add(transactionData);
      await updateTransactionTidData(
        uid: uid,
        tid: result.id,
        transaction: transactionData,
      );

      print("Transaction added to user");
      return true;
    } catch (e) {
      print("Error adding transaction to user: $e");
      return false;
    }
  }

  Future<bool> updateTransactionTidData({
    required String uid,
    required String tid,
    required Transaction transaction,
  }) async {
    final Transaction tempTransaction = transaction;
    try {
      // adding tid to transaction doc in firestore
      ((tempTransaction.isGroupTransaction)
              ? groupTansactionCollection(tempTransaction.gid).doc(tid)
              : userTransactionsCollection(uid).doc(tid))
          .update({
        'tid': tid,
      }).then((value) async {
        tempTransaction.tid = tid;
        if (!tempTransaction.isGroupTransaction) {
          // updating transation in user transactions
          final List<Transaction>? listOfUserTransactions =
              state.listOfUserTransactions;
          listOfUserTransactions?.add(tempTransaction);
          state = UserFinanceData(
            listOfGroups: state.listOfGroups,
            listOfUserTransactions: listOfUserTransactions,
            cash: state.cash,
          );
        } else {
          // updating transation in group transactionsList
          final List<Group>? listOfGroups = state.listOfGroups;
          listOfGroups
              ?.firstWhere((group) => group.gid == tempTransaction.gid)
              .listOfTransactions
              ?.add(tempTransaction);
          state = UserFinanceData(
            listOfGroups: listOfGroups,
            listOfUserTransactions: state.listOfUserTransactions,
            cash: state.cash,
          );
        }
      });

      return true;
    } catch (e) {
      logger.w("Error while updating transaction tid: $e");
      return false;
    }
  }

  Future<bool> deleteTransaction(String uid, String tid) async {
    try {
      userTransactionsCollection(uid).doc(tid).delete().then((value) {
        state = UserFinanceData(
          listOfGroups: state.listOfGroups,
          listOfUserTransactions: state.listOfUserTransactions
              ?.where((transaction) => transaction.tid != tid)
              .toList(),
        );
        logger.i("Transaction with tid $tid removed successfully.");
      });

      return true;
    } catch (e) {
      logger.w("Error while removing transaction with tid $tid: $e");
      return false;
    }
  }

  Future<bool> createGroupProfile({
    required Group groupProfile,
    required WidgetRef ref,
  }) async {
    try {
      if (groupProfile.creatorId != null) {
        final result = await groupsCollection.add(groupProfile);
        await result.update({'gid': result.id});

        state = UserFinanceData(
          listOfGroups: state.listOfGroups!
            ..add(groupProfile.copyWith(gid: result.id)),
          listOfUserTransactions: state.listOfUserTransactions,
          cash: state.cash,
        );
      } else {
        Logger().w("❗groupProfile.creatorId is null");
        throw ArgumentError("❗groupProfile.creatorId cannot be null");
      }
      Logger().i("✅Group profile created successfully");
      return true;
    } catch (e) {
      Logger().w("❗Error creating group profile: $e");
      return false;
    }
  }

  Future<bool> deleteGroupProfile({required Group group}) async {
    print("uid: ${group.creatorId}, gid: ${group.gid}");
    try {
      await groupsCollection.doc(group.gid).delete().then((value) {
        state = UserFinanceData(
          listOfGroups:
              state.listOfGroups?.where((g) => g.gid != group.gid).toList(),
          listOfUserTransactions: state.listOfUserTransactions,
          cash: state.cash,
        );
        logger.i("✅Group with gid $group.gid removed successfully.");
      });

      return true;
    } catch (e) {
      logger.w("❗Error while removing group with gid $group.gid: $e");
      return false;
    }
  }

  void reset() {
    state = UserFinanceData();
    print("user finance data reset");
  }
}
