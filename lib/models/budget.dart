class Budget {
  String? bid;
  DateTime? date;
  String? totalBudget;
  String? spendings;
  Map<String, Map<String, String>>? categoryBudgets;

  Budget({
    this.bid = "",
    DateTime? date,
    this.totalBudget = "0",
    this.spendings = "0",
    this.categoryBudgets,
  }) {
    date = date ?? DateTime.now();
    categoryBudgets = categoryBudgets ?? {};
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      bid: json['bid'] as String?,
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      totalBudget: json['totalBudget'] as String? ?? "0",
      spendings: json['spendings'] as String? ?? "0",
      categoryBudgets: json['categoryBudgets'] != null
          ? Map<String, Map<String, String>>.from(
              json['categoryBudgets'].map(
                (key, value) => MapEntry(
                  key,
                  Map<String, String>.from(value),
                ),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bid': bid,
      'date': date?.toIso8601String(),
      'totalBudget': totalBudget,
      'spendings': spendings,
      'categoryBudgets': categoryBudgets,
    };
  }

  Budget copyWith({
    String? bid,
    DateTime? date,
    String? totalBudget,
    String? spendings,
    Map<String, Map<String, String>>? categoryBudgets,
  }) {
    return Budget(
      bid: bid ?? this.bid,
      date: date ?? this.date,
      totalBudget: totalBudget ?? this.totalBudget,
      spendings: spendings ?? this.spendings,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
    );
  }
}
