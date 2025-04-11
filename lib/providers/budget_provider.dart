import 'package:finmate/models/budget.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/services/database_references.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// Provider for BudgetNotifier
final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  return BudgetNotifier();
});

class BudgetNotifier extends StateNotifier<List<Budget>> {
  BudgetNotifier() : super([]);
  final logger = Logger();

  /// Fetches all budgets for a user
  Future<void> fetchUserBudgets(String uid) async {
    try {
      final budgetDocs = await userBudgetsCollection(uid).get();
      final budgets = budgetDocs.docs.map((doc) => doc.data()).toList();

      // Sort budgets by date, newest first
      budgets.sort((a, b) =>
          (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));

      state = budgets;
      logger.i("✅ Fetched ${budgets.length} budgets for user $uid");
    } catch (e) {
      logger.e("❌ Error fetching budgets: $e");
      state = [];
    }
  }

  /// Creates a new budget
  Future<bool> createBudget(String uid, Budget budget) async {
    try {
      // Check if a budget for this month already exists
      final existingBudget = state
          .where((b) =>
              b.date?.year == budget.date?.year &&
              b.date?.month == budget.date?.month)
          .toList();

      if (existingBudget.isNotEmpty) {
        logger.w("⚠️ A budget for this month already exists");
        return await updateBudget(uid, budget);
      }

      // Create a new budget document
      final budgetRef = userBudgetsCollection(uid).doc();
      final budgetWithId = budget.copyWith(bid: budgetRef.id);

      await budgetRef.set(budgetWithId);

      // Update local state
      state = [budgetWithId, ...state];

      logger.i("✅ Budget created successfully");
      return true;
    } catch (e) {
      logger.e("❌ Error creating budget: $e");
      return false;
    }
  }

  /// Updates an existing budget
  Future<bool> updateBudget(String uid, Budget budget) async {
    try {
      // Find the existing budget for this month
      final existingBudget = state.firstWhere(
        (b) =>
            b.date?.year == budget.date?.year &&
            b.date?.month == budget.date?.month,
        orElse: () => budget,
      );

      // If no existing budget, create new one
      if (existingBudget.bid == null || existingBudget.bid!.isEmpty) {
        return await createBudget(uid, budget);
      }

      // Update with the existing ID
      final updatedBudget = budget.copyWith(bid: existingBudget.bid);

      await userBudgetsCollection(uid)
          .doc(existingBudget.bid)
          .set(updatedBudget);

      // Update state
      state = state
          .map((b) => (b.bid == existingBudget.bid) ? updatedBudget : b)
          .toList();

      logger.i("✅ Budget updated successfully");
      return true;
    } catch (e) {
      logger.e("❌ Error updating budget: $e");
      return false;
    }
  }

  /// Updates category spending based on a new transaction
  Future<bool> updateBudgetWithTransaction(
      String uid, Transaction transaction) async {
    try {
      // Skip if not an expense transaction
      if (transaction.transactionType != TransactionType.expense.displayName) {
        return true;
      }

      // Find the budget for the transaction month
      final transactionDate = transaction.date;
      if (transactionDate == null) return false;

      final budget = state.firstWhere(
        (b) =>
            b.date?.year == transactionDate.year &&
            b.date?.month == transactionDate.month,
        orElse: () => Budget(),
      );

      // Skip if no budget found for this month
      if (budget.bid == null || budget.bid!.isEmpty) {
        return true;
      }

      // Get transaction amount (remove minus sign if present)
      final amount =
          double.tryParse(transaction.amount?.replaceAll('-', '') ?? '0') ?? 0;

      // Update total spending
      final currentSpending = double.tryParse(budget.spendings ?? '0') ?? 0;
      final newTotalSpending = (currentSpending + amount).toString();

      // Update category spending if applicable
      final categoryName = transaction.category;
      final categoryBudgets =
          Map<String, Map<String, String>>.from(budget.categoryBudgets ?? {});

      if (categoryName != null && categoryBudgets.containsKey(categoryName)) {
        final categoryData =
            Map<String, String>.from(categoryBudgets[categoryName]!);

        // Update spent amount
        final categorySpent =
            double.tryParse(categoryData['spent'] ?? '0') ?? 0;
        final newCategorySpent = categorySpent + amount;
        categoryData['spent'] = newCategorySpent.toString();

        // Update remaining amount
        final allocated =
            double.tryParse(categoryData['allocated'] ?? '0') ?? 0;
        final newRemaining = allocated - newCategorySpent;
        categoryData['remaining'] = newRemaining.toString();

        // Update percentage
        final newPercentage = allocated > 0
            ? ((newCategorySpent / allocated) * 100).clamp(0, 100)
            : 0.0;
        categoryData['percentage'] = newPercentage.toString();

        // Update the category in the map
        categoryBudgets[categoryName] = categoryData;
      }

      // Create updated budget object
      final updatedBudget = budget.copyWith(
        spendings: newTotalSpending,
        categoryBudgets: categoryBudgets,
      );

      // Save to Firestore
      await userBudgetsCollection(uid).doc(budget.bid).set(updatedBudget);

      // Update state
      state =
          state.map((b) => b.bid == budget.bid ? updatedBudget : b).toList();

      logger.i("✅ Budget updated with transaction successfully");
      return true;
    } catch (e) {
      logger.e("❌ Error updating budget with transaction: $e");
      return false;
    }
  }

  /// Deletes a budget
  Future<bool> deleteBudget(String uid, String budgetId) async {
    try {
      await userBudgetsCollection(uid).doc(budgetId).delete();

      // Update local state
      state = state.where((budget) => budget.bid != budgetId).toList();

      logger.i("✅ Budget deleted successfully: $budgetId");
      return true;
    } catch (e) {
      logger.e("❌ Error deleting budget: $e");
      return false;
    }
  }

  /// Resets the budget state
  void reset() {
    state = [];
    logger.i("Budget state reset");
  }
}
