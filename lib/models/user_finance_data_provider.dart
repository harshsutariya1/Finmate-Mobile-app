import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/services/database_services.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_finance_data_provider.g.dart';

//	dart run build_runner watch -d
@riverpod
class UserFinanceDataNotifier extends _$UserFinanceDataNotifier {
  var logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  @override
  UserFinanceData build() {
    return UserFinanceData(
      listOfGroups: [],
      listOfTransactions: [],
    );
  }

  Future<bool> fetchUserFinanceData(String uid) async {
    List<Transaction> transactions = [];
    try {
      userTransactionsCollection(uid).get().then((value) {
        for (var element in value.docs) {
          transactions.add(element.data());
        }
      }).then((value) {
        state = UserFinanceData(
          listOfGroups: [],
          listOfTransactions: transactions.toList(),
        );
        logger.i(
            "User transaction data fetched successfully. ${state.listOfTransactions?.length}");
      });

      return true;
    } catch (e) {
      logger.w("Failed to fetch user finance data: $e");
      return false;
    }
  }

  Future<bool> updateTransactionTidData({
    required String uid,
    required String tid,
    required Transaction transaction,
  }) async {
    Transaction t = transaction;
    try {
      userTransactionsCollection(uid).doc(tid).update({
        'tid': tid,
      }).then((value) {
        t.tid = tid;
        state.listOfTransactions?.add(t);
      });

      return true;
    } catch (e) {
      logger.w("Error while updating transaction tid: $e");
      return false;
    }
  }
}
