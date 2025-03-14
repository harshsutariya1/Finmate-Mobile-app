// ignore_for_file: public_member_api_docs, sort_constructors_first
class Cash {
  String? amount;

  Cash({
    this.amount = "0",
  });

  factory Cash.fromJson(Map<String, dynamic> json) {
    return Cash(
      amount: json['amount'] ?? "0.0",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
    };
  }
}

// _________________________________________________________________________ //

class BankAccount {
  String? bid;
  String? bankAccountName;
  String? totalBalance;
  String? availableBalance;
  List<String>? upiIds;
  List<String>? linkedGroupIds;
  Map<String, String>? groupsBalance;

  BankAccount({
    this.bid = "",
    this.bankAccountName = "",
    this.totalBalance = "",
    this.availableBalance = "",
    this.upiIds = const [],
    this.linkedGroupIds = const [],
    this.groupsBalance = const {},
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      bid: json['bid'] ?? "",
      bankAccountName: json['bankAccountName'] ?? "",
      totalBalance: json['totalBalance'] ?? "",
      availableBalance: json['availableBalance'] ?? "",
      upiIds: List<String>.from(json['upiIds'] ?? []),
      linkedGroupIds: List<String>.from(json['linkedGroupIds'] ?? []),
      groupsBalance: Map<String, String>.from(json['groupsBalance'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bid': bid,
      'bankAccountName': bankAccountName,
      'totalBalance': totalBalance,
      'availableBalance': availableBalance,
      'upiIds': upiIds,
      'linkedGroupIds': linkedGroupIds,
      'groupsBalance': groupsBalance,
    };
  }

  BankAccount copyWith({
    String? bid,
    String? bankAccountName,
    String? totalBalance,
    String? availableBalance,
    List<String>? upiIds,
    List<String>? linkedGroupIds,
    Map<String, String>? groupsBalance,
  }) {
    return BankAccount(
      bid: bid ?? this.bid,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      totalBalance: totalBalance ?? this.totalBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      upiIds: upiIds ?? this.upiIds,
      linkedGroupIds: linkedGroupIds ?? this.linkedGroupIds,
      groupsBalance: groupsBalance ?? this.groupsBalance,
    );
  }
}

// _________________________________________________________________________ //

class Wallet {
  String? wid;
  String? walletName;
  String? balance;

  Wallet({
    this.wid = "",
    this.walletName = "",
    this.balance = "0",
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      wid: json['wid'] ?? "",
      walletName: json['walletName'] ?? "",
      balance: json['balance'] ?? "0",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wid': wid,
      'walletName': walletName,
      'balance': balance,
    };
  }

  Wallet copyWith({
    String? wid,
    String? walletName,
    String? balance,
  }) {
    return Wallet(
      wid: wid ?? this.wid,
      walletName: walletName ?? this.walletName,
      balance: balance ?? this.balance,
    );
  }
}