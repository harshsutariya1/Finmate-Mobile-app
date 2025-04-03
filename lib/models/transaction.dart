// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

enum TransactionType {
  expense,
  income,
  transfer,
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

enum PaymentModes {
  cash,
  bankAccount,
  group,
}

extension PaymentModeExtension on PaymentModes {
  String get displayName {
    switch (this) {
      case PaymentModes.cash:
        return 'Cash';
      case PaymentModes.bankAccount:
        return 'Bank Account';

      case PaymentModes.group:
        return 'Group';
    }
  }
}

class Transaction {
  String? tid;
  String? amount;
  DateTime? date;
  TimeOfDay? time;
  String? uid;
  String? category;
  String? methodOfPayment;
  String? methodOfPayment2;
  String? payee;
  String? description;
  String? transactionType;
  bool isGroupTransaction;
  String? gid;
  String? groupName;
  String? bankAccountId;
  String? bankAccountName;
  bool isTransferTransaction;
  String? gid2;
  String? groupName2;
  String? bankAccountId2;
  String? bankAccountName2;
  String? vpaId;

  Transaction({
    this.tid = "",
    this.amount = "0",
    DateTime? date,
    this.time,
    this.uid = "",
    this.category = "Others",
    this.methodOfPayment = "Cash",
    this.methodOfPayment2,
    this.payee = "",
    this.description = "",
    this.transactionType,
    this.isGroupTransaction = false,
    this.gid,
    this.groupName,
    this.bankAccountId,
    this.bankAccountName,
    this.isTransferTransaction = false,
    this.gid2,
    this.groupName2,
    this.bankAccountId2,
    this.bankAccountName2,
    this.vpaId,
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
      methodOfPayment2: json['methodOfPayment2'] as String?,
      payee: json['payee'] as String? ?? "",
      transactionType: json['transactionType'] as String?,
      isGroupTransaction: json['isGroupTransaction'] as bool? ?? false,
      gid: json['gid'] as String?,
      groupName: json['groupName'] as String?,
      bankAccountId: json['bankAccountId'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
      isTransferTransaction: json['isTransferTransaction'] as bool? ?? false,
      gid2: json['gid2'] as String?,
      groupName2: json['groupName2'] as String?,
      bankAccountId2: json['bankAccountId2'] as String?,
      bankAccountName2: json['bankAccountName2'] as String?,
      vpaId: json['vpaId'] as String? ?? "",
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
      'methodOfPayment2': methodOfPayment2,
      'payee': payee,
      'transactionType': transactionType,
      'isGroupTransaction': isGroupTransaction,
      'gid': gid,
      'groupName': groupName,
      'bankAccountId': bankAccountId,
      'bankAccountName': bankAccountName,
      'isTransferTransaction': isTransferTransaction,
      'gid2': gid2,
      'groupName2': groupName2,
      'bankAccountId2': bankAccountId2,
      'bankAccountName2': bankAccountName2,
      'vpaId': vpaId,
    };
  }

  Transaction copyWith({
    String? tid,
    String? amount,
    DateTime? date,
    TimeOfDay? time,
    String? uid,
    String? category,
    String? methodOfPayment,
    String? methodOfPayment2,
    String? payee,
    String? transactionType,
    String? description,
    bool? isGroupTransaction,
    String? gid,
    String? groupName,
    String? bankAccountId,
    String? bankAccountName,
    bool? isTransferTransaction,
    String? gid2,
    String? groupName2,
    String? bankAccountId2,
    String? bankAccountName2,
    String? vpaId,
  }) {
    return Transaction(
      tid: tid ?? this.tid,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      uid: uid ?? this.uid,
      category: category ?? this.category,
      methodOfPayment: methodOfPayment ?? this.methodOfPayment,
      methodOfPayment2: methodOfPayment2 ?? this.methodOfPayment2,
      payee: payee ?? this.payee,
      transactionType: transactionType ?? this.transactionType,
      description: description ?? this.description,
      isGroupTransaction: isGroupTransaction ?? this.isGroupTransaction,
      gid: gid ?? this.gid,
      groupName: groupName ?? this.groupName,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      isTransferTransaction:
          isTransferTransaction ?? this.isTransferTransaction,
      gid2: gid2 ?? this.gid2,
      groupName2: groupName2 ?? this.groupName2,
      bankAccountId2: bankAccountId2 ?? this.bankAccountId2,
      vpaId: vpaId ?? this.vpaId,
    );
  }
}
