// Provider for UserFinanceDataNotifier
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/services/database_services.dart';
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
      }).then((value) {
        userCashDocument(uid).get().then((value) {
          cash = value.data();
        }).then((value) {
          userGroupsCollection(uid).get().then((value) {
            for (var element in value.docs) {
              groups.add(element.data());
            }
          }).then((value) {
            state = UserFinanceData(
              listOfGroups: groups,
              listOfTransactions: transactions,
              cash: cash,
            );
            logger.i(
                "✅ User Finance data fetched successfully. \nTransactions: ${state.listOfTransactions?.length} \nCash Amount: ${state.cash?.amount} \nGroups: ${state.listOfGroups?.length}");
          });
        });
      });

      return true;
    } catch (e) {
      logger.w("Failed to fetch user finance data: $e");
      return false;
    }
  }

  Future<bool> updateCashAmount(
      {required String uid, required String amount}) async {
    try {
      await userCashDocument(uid).update({
        'amount': amount,
      }).then((value) {
        state = UserFinanceData(
          listOfGroups: state.listOfGroups,
          listOfTransactions: state.listOfTransactions,
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

  Future<bool> updateTransactionTidData({
    required String uid,
    required String tid,
    required Transaction transaction,
  }) async {
    Transaction temp = transaction;
    try {
      userTransactionsCollection(uid).doc(tid).update({
        'tid': tid,
      }).then((value) {
        temp.tid = tid;
        final listOTransactions = state.listOfTransactions;
        listOTransactions?.add(temp);
        state = UserFinanceData(
          listOfGroups: state.listOfGroups,
          listOfTransactions: listOTransactions,
        );
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
          listOfTransactions: state.listOfTransactions
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
        final result = await userGroupsCollection(groupProfile.creatorId!)
            .add(groupProfile);

        await result.update({'gid': result.id});

        state = UserFinanceData(
          listOfGroups: state.listOfGroups!
            ..add(groupProfile.copyWith(gid: result.id)),
          listOfTransactions: state.listOfTransactions,
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
      await userGroupsCollection(group.creatorId!)
          .doc(group.gid)
          .delete()
          .then((value) {
        state = UserFinanceData(
          listOfGroups:
              state.listOfGroups?.where((g) => g.gid != group.gid).toList(),
          listOfTransactions: state.listOfTransactions,
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
