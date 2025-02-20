import 'package:flutter/material.dart';

const Map<String, IconData> transactionCategoriesAndIcons = {
  'Food': Icons.fastfood,
  'Transport': Icons.directions_bus,
  'Entertainment': Icons.movie,
  'Utilities': Icons.lightbulb,
  'Health': Icons.local_hospital,
  'Shopping': Icons.shopping_cart,
  'Education': Icons.school,
  'Salary': Icons.attach_money,
  'Investment': Icons.trending_up,
  'Others': Icons.category,
};

const List<String> transactionCategories = [
  'Food',
  'Transport',
  'Entertainment',
  'Utilities',
  'Health',
  'Shopping',
  'Education',
  'Salary',
  'Investment',
  'Others',
];

// const List<IconData> transactionCategoryIcons = [
//   Icons.fastfood,        // Food
//   Icons.directions_bus,  // Transport
//   Icons.movie,           // Entertainment
//   Icons.lightbulb,       // Utilities
//   Icons.local_hospital,  // Health
//   Icons.shopping_cart,   // Shopping
//   Icons.school,          // Education
//   Icons.attach_money,    // Salary
//   Icons.trending_up,     // Investment
//   Icons.category,        // Others
// ];

class Transaction {
  String? tid;
  String? amount;
  DateTime? date;
  String? uid;
  String? category;
  String? methodOfPayment;
  String? description;

  Transaction({
    this.tid = "",
    this.amount = "0",
    DateTime? date,
    this.uid = "",
    this.category = "",
    this.methodOfPayment = "",
    this.description = "",
  }) : date = date ?? DateTime.now();

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      tid: json['tid'] as String,
      description: json['description'] as String,
      amount: json['amount'] as String,
      date: DateTime.parse(json['date']),
      uid: json['uid'] as String,
      category: json['category'] as String,
      methodOfPayment: json['methodOfPayment'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'description': description,
      'amount': amount,
      'date': date?.toIso8601String(),
      'uid': uid,
      'category': category,
      'methodOfPayment': methodOfPayment,
    };
  }
}
