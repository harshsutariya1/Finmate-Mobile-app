import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';

class UserFinanceData {
  List<Transaction>? listOfUserTransactions;
  List<Group>? listOfGroups;
  List<BankAccount>? listOfBankAccounts;
  List<Wallet>? listOfWallets;
  Cash? cash;

  UserFinanceData({
    this.listOfUserTransactions = const [],
    this.listOfGroups = const [],
    this.listOfBankAccounts = const [],
    this.listOfWallets = const [],
    this.cash,
  });

  UserFinanceData copyWith({
    List<Transaction>? listOfUserTransactions,
    List<Group>? listOfGroups,
    List<BankAccount>? listOfBankAccounts,
    List<Wallet>? listOfWallets,
    Cash? cash,
  }) {
    return UserFinanceData(
      listOfUserTransactions:
          listOfUserTransactions ?? this.listOfUserTransactions,
      listOfGroups: listOfGroups ?? this.listOfGroups,
      listOfBankAccounts: listOfBankAccounts ?? this.listOfBankAccounts,
      listOfWallets: listOfWallets ?? this.listOfWallets,
      cash: cash ?? this.cash,
    );
  }
}