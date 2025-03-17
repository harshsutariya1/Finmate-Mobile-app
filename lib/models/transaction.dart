// ignore_for_file: public_member_api_docs, sort_constructors_first
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
  'Refund or Bonus': Icons.refresh_rounded,
  'Others': Icons.category,
  'Balance Adjustment': Icons.account_balance_wallet_rounded,
  'Transfer': Icons.swap_horiz,
};

enum TransactionCategory {
  foodAndDrinks,
  transport,
  entertainment,
  utilities,
  health,
  shopping,
  education,
  salary,
  investment,
  refundOrBonus,
  others,
  balanceAdjustment,
  transfer,
}

extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.foodAndDrinks:
        return 'Food & Drinks';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.refundOrBonus:
        return 'Refund or Bonus';
      case TransactionCategory.others:
        return 'Others';
      case TransactionCategory.balanceAdjustment:
        return 'Balance Adjustment';
      case TransactionCategory.transfer:
        return 'Transfer';
    }
  }

  IconData get icon {
    return transactionCategoriesAndIcons[displayName] ?? Icons.category;
  }
}

enum TransactionType {
  expense,
  income,
  transfer,
}

enum PaymentModes {
  cash,
  bankAccount,
  wallet,
  group,
}

extension PaymentModeExtension on PaymentModes {
  String get displayName {
    switch (this) {
      case PaymentModes.cash:
        return 'Cash';
      case PaymentModes.bankAccount:
        return 'Bank Account';
      case PaymentModes.wallet:
        return 'Wallet';
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
  String? description;
  TransactionType? type;
  bool isGroupTransaction;
  String? gid;
  String? groupName;
  String? bankAccountId;
  String? walletId;
  bool isTransferTransaction;
  String? gid2;
  String? groupName2;
  String? bankAccountId2;
  String? walletId2;
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
    this.description = "",
    this.type,
    this.isGroupTransaction = false,
    this.gid,
    this.groupName,
    this.bankAccountId,
    this.walletId,
    this.isTransferTransaction = false,
    this.gid2,
    this.groupName2,
    this.bankAccountId2,
    this.walletId2,
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
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.expense,
      ),
      isGroupTransaction: json['isGroupTransaction'] as bool? ?? false,
      gid: json['gid'] as String?,
      groupName: json['groupName'] as String?,
      bankAccountId: json['bankAccountId'] as String?,
      walletId: json['walletId'] as String?,
      isTransferTransaction: json['isTransferTransaction'] as bool? ?? false,
      gid2: json['gid2'] as String?,
      groupName2: json['groupName2'] as String?,
      bankAccountId2: json['bankAccountId2'] as String?,
      walletId2: json['walletId2'] as String?,
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
      'type': type?.toString().split('.').last,
      'isGroupTransaction': isGroupTransaction,
      'gid': gid,
      'groupName': groupName,
      'bankAccountId': bankAccountId,
      'walletId': walletId,
      'isTransferTransaction': isTransferTransaction,
      'gid2': gid2,
      'groupName2': groupName2,
      'bankAccountId2': bankAccountId2,
      'walletId2': walletId2,
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
    String? description,
    bool? isGroupTransaction,
    String? gid,
    String? groupName,
    String? bankAccountId,
    String? walletId,
    bool? isTransferTransaction,
    String? gid2,
    String? groupName2,
    String? bankAccountId2,
    String? walletId2,
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
      description: description ?? this.description,
      isGroupTransaction: isGroupTransaction ?? this.isGroupTransaction,
      gid: gid ?? this.gid,
      groupName: groupName ?? this.groupName,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      walletId: walletId ?? this.walletId,
      isTransferTransaction:
          isTransferTransaction ?? this.isTransferTransaction,
      gid2: gid2 ?? this.gid2,
      groupName2: groupName2 ?? this.groupName2,
      bankAccountId2: bankAccountId2 ?? this.bankAccountId2,
      walletId2: walletId2 ?? this.walletId2,
      vpaId: vpaId ?? this.vpaId,
    );
  }
}
