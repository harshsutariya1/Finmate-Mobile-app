import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/goal.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/transaction_category.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/database_references.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

// Provider for GoalsNotifier
final goalsNotifierProvider =
    StateNotifierProvider<GoalsNotifier, List<Goal>>((ref) {
  return GoalsNotifier();
});

class GoalsNotifier extends StateNotifier<List<Goal>> {
  GoalsNotifier() : super([]); // Start with an empty list

  final Logger _logger = Logger();
  final Uuid _uuid = Uuid();

  // Fetch all goals for a user
  Future<void> fetchUserGoals(String uid) async {
    try {
      final snapshot = await userGoalsCollection(uid).get();
      final goals = snapshot.docs.map((doc) => doc.data()).toList();
      state = goals;
      _logger.i("✅ Fetched ${goals.length} goals for user $uid");
    } catch (e, stackTrace) {
      _logger.e("❌ Error fetching goals for user $uid: $e",
          error: e, stackTrace: stackTrace);
      state = []; // Reset state on error
    }
  }

  // Add a new goal with initial contribution from bank account
  Future<bool> addGoal(String uid, Goal goal, WidgetRef ref) async {
    try {
      // Validate goal has bank account if there's an initial contribution
      if (goal.currentAmount > 0 && (goal.primaryBankAccountId == null || goal.primaryBankAccountId!.isEmpty)) {
        _logger.w("❌ Cannot add goal: Missing bank account for initial contribution");
        return false;
      }

      // First, create the goal document
      final docRef = await userGoalsCollection(uid).add(goal);
      final goalId = docRef.id;
      
      // Add contribution if there's an initial amount
      List<GoalContribution> contributions = [];
      if (goal.currentAmount > 0) {
        // Create contribution record
        final contribution = GoalContribution(
          id: _uuid.v4(),
          amount: goal.currentAmount,
          bankAccountId: goal.primaryBankAccountId!,
          bankAccountName: goal.primaryBankAccountName!,
          date: DateTime.now(),
        );
        contributions.add(contribution);
        
        // Transfer money from bank account
        final financeDataNotifier = ref.read(userFinanceDataNotifierProvider.notifier);
        final bankAccount = ref.read(userFinanceDataNotifierProvider).listOfBankAccounts
            ?.firstWhere((b) => b.bid == goal.primaryBankAccountId);
            
        if (bankAccount == null) {
          _logger.e("❌ Bank account not found: ${goal.primaryBankAccountId}");
          return false;
        }
        
        // Create a transaction
        final transaction = Transaction(
          uid: uid,
          amount: (-goal.currentAmount).toString(),
          description: "Initial contribution to goal: ${goal.name}",
          category: SystemCategory.goalContribution.displayName,
          methodOfPayment: PaymentModes.bankAccount.displayName,
          bankAccountId: goal.primaryBankAccountId,
          bankAccountName: goal.primaryBankAccountName,
          transactionType: TransactionType.expense.displayName,
        );
        
        // Add transaction
        final transactionSuccess = await financeDataNotifier.addTransactionToUserData(
          uid: uid,
          transactionData: transaction,
          ref: ref,
        );
        
        if (!transactionSuccess) {
          _logger.e("❌ Failed to create transaction for goal contribution");
          await docRef.delete(); // Clean up the goal we created
          return false;
        }
        
        // Update bank balance
        final bankAvailableBalance = double.parse(bankAccount.availableBalance ?? '0');
        final bankTotalBalance = double.parse(bankAccount.totalBalance ?? '0');
        
        if (bankAvailableBalance < goal.currentAmount) {
          _logger.e("❌ Insufficient funds in bank account");
          await docRef.delete();
          return false;
        }
        
        await financeDataNotifier.updateBankAccountBalance(
          uid: uid,
          bankAccountId: goal.primaryBankAccountId!,
          availableBalance: (bankAvailableBalance - goal.currentAmount).toString(),
          totalBalance: (bankTotalBalance - goal.currentAmount).toString(),
          bankAccount: bankAccount,
          ref: ref,
        );
      }
      
      // Update the goal with ID and contributions
      final newGoal = goal.copyWith(
        id: goalId,
        contributions: contributions,
      );
      
      await docRef.update({'id': goalId, 'contributions': contributions.map((c) => c.toJson()).toList()});
      
      // Update local state
      state = [...state, newGoal];
      _logger.i("✅ Goal '${newGoal.name}' added successfully (ID: ${newGoal.id})");
      return true;
    } catch (e, stackTrace) {
      _logger.e("❌ Error adding goal '${goal.name}': $e",
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Add contribution to a goal
  Future<bool> addContribution(
    String uid, 
    String goalId, 
    double amount, 
    String bankAccountId,
    String bankAccountName,
    WidgetRef ref
  ) async {
    try {
      // Find the goal in our current state
      final goalIndex = state.indexWhere((g) => g.id == goalId);
      if (goalIndex == -1) {
        _logger.w("❌ Goal with ID $goalId not found for contribution");
        return false;
      }
      
      final goal = state[goalIndex];
      
      // Create the new contribution
      final contribution = GoalContribution(
        id: _uuid.v4(),
        amount: amount,
        bankAccountId: bankAccountId,
        bankAccountName: bankAccountName,
        date: DateTime.now(),
      );
      
      // Calculate new amount
      final newAmount = goal.currentAmount + amount;
      final newStatus = newAmount >= goal.targetAmount ? GoalStatus.achieved : goal.status;
      
      // Get bank account
      final financeDataNotifier = ref.read(userFinanceDataNotifierProvider.notifier);
      final bankAccount = ref.read(userFinanceDataNotifierProvider).listOfBankAccounts
          ?.firstWhere((b) => b.bid == bankAccountId);
          
      if (bankAccount == null) {
        _logger.e("❌ Bank account not found: $bankAccountId");
        return false;
      }
      
      // Check funds
      final bankAvailableBalance = double.parse(bankAccount.availableBalance ?? '0');
      if (bankAvailableBalance < amount) {
        _logger.e("❌ Insufficient funds in bank account");
        return false;
      }
      
      // Create transaction
      final transaction = Transaction(
        uid: uid,
        amount: (-amount).toString(),
        description: "Contribution to goal: ${goal.name}",
        category: SystemCategory.goalContribution.displayName,
        methodOfPayment: PaymentModes.bankAccount.displayName,
        bankAccountId: bankAccountId,
        bankAccountName: bankAccountName,
        transactionType: TransactionType.expense.displayName,
      );
      
      // Add transaction
      final transactionSuccess = await financeDataNotifier.addTransactionToUserData(
        uid: uid,
        transactionData: transaction,
        ref: ref,
      );
      
      if (!transactionSuccess) {
        _logger.e("❌ Failed to create transaction for goal contribution");
        return false;
      }
      
      // Update bank balance
      final bankTotalBalance = double.parse(bankAccount.totalBalance ?? '0');
      await financeDataNotifier.updateBankAccountBalance(
        uid: uid,
        bankAccountId: bankAccountId,
        availableBalance: (bankAvailableBalance - amount).toString(),
        totalBalance: (bankTotalBalance - amount).toString(),
        bankAccount: bankAccount,
        ref: ref,
      );
      
      // Update goal
      final updatedContributions = [...goal.contributions, contribution];
      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        status: newStatus,
        contributions: updatedContributions,
      );
      
      // Update in Firestore
      await userGoalsCollection(uid).doc(goalId).update({
        'currentAmount': newAmount,
        'status': newStatus.displayName,
        'contributions': updatedContributions.map((c) => c.toJson()).toList(),
      });
      
      // Update state
      state = [
        for (int i = 0; i < state.length; i++)
          i == goalIndex ? updatedGoal : state[i]
      ];
      
      _logger.i("✅ Added contribution of Rs.$amount to goal '${goal.name}'");
      return true;
    } catch (e, stackTrace) {
      _logger.e("❌ Error adding contribution: $e",
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Update a goal's details
  Future<bool> updateGoal(String uid, Goal updatedGoal) async {
    if (updatedGoal.id == null) {
      _logger.w("❌ Cannot update goal without an ID");
      return false;
    }
    
    try {
      await userGoalsCollection(uid).doc(updatedGoal.id).set(updatedGoal);
      state = state.map((goal) => goal.id == updatedGoal.id ? updatedGoal : goal).toList();
      _logger.i("✅ Goal '${updatedGoal.name}' updated successfully");
      return true;
    } catch (e, stackTrace) {
      _logger.e("❌ Error updating goal '${updatedGoal.name}': $e",
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Delete a goal and return funds to bank account
  Future<bool> deleteGoal(String uid, String goalId, WidgetRef ref) async {
    try {
      // Find goal in state
      final goal = state.firstWhere(
        (g) => g.id == goalId, 
        orElse: () => throw Exception("Goal not found")
      );
      
      // Group contributions by bank account to handle refunds
      final Map<String, double> refundsByBank = {};
      for (var contribution in goal.contributions) {
        final bankId = contribution.bankAccountId;
        refundsByBank[bankId] = (refundsByBank[bankId] ?? 0) + contribution.amount;
      }
      
      // Process refunds for each bank account
      final financeDataNotifier = ref.read(userFinanceDataNotifierProvider.notifier);
      final bankAccounts = ref.read(userFinanceDataNotifierProvider).listOfBankAccounts ?? [];
      
      for (final entry in refundsByBank.entries) {
        final bankId = entry.key;
        final refundAmount = entry.value;
        
        // Find the bank account
        final bankAccount = bankAccounts.firstWhere(
          (b) => b.bid == bankId,
          orElse: () => throw Exception("Bank account $bankId not found")
        );
        
        // Create refund transaction
        final transaction = Transaction(
          uid: uid,
          amount: refundAmount.toString(), // Positive for refund
          description: "Refund from deleted goal: ${goal.name}",
          category: SystemCategory.goalContribution.displayName,
          methodOfPayment: PaymentModes.bankAccount.displayName,
          bankAccountId: bankId,
          bankAccountName: bankAccount.bankAccountName,
          transactionType: TransactionType.income.displayName,
        );
        
        // Add transaction
        await financeDataNotifier.addTransactionToUserData(
          uid: uid,
          transactionData: transaction,
          ref: ref,
        );
        
        // Update bank balance
        final bankAvailableBalance = double.parse(bankAccount.availableBalance ?? '0');
        final bankTotalBalance = double.parse(bankAccount.totalBalance ?? '0');
        await financeDataNotifier.updateBankAccountBalance(
          uid: uid,
          bankAccountId: bankId,
          availableBalance: (bankAvailableBalance + refundAmount).toString(),
          totalBalance: (bankTotalBalance + refundAmount).toString(),
          bankAccount: bankAccount,
          ref: ref,
        );
      }
      
      // Delete goal from Firestore
      await userGoalsCollection(uid).doc(goalId).delete();
      
      // Update state
      state = state.where((goal) => goal.id != goalId).toList();
      _logger.i("✅ Goal '${goal.name}' deleted and funds returned");
      return true;
    } catch (e, stackTrace) {
      _logger.e("❌ Error deleting goal (ID: $goalId): $e",
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Reset state (e.g., on logout)
  void reset() {
    state = [];
    _logger.i("Goals state reset");
  }
}

// Provider to fetch goals initially when user data is loaded
final initialGoalsFetchProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(userDataNotifierProvider);
  if (user.uid != null && user.uid!.isNotEmpty) {
    await ref.read(goalsNotifierProvider.notifier).fetchUserGoals(user.uid!);
  }
});
