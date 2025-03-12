// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';

class UserFinanceData {
  List<Transaction>? listOfUserTransactions;
  List<Group>? listOfGroups;
  List<BankAccount>? listOfBankAccounts;
  Cash? cash;

  UserFinanceData({
    this.listOfUserTransactions = const [],
    this.listOfGroups = const [],
    this.listOfBankAccounts = const [],
    this.cash,
  });

  UserFinanceData copyWith({
    List<Transaction>? listOfUserTransactions,
    List<Group>? listOfGroups,
    List<BankAccount>? listOfBankAccounts,
    Cash? cash,
  }) {
    return UserFinanceData(
      listOfUserTransactions:
          listOfUserTransactions ?? this.listOfUserTransactions,
      listOfGroups: listOfGroups ?? this.listOfGroups,
      listOfBankAccounts: listOfBankAccounts ?? this.listOfBankAccounts,
      cash: cash ?? this.cash,
    );
  }
}
