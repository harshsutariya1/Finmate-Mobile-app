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
  String? name;
  String? amount;

  BankAccount({
    this.name = "",
    this.amount = "0",
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      name: json['name'] ?? "",
      amount: json['amount']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}

// _________________________________________________________________________ //
