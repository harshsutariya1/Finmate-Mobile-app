import 'package:flutter/material.dart';

// Combined map of all category icons (both income and expense)
const Map<String, IconData> transactionCategoriesAndIcons = {
  // Expense categories
  'Food & Drinks': Icons.fastfood,
  'Transport': Icons.directions_bus,
  'Entertainment': Icons.movie,
  'Utilities': Icons.lightbulb,
  'Health': Icons.local_hospital,
  'Shopping': Icons.shopping_cart,
  'Education': Icons.school,
  'Housing': Icons.home,
  'Personal': Icons.person,
  'Clothing': Icons.checkroom,

  // Income categories
  'Salary': Icons.attach_money,
  'Investment': Icons.trending_up,
  'Refund or Bonus': Icons.refresh_rounded,
  'Gifts': Icons.card_giftcard,
  'Business': Icons.business,
  'Pension': Icons.elderly,
  'Rental': Icons.apartment,

  // Common categories
  'Others': Icons.category,
  'Balance Adjustment': Icons.account_balance_wallet_rounded,
  'Transfer': Icons.swap_horiz,

  // Add goal contribution category
  'Goal Contribution': Icons.savings,
  'Goal Refund': Icons.savings_outlined,
};

// Separated expense categories
enum ExpenseCategory {
  foodAndDrinks,
  transport,
  entertainment,
  utilities,
  health,
  shopping,
  education,
  housing,
  personal,
  clothing,
  others,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.foodAndDrinks:
        return 'Food & Drinks';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.housing:
        return 'Housing';
      case ExpenseCategory.personal:
        return 'Personal';
      case ExpenseCategory.clothing:
        return 'Clothing';
      case ExpenseCategory.others:
        return 'Others';
    }
  }

  IconData get icon {
    return transactionCategoriesAndIcons[displayName] ?? Icons.category;
  }
}

// Separated income categories
enum IncomeCategory {
  salary,
  investment,
  refundOrBonus,
  gifts,
  business,
  pension,
  rental,
  others,
}

extension IncomeCategoryExtension on IncomeCategory {
  String get displayName {
    switch (this) {
      case IncomeCategory.salary:
        return 'Salary';
      case IncomeCategory.investment:
        return 'Investment';
      case IncomeCategory.refundOrBonus:
        return 'Refund or Bonus';
      case IncomeCategory.gifts:
        return 'Gifts';
      case IncomeCategory.business:
        return 'Business';
      case IncomeCategory.pension:
        return 'Pension';
      case IncomeCategory.rental:
        return 'Rental';
      case IncomeCategory.others:
        return 'Others';
    }
  }

  IconData get icon {
    return transactionCategoriesAndIcons[displayName] ?? Icons.category;
  }
}

// Special categories for system operations
enum SystemCategory {
  balanceAdjustment,
  transfer,
  goalContribution, // Added new category for goal contributions
}

extension SystemCategoryExtension on SystemCategory {
  String get displayName {
    switch (this) {
      case SystemCategory.balanceAdjustment:
        return 'Balance Adjustment';
      case SystemCategory.transfer:
        return 'Transfer';
      case SystemCategory.goalContribution:
        return 'Goal Contribution';
    }
  }

  IconData get icon {
    return transactionCategoriesAndIcons[displayName] ?? Icons.category;
  }
}

// Helper methods to get all categories of each type
class CategoryHelpers {
  static List<String> getAllExpenseCategories() {
    return ExpenseCategory.values.map((e) => e.displayName).toList();
  }

  static List<String> getAllIncomeCategories() {
    return IncomeCategory.values.map((e) => e.displayName).toList();
  }

  static List<String> getAllSystemCategories() {
    return SystemCategory.values.map((e) => e.displayName).toList();
  }

  static IconData getIconForCategory(String categoryName) {
    return transactionCategoriesAndIcons[categoryName] ?? Icons.category;
  }

  static bool isIncomeCategory(String categoryName) {
    return IncomeCategory.values.any((e) => e.displayName == categoryName);
  }

  static bool isExpenseCategory(String categoryName) {
    return ExpenseCategory.values.any((e) => e.displayName == categoryName);
  }

  static bool isSystemCategory(String categoryName) {
    return SystemCategory.values.any((e) => e.displayName == categoryName);
  }
}
