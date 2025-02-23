// Provider for UserFinanceDataNotifier
import 'package:finmate/models/accounts.dart';
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
    // List<Group> groups = [];
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
          state = UserFinanceData(
            listOfGroups: [],
            listOfTransactions: transactions.toList(),
            cash: cash,
          );
          logger.i(
              "✅ User Finance data fetched successfully. \nTransactions: ${state.listOfTransactions?.length} \nCash Amount: ${state.cash?.amount}");
        });
      });

      return true;
    } catch (e) {
      logger.w("Failed to fetch user finance data: $e");
      return false;
    }
  }

// update user finance data
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

  void reset() {
    state = UserFinanceData();
    print("user finance data reset");
  }
}
