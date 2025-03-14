import 'package:flutter/material.dart';

const Map<String, IconData> transactionCategoriesAndIcons = {
  'Food & Drinks': Icons.fastfood,
  'Transport': Icons.directions_bus,
  'Entertainment': Icons.movie,
  'Utilities': Icons.lightbulb,
  'Health': Icons.local_hospital,
  'Shopping': Icons.shopping_cart,
  'Education': Icons.school,
  'Salary': Icons.attach_money,
  'Investment': Icons.trending_up,
  'Others': Icons.category,
  'Balance Adjustment': Icons.account_balance_wallet_rounded,
};

enum TransactionType {
  expense,
  income,
  transfer,
}

class Transaction {
  String? tid;
  String? amount;
  DateTime? date;
  TimeOfDay? time;
  String? uid;
  String? category;
  String? methodOfPayment;
  String? description;
  TransactionType? type;
  bool isGroupTransaction;
  String? gid;
  String? bankAccountId; // New field for bank account ID
  String? walletId; // New field for wallet ID

  Transaction({
    this.tid = "",
    this.amount = "0",
    DateTime? date,
    this.time,
    this.uid = "",
    this.category = "Others",
    this.methodOfPayment = "Cash",
    this.description = "",
    this.type,
    this.isGroupTransaction = false,
    this.gid,
    this.bankAccountId, // Initialize as null
    this.walletId, // Initialize as null
  }) : date = date ?? DateTime.now() {
    time = time ?? TimeOfDay.now();
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      tid: json['tid'] as String? ?? "",
      description: json['description'] as String? ?? "",
      amount: json['amount'] as String? ?? "0",
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      time: (json['time'] != null)
          ? TimeOfDay(
              hour: int.parse(json['time'].split(":")[0]),
              minute: int.parse(json['time'].split(":")[1]),
            )
          : TimeOfDay.now(),
      uid: json['uid'] as String? ?? "",
      category: json['category'] as String? ?? "Others",
      methodOfPayment: json['methodOfPayment'] as String? ?? "Cash",
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.expense,
      ),
      isGroupTransaction: json['isGroupTransaction'] as bool? ?? false,
      gid: json['gid'] as String?,
      bankAccountId: json['bankAccountId'] as String?, // Parse bank account ID
      walletId: json['walletId'] as String?, // Parse wallet ID
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'description': description,
      'amount': amount,
      'date': date?.toIso8601String(),
      'time': '${time?.hour}:${time?.minute}',
      'uid': uid,
      'category': category,
      'methodOfPayment': methodOfPayment,
      'type': type?.toString().split('.').last,
      'isGroupTransaction': isGroupTransaction,
      'gid': gid,
      'bankAccountId': bankAccountId, // Add bank account ID to JSON
      'walletId': walletId, // Add wallet ID to JSON
    };
  }
}