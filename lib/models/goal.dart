import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum GoalStatus { active, achieved, archived }

extension GoalStatusExtension on GoalStatus {
  String get displayName {
    switch (this) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.achieved:
        return 'Achieved';
      case GoalStatus.archived:
        return 'Archived';
    }
  }

  static GoalStatus fromString(String? statusString) {
    return GoalStatus.values.firstWhere(
      (e) => e.displayName.toLowerCase() == statusString?.toLowerCase(),
      orElse: () => GoalStatus.active,
    );
  }
}

class GoalContribution {
  final String id;
  final double amount;
  final String bankAccountId;
  final String bankAccountName;
  final DateTime date;
  
  GoalContribution({
    required this.id,
    required this.amount,
    required this.bankAccountId,
    required this.bankAccountName,
    required this.date,
  });
  
  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    return GoalContribution(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      bankAccountId: json['bankAccountId'],
      bankAccountName: json['bankAccountName'],
      date: (json['date'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'bankAccountId': bankAccountId,
      'bankAccountName': bankAccountName,
      'date': Timestamp.fromDate(date),
    };
  }
}

class Goal {
  String? id;
  String name;
  double targetAmount;
  double currentAmount;
  DateTime? deadline;
  DateTime creationDate;
  String? iconName;
  String? notes;
  GoalStatus status;
  List<GoalContribution> contributions;
  String? primaryBankAccountId; // ID of main bank account associated with goal
  String? primaryBankAccountName; // Name of main bank account

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    DateTime? creationDate,
    this.iconName,
    this.notes,
    this.status = GoalStatus.active,
    List<GoalContribution>? contributions,
    this.primaryBankAccountId,
    this.primaryBankAccountName,
  }) : 
      creationDate = creationDate ?? DateTime.now(),
      contributions = contributions ?? [];

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, targetAmount);
  }

  bool get isAchieved => currentAmount >= targetAmount;

  factory Goal.fromJson(Map<String, dynamic> json) {
    final List<GoalContribution> contributions = [];
    if (json['contributions'] != null) {
      for (var contribution in json['contributions']) {
        contributions.add(GoalContribution.fromJson(contribution));
      }
    }
    
    return Goal(
      id: json['id'] as String?,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num? ?? 0.0).toDouble(),
      deadline: (json['deadline'] as Timestamp?)?.toDate(),
      creationDate: (json['creationDate'] as Timestamp).toDate(),
      iconName: json['iconName'] as String?,
      notes: json['notes'] as String?,
      status: GoalStatusExtension.fromString(json['status'] as String?),
      contributions: contributions,
      primaryBankAccountId: json['primaryBankAccountId'] as String?,
      primaryBankAccountName: json['primaryBankAccountName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'creationDate': Timestamp.fromDate(creationDate),
      'iconName': iconName,
      'notes': notes,
      'status': status.displayName,
      'contributions': contributions.map((e) => e.toJson()).toList(),
      'primaryBankAccountId': primaryBankAccountId,
      'primaryBankAccountName': primaryBankAccountName,
    };
  }

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    DateTime? creationDate,
    String? iconName,
    String? notes,
    GoalStatus? status,
    List<GoalContribution>? contributions,
    String? primaryBankAccountId,
    String? primaryBankAccountName,
    bool setDeadlineToNull = false,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: setDeadlineToNull ? null : (deadline ?? this.deadline),
      creationDate: creationDate ?? this.creationDate,
      iconName: iconName ?? this.iconName,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      contributions: contributions ?? this.contributions,
      primaryBankAccountId: primaryBankAccountId ?? this.primaryBankAccountId,
      primaryBankAccountName: primaryBankAccountName ?? this.primaryBankAccountName,
    );
  }
}
