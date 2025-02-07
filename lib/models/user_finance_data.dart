import 'package:finmate/models/groups.dart';
import 'package:finmate/models/transaction.dart';

class UserFinanceData {
  List<Transaction>? listOfTransactions;
  List<Group>? listOfGroups;

  UserFinanceData({
    this.listOfTransactions = const [],
    this.listOfGroups = const [],
  });
}
