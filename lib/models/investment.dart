import 'package:cloud_firestore/cloud_firestore.dart';

class Investment {
  final String id;
  final String uid;
  final String name;
  final String type;
  final double initialAmount;
  final double currentAmount;
  final double targetAmount;
  final double progressPercentage;
  final DateTime purchaseDate;
  final DateTime? maturityDate;
  final List<Map<String, dynamic>> valueHistory;
  final String notes;
  final String institution;
  final String accountNumber;
  final bool isActive;

  Investment({
    required this.id,
    required this.uid,
    required this.name,
    required this.type,
    required this.initialAmount,
    required this.currentAmount,
    this.targetAmount = 0,
    required this.progressPercentage,
    required this.purchaseDate,
    this.maturityDate,
    this.valueHistory = const [],
    this.notes = '',
    this.institution = '',
    this.accountNumber = '',
    this.isActive = true,
  });

  double get totalReturn => currentAmount - initialAmount;
  
  double get returnPercentage => 
      initialAmount > 0 ? (totalReturn / initialAmount) * 100 : 0;

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Others',
      initialAmount: (json['initialAmount'] ?? 0.0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0.0).toDouble(),
      targetAmount: (json['targetAmount'] ?? 0.0).toDouble(),
      progressPercentage: (json['progressPercentage'] ?? 0.0).toDouble(),
      purchaseDate: (json['purchaseDate'] as Timestamp).toDate(),
      maturityDate: json['maturityDate'] != null
          ? (json['maturityDate'] as Timestamp).toDate()
          : null,
      valueHistory: List<Map<String, dynamic>>.from(json['valueHistory'] ?? []),
      notes: json['notes'] ?? '',
      institution: json['institution'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'type': type,
      'initialAmount': initialAmount,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'progressPercentage': progressPercentage,
      'purchaseDate': purchaseDate,
      'maturityDate': maturityDate,
      'valueHistory': valueHistory,
      'notes': notes,
      'institution': institution,
      'accountNumber': accountNumber,
      'isActive': isActive,
    };
  }

  Investment copyWith({
    String? id,
    String? uid,
    String? name,
    String? type,
    double? initialAmount,
    double? currentAmount,
    double? targetAmount,
    double? progressPercentage,
    DateTime? purchaseDate,
    DateTime? maturityDate,
    List<Map<String, dynamic>>? valueHistory,
    String? notes,
    String? institution,
    String? accountNumber,
    bool? isActive,
  }) {
    return Investment(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      type: type ?? this.type,
      initialAmount: initialAmount ?? this.initialAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      maturityDate: maturityDate ?? this.maturityDate,
      valueHistory: valueHistory ?? this.valueHistory,
      notes: notes ?? this.notes,
      institution: institution ?? this.institution,
      accountNumber: accountNumber ?? this.accountNumber,
      isActive: isActive ?? this.isActive,
    );
  }

  // Add a new value entry to the history
  Investment addValueEntry(double amount) {
    final now = DateTime.now();
    final newEntry = {
      'date': now,
      'value': amount,
    };
    
    final updatedHistory = List<Map<String, dynamic>>.from(valueHistory)
      ..add(newEntry);
      
    return copyWith(
      currentAmount: amount,
      progressPercentage: targetAmount > 0 
          ? (amount / targetAmount * 100).clamp(0.0, 100.0) 
          : 0.0,
      valueHistory: updatedHistory,
    );
  }
}
