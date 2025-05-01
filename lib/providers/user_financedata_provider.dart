// Provider for UserFinanceDataNotifier
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/budget.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/transaction_category.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/budget_provider.dart';
import 'package:finmate/services/database_references.dart';
import 'package:finmate/services/database_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final userFinanceDataNotifierProvider =
    StateNotifierProvider<UserFinanceDataNotifier, UserFinanceData>((ref) {
  return UserFinanceDataNotifier();
});

class UserFinanceDataNotifier extends StateNotifier<UserFinanceData> {
  UserFinanceDataNotifier() : super(UserFinanceData());
  var logger = Logger();

  Future<bool> fetchUserFinanceData(String uid) async {
    List<Transaction> transactions = [];
    List<Group> groups = [];
    List<BankAccount> bankAccounts = [];
    Cash? cash = Cash();
    try {
      // fetch user transactions data
      await userTransactionsCollection(uid).get().then((value) {
        for (var element in value.docs) {
          transactions.add(element.data());
        }
      });
      // fetch cash data
      await userCashDocument(uid).get().then((value) {
        cash = value.data();
      });

      // fetch bank accounts data
      await bankAccountsCollectionReference(uid).get().then((value) {
        for (var doc in value.docs) {
          bankAccounts.add(doc.data());
        }
      });

      await groupsCollection.get().then((value) async {
        for (var group in value.docs) {
          if (group.data().memberIds?.contains(uid) ?? false) {
            final currentGroup = group.data();
            // fetch group transactions
            await groupTansactionCollection(currentGroup.gid!)
                .get()
                .then((transactionSnapshot) async {
              for (var transaction in transactionSnapshot.docs) {
                currentGroup.listOfTransactions?.add(transaction.data());
              }
              // fetch group members data
              final List<String>? groupMembersIds = currentGroup.memberIds;
              List<UserData> appUsers = await getAllAppUsers();
              currentGroup.listOfMembers?.addAll(
                appUsers
                    .where((user) => groupMembersIds!.contains(user.uid))
                    .toList(),
              );
            });
            groups.add(currentGroup);
          }
        }
      }).then((value) {
        state = UserFinanceData(
          listOfGroups: groups,
          listOfUserTransactions: transactions,
          listOfBankAccounts: bankAccounts,
          cash: cash,
        );
        logger.i(
            "✅ User Finance data fetched successfully. \nTransactions: ${state.listOfUserTransactions?.length} \nCash Amount: ${state.cash?.amount} \nGroups: ${state.listOfGroups?.length} \nBank Accounts: ${state.listOfBankAccounts?.length}");
      });

      return true;
    } catch (e) {
      logger.w("Failed to fetch user finance data: $e");
      return false;
    }
  }

// __________________________________________________________________________ //

  Future<bool> updateUserCashAmount({
    required String uid,
    required String amount,
    bool isCashBalanceAdjustment = false,
    required WidgetRef ref,
  }) async {
    try {
      if (isCashBalanceAdjustment) {
        // adjustmentAmount = newAmount - currentAmount
        final String adjustmentAmount =
            (double.parse(amount) - double.parse(state.cash?.amount ?? '0'))
                .toString();
        await addTransactionToUserData(
          uid: uid,
          transactionData: Transaction(
            uid: uid,
            amount: adjustmentAmount,
            description: "Cash Balance Adjustment",
            category: SystemCategory.balanceAdjustment.displayName,
            methodOfPayment: PaymentModes.cash.displayName,
            transactionType: (double.parse(adjustmentAmount).isNegative)
                ? TransactionType.expense.displayName
                : TransactionType.income.displayName,
          ),
          ref: ref,
        );
      }

      await userCashDocument(uid).update({
        'amount': amount,
      }).then((value) {
        state = state.copyWith(cash: Cash(amount: amount));
        logger.i("Cash amount updated successfully.");
      });

      return true;
    } catch (e) {
      logger.w(
          "Error while updating cash amount: $e\nStack Trace: ${StackTrace.current}");
      return false;
    }
  }

  Future<bool> updateBankAccountBalance({
    required String uid,
    required String bankAccountId,
    required String totalBalance,
    required String availableBalance,
    BankAccount? bankAccount,
    Map<String, String>? groupsBalance,
    bool isBalanceAdjustment = false,
    required WidgetRef ref,
  }) async {
    try {
      // adjustmentAmount = newAmount - currentAmount
      final String adjustmentAmount = (double.parse(availableBalance) -
              double.parse(bankAccount?.totalBalance ?? '0'))
          .toString();
      final String adjustmentTotalAmount =
          (double.parse(totalBalance) + double.parse(adjustmentAmount))
              .toString();

      if (isBalanceAdjustment) {
        await addTransactionToUserData(
          uid: uid,
          transactionData: Transaction(
            uid: uid,
            amount: adjustmentAmount,
            description: "Bank Balance Adjustment",
            category: SystemCategory.balanceAdjustment.displayName,
            methodOfPayment: PaymentModes.bankAccount.displayName,
            bankAccountId: bankAccount?.bid,
            bankAccountName: bankAccount?.bankAccountName,
            transactionType: (double.parse(adjustmentAmount).isNegative)
                ? TransactionType.expense.displayName
                : TransactionType.income.displayName,
          ),
          ref: ref,
        );
      }

      // Update the balance in Firestore
      await bankAccountsCollectionReference(uid).doc(bankAccountId).update({
        'availableBalance': availableBalance,
        'totalBalance':
            (isBalanceAdjustment) ? adjustmentTotalAmount : totalBalance,
        'groupsBalance': groupsBalance ?? bankAccount?.groupsBalance,
      });

      // Update the balance in the local state
      final updatedBankAccounts = state.listOfBankAccounts?.map((bankAccount) {
        if (bankAccount.bid == bankAccountId) {
          return bankAccount.copyWith(
            availableBalance: availableBalance,
            totalBalance:
                (isBalanceAdjustment) ? adjustmentTotalAmount : totalBalance,
            groupsBalance: groupsBalance ?? bankAccount.groupsBalance,
          );
        }
        return bankAccount;
      }).toList();

      state = state.copyWith(listOfBankAccounts: updatedBankAccounts);

      logger.i("✅ Bank account balance updated successfully.");
      return true;
    } catch (e) {
      logger.w("❌ Error updating bank account balance: $e");
      return false;
    }
  }

  Future<bool> updateGroupAmount({
    required String gid,
    required String amount,
    required String memberAmount,
    required String uid,
  }) async {
    try {
      // Get the current group from state
      final group = state.listOfGroups?.firstWhere((group) => group.gid == gid);
      if (group == null) {
        logger.w("Group not found with gid: $gid");
        return false;
      }

      // Create a deep copy of the members balance map
      final updatedMembersBalance =
          Map<String, Map<String, String>>.from(group.membersBalance ?? {});

      // Update the member's current amount while preserving the initial amount
      if (updatedMembersBalance.containsKey(uid)) {
        updatedMembersBalance[uid] = {
          'initialAmount':
              updatedMembersBalance[uid]?['initialAmount'] ?? memberAmount,
          'currentAmount': memberAmount,
        };
      } else {
        updatedMembersBalance[uid] = {
          'initialAmount': memberAmount,
          'currentAmount': memberAmount,
        };
      }

      // updating group in firestore
      await groupsCollection.doc(gid).update({
        'totalAmount': amount,
        'membersBalance': updatedMembersBalance,
      }).then((value) {
        // updating group in provider state
        final updatedGroup = group.copyWith(
            totalAmount: amount, membersBalance: updatedMembersBalance);

        final updatedGroupsList = state.listOfGroups?.map((oldGroup) {
          return oldGroup.gid == gid ? updatedGroup : oldGroup;
        }).toList();

        state = state.copyWith(
          listOfGroups: updatedGroupsList,
        );
        logger.i("Group amount updated successfully.");
      });
      return true;
    } catch (e) {
      logger.w("Error while updating amount: $e");
      return false;
    }
  }

  Future<bool> updateGroupMembers(
      {required String gid, required List<UserData> groupMembersList}) async {
    try {
      final Group? group =
          state.listOfGroups?.firstWhere((group) => group.gid == gid);
      if (group != null) {
        final updatedGroup = group.copyWith(
            listOfMembers: groupMembersList,
            memberIds: groupMembersList
                .map((member) => member.uid)
                .whereType<String>()
                .toList());
        final updatedGroupsList = state.listOfGroups
            ?.map((oldGroup) => oldGroup.gid == gid ? updatedGroup : oldGroup)
            .toList();
        state = state.copyWith(listOfGroups: updatedGroupsList);
        await groupsCollection.doc(gid).update({
          "memberIds": groupMembersList.map((member) => member.uid).toList(),
        });
        logger.i("Group members updated successfully.");
        return true;
      }
      return false;
    } catch (e) {
      Logger().i("Error updating group members: $e");
      return false;
    }
  }

// __________________________________________________________________________ //

  Future<bool> addTransactionToUserData({
    required String uid,
    required Transaction transactionData,
    required WidgetRef ref,
  }) async {
    try {
      final result = (transactionData.isGroupTransaction)
          ? await groupTansactionCollection(transactionData.gid ?? "")
              .add(transactionData)
          : await userTransactionsCollection(uid).add(transactionData);
      await updateTransactionTidDataAndState(
        uid: uid,
        tid: result.id,
        transaction: transactionData,
      );

      // Update budget if this is an expense transaction
      if (transactionData.transactionType ==
              TransactionType.expense.displayName &&
          !transactionData.isGroupTransaction &&
          SystemCategory.goalContribution.displayName !=
              transactionData.category) {
        await _updateBudgetWithTransaction(uid, transactionData, ref);
      }

      print("Transaction added to user");
      return true;
    } catch (e) {
      print("Error adding transaction to user: $e");
      return false;
    }
  }

  Future<void> _updateBudgetWithTransaction(
      String uid, Transaction transaction, WidgetRef ref) async {
    try {
      // Get the transaction date
      final transactionDate = transaction.date;
      if (transactionDate == null) return;

      // Get the category
      final category = transaction.category;
      if (category == null) return;

      // Get budgets from the provider instead of directly querying Firestore
      final budgets = ref.read(budgetNotifierProvider);

      // Find budget for the current month and year
      final budget = budgets.firstWhere(
        (b) =>
            b.date?.year == transactionDate.year &&
            b.date?.month == transactionDate.month,
        orElse: () => Budget(),
      );

      // Skip if no budget found for this month
      if (budget.bid == null || budget.bid!.isEmpty) {
        logger.i("No budget found for the transaction month");
        return;
      }

      // Use the budget provider to update the budget
      await ref
          .read(budgetNotifierProvider.notifier)
          .updateBudgetWithTransaction(uid, transaction);

      logger.i("✅ Budget updated with transaction successfully via provider");
    } catch (e) {
      logger.e("❌ Error updating budget with transaction: $e");
    }
  }

  Future<bool> updateTransactionTidDataAndState({
    required String uid,
    required String tid,
    required Transaction transaction,
  }) async {
    final Transaction tempTransaction = transaction;
    try {
      // adding tid to transaction doc in firestore
      ((tempTransaction.isGroupTransaction)
              ? groupTansactionCollection(tempTransaction.gid ?? "").doc(tid)
              : userTransactionsCollection(uid).doc(tid))
          .update({
        'tid': tid,
      }).then((value) async {
        tempTransaction.tid = tid;
        if (!tempTransaction.isGroupTransaction) {
          // updating transation in user transactions state
          final List<Transaction>? listOfUserTransactions =
              state.listOfUserTransactions?.toList();
          listOfUserTransactions?.add(tempTransaction);
          state =
              state.copyWith(listOfUserTransactions: listOfUserTransactions);
        } else {
          // updating transation in group transactionsList state
          final List<Group>? listOfGroups = state.listOfGroups;
          listOfGroups
              ?.firstWhere((group) => group.gid == tempTransaction.gid)
              .listOfTransactions
              ?.add(tempTransaction);
          state = state.copyWith(listOfGroups: listOfGroups);
        }
      });

      return true;
    } catch (e) {
      logger.w("Error while updating transaction tid: $e");
      return false;
    }
  }

  Future<bool> addTransferTransactionToUserData({
    required String uid,
    required Transaction transactionData,
  }) async {
    try {
// Initialize a Firestore batch to perform atomic operations
      final batch = firestore.FirebaseFirestore.instance.batch();

      // Prepare different transaction objects for user and group collections
      final Transaction userTransactionIndividual =
          transactionData; // For non-group transactions
      final userTransaction1 = transactionData.copyWith(
        amount: transactionData.amount, // For user collection (positive amount)
      );
      final groupTransaction1 = transactionData.copyWith(
        amount: (-double.parse(transactionData.amount ?? "0.0"))
            .toString(), // For group collection (negative amount)
      );
      final userTransaction2 = transactionData.copyWith(
        amount: (-double.parse(transactionData.amount ?? "0.0"))
            .toString(), // For user collection (negative amount)
      );
      final groupTransaction2 = transactionData.copyWith(
        amount:
            transactionData.amount, // For group collection (positive amount)
      );

// Check if the transaction is not a group transaction
      if (!transactionData.isGroupTransaction) {
        // Add the transaction to the user's collection
        final userTransactionRef = userTransactionsCollection(uid).doc();
        batch.set(userTransactionRef, userTransactionIndividual);
        batch.update(userTransactionRef, {'tid': userTransactionRef.id});
        userTransactionIndividual.tid = userTransactionRef.id;
      } else {
        // Handle group transactions
        if (transactionData.methodOfPayment == PaymentModes.group.displayName) {
          // Case 1: Payment Mode 1 is a group
          // Add the transaction with a negative amount to the group collection
          final groupTransactionRef =
              groupTansactionCollection(transactionData.gid ?? "").doc();
          batch.set(groupTransactionRef, groupTransaction1);
          batch.update(groupTransactionRef, {'tid': groupTransactionRef.id});
          groupTransaction1.tid = groupTransactionRef.id;

          // Add the transaction with a positive amount to the user's collection
          final userTransactionRef = userTransactionsCollection(uid).doc();
          batch.set(userTransactionRef, userTransaction1);
          batch.update(userTransactionRef, {'tid': userTransactionRef.id});
          userTransaction1.tid = userTransactionRef.id;
        } else if (transactionData.methodOfPayment2 ==
            PaymentModes.group.displayName) {
          // Case 2: Payment Mode 2 is a group
          // Add the transaction with a negative amount to the user's collection
          final userTransactionRef = userTransactionsCollection(uid).doc();
          batch.set(userTransactionRef, userTransaction2);
          batch.update(userTransactionRef, {'tid': userTransactionRef.id});
          userTransaction2.tid = userTransactionRef.id;

          // Add the transaction with a positive amount to the group collection
          final groupTransactionRef =
              groupTansactionCollection(transactionData.gid2 ?? "").doc();
          batch.set(groupTransactionRef, transactionData);
          batch.update(groupTransactionRef, {'tid': groupTransactionRef.id});

          groupTransaction2.tid = groupTransactionRef.id;
        }
      }

      // Commit the batch to Firestore
      await batch.commit();

// Update the local state after a successful batch commit
      if (!transactionData.isGroupTransaction) {
        // Update the user's transaction list in the state
        final List<Transaction>? listOfUserTransactions =
            state.listOfUserTransactions?.toList();
        listOfUserTransactions?.add(userTransactionIndividual);
        state = state.copyWith(listOfUserTransactions: listOfUserTransactions);
      } else {
        if (transactionData.methodOfPayment == PaymentModes.group.displayName) {
          // Update the user's transaction list and the group's transaction list in the state
          final List<Transaction>? listOfUserTransactions =
              state.listOfUserTransactions?.toList();
          listOfUserTransactions?.add(userTransaction1);
          state =
              state.copyWith(listOfUserTransactions: listOfUserTransactions);
          final List<Group>? listOfGroups = state.listOfGroups;
          listOfGroups
              ?.firstWhere((group) => group.gid == transactionData.gid)
              .listOfTransactions
              ?.add(groupTransaction1);
          state = state.copyWith(listOfGroups: listOfGroups);
        } else if (transactionData.methodOfPayment2 ==
            PaymentModes.group.displayName) {
          // Update the user's transaction list and the group's transaction list in the state
          final List<Transaction>? listOfUserTransactions =
              state.listOfUserTransactions?.toList();
          listOfUserTransactions?.add(userTransaction2);
          state =
              state.copyWith(listOfUserTransactions: listOfUserTransactions);

          final List<Group>? listOfGroups = state.listOfGroups;
          listOfGroups
              ?.firstWhere((group) => group.gid == transactionData.gid2)
              .listOfTransactions
              ?.add(groupTransaction2);
          state = state.copyWith(listOfGroups: listOfGroups);
        }
      }

      logger.i("Transaction added to user ✅");
      return true;
    } catch (e) {
      logger.w(
          "❗Error adding transaction to user: $e\nStack Trace: ${StackTrace.current}");
      return false;
    }
  }

  Future<bool> deleteTransaction(String uid, String tid) async {
    try {
      userTransactionsCollection(uid).doc(tid).delete().then((value) {
        state = state.copyWith(
          listOfUserTransactions: state.listOfUserTransactions
              ?.where((transaction) => transaction.tid != tid)
              .toList(),
        );
        logger.i("Transaction with tid $tid removed successfully.");
      });

      return true;
    } catch (e) {
      logger.w(
          "Error while removing transaction with tid $tid: $e\nStack Trace: ${StackTrace.current}");
      return false;
    }
  }

// __________________________________________________________________________ //

  Future<bool> createGroupProfile({required Group groupProfile}) async {
    try {
      // Initialize a Firestore batch for atomic operations
      final batch = firestore.FirebaseFirestore.instance.batch();

      if (groupProfile.creatorId != null) {
        // Add the group to Firestore
        final groupDocRef = groupsCollection.doc();
        final groupId = groupDocRef.id;

        // Set the group data with the generated ID
        batch.set(
            groupDocRef,
            groupProfile.copyWith(
              gid: groupId,
              listOfMembers: [], // Clear members to avoid serialization issues
            ));

        // Check if this group is linked to a bank account
        if (groupProfile.linkedBankAccountId != null &&
            groupProfile.linkedBankAccountId!.isNotEmpty) {
          // Find the bank account in the state
          final bankAccount = state.listOfBankAccounts?.firstWhere(
              (account) => account.bid == groupProfile.linkedBankAccountId,
              orElse: () => throw Exception("Bank account not found"));

          if (bankAccount != null) {
            // Create updated groupsBalance map for the bank account
            final updatedGroupsBalance = {
              ...?bankAccount.groupsBalance,
              groupId: groupProfile.totalAmount ?? "0",
            };

            // Calculate new total balance for the bank account
            final updatedTotalBalance =
                (double.parse(bankAccount.totalBalance ?? "0") +
                        double.parse(groupProfile.totalAmount ?? "0"))
                    .toString();

            // Update the bank account in Firestore
            final bankAccountRef =
                bankAccountsCollectionReference(groupProfile.creatorId!)
                    .doc(bankAccount.bid);

            batch.update(bankAccountRef, {
              'groupsBalance': updatedGroupsBalance,
              'totalBalance': updatedTotalBalance,
            });

            // Update bank account in local state after batch commits
            final updatedBankAccounts =
                state.listOfBankAccounts?.map((account) {
              if (account.bid == bankAccount.bid) {
                return account.copyWith(
                  groupsBalance: updatedGroupsBalance,
                  totalBalance: updatedTotalBalance,
                );
              }
              return account;
            }).toList();

            // Commit the batch
            await batch.commit();

            // Update local state with both the new group and updated bank account
            state = state.copyWith(
              listOfGroups: state.listOfGroups!
                ..add(groupProfile.copyWith(gid: groupId)),
              listOfBankAccounts: updatedBankAccounts,
            );
          } else {
            // If bank account not found, just create the group
            await batch.commit();

            state = state.copyWith(
              listOfGroups: state.listOfGroups!
                ..add(groupProfile.copyWith(gid: groupId)),
            );
          }
        } else {
          // If no linked bank account, just create the group
          await batch.commit();

          state = state.copyWith(
            listOfGroups: state.listOfGroups!
              ..add(groupProfile.copyWith(gid: groupId)),
          );
        }

        Logger().i("✅ Group profile created successfully");
        return true;
      } else {
        Logger().w("❗groupProfile.creatorId is null");
        throw ArgumentError("❗groupProfile.creatorId cannot be null");
      }
    } catch (e) {
      Logger().w("❗Error creating group profile: $e");
      return false;
    }
  }

  Future<bool> deleteGroupProfile({required Group group}) async {
    print("uid: ${group.creatorId}, gid: ${group.gid}");
    try {
      await groupsCollection.doc(group.gid).delete();
      // Delete all transactions associated with the group
      final groupTransactionsSnapshot =
          await groupTansactionCollection(group.gid!).get();
      for (var doc in groupTransactionsSnapshot.docs) {
        await doc.reference.delete();
      }
      // Delete all chats associated with the group
      final groupChatCollectionSnapshot =
          await groupChatCollection(group.gid ?? "").get();
      for (var doc in groupChatCollectionSnapshot.docs) {
        await doc.reference.delete();
      }

      state = state.copyWith(
        listOfGroups:
            state.listOfGroups?.where((g) => g.gid != group.gid).toList(),
      );
      logger.i("✅ Group: ${group.name} removed successfully.");

      return true;
    } catch (e) {
      logger.w("❗Error while removing Group: ${group.name}: $e");
      return false;
    }
  }

  /// Removes a member from a group
  Future<bool> removeGroupMember({
    required String gid,
    required String memberUid,
  }) async {
    try {
      // Find the group in the state
      final group = state.listOfGroups?.firstWhere(
        (g) => g.gid == gid,
        orElse: () => throw Exception("Group not found"),
      );

      if (group == null) {
        logger.w("❗Group with ID $gid not found");
        return false;
      }

      // Check if memberUid exists in the group
      if (!(group.memberIds?.contains(memberUid) ?? false)) {
        logger.w("❗Member with ID $memberUid not found in group");
        return false;
      }

      // Create updated lists
      final updatedMemberIds =
          group.memberIds?.where((id) => id != memberUid).toList() ?? [];
      final updatedMembers = group.listOfMembers
              ?.where((member) => member.uid != memberUid)
              .toList() ??
          [];

      // Remove the member from the membersBalance map
      final updatedMembersBalance =
          Map<String, Map<String, String>>.from(group.membersBalance ?? {});
      updatedMembersBalance.remove(memberUid);

      // Update Firestore
      await groupsCollection.doc(gid).update({
        'memberIds': updatedMemberIds,
        'membersBalance': updatedMembersBalance,
      });

      // Update the state
      final updatedGroups = state.listOfGroups?.map((g) {
        if (g.gid == gid) {
          return g.copyWith(
            memberIds: updatedMemberIds,
            listOfMembers: updatedMembers,
            membersBalance: updatedMembersBalance,
          );
        }
        return g;
      }).toList();

      state = state.copyWith(listOfGroups: updatedGroups);

      logger.i("✅ Member removed from group successfully");
      return true;
    } catch (e) {
      logger.w("❗Error removing member from group: $e");
      return false;
    }
  }

// __________________________________________________________________________ //

  Future<bool> addBankAccount(
      String uid, BankAccount bankAccount, WidgetRef ref) async {
    try {
      if (bankAccount.bankAccountName != null) {
        if (uid.isNotEmpty && bankAccount.bankAccountName!.isNotEmpty) {
          // add bank account to firestore
          final bankAccountRef =
              await bankAccountsCollectionReference(uid).add(bankAccount);
          await bankAccountRef.update({
            'bid': bankAccountRef.id,
          });

          // add bank account to state provider
          state = state.copyWith(
            listOfBankAccounts: [
              ...?state.listOfBankAccounts,
              bankAccount.copyWith(
                bid: bankAccountRef.id,
              ),
            ],
          );
        } else {
          throw Exception("Uid or Bank Name fields are empty");
        }
      } else {
        Logger().w("❗Error bank account name cannot be null");
        throw ArgumentError("Bank account name cannot be null");
      }
      return true;
    } catch (e) {
      Logger().w("❗Error adding Bank Account: $e");
      return false;
    }
  }

  Future<bool> linkBankAccountToGroup({
    required String uid,
    required String bankAccountId,
    required String groupId,
    required String groupBalance,
  }) async {
    final firestore.WriteBatch batch =
        firestore.FirebaseFirestore.instance.batch();
    try {
      // Fetch the bank account from the state
      final BankAccount? bankAccount = state.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);

      if (bankAccount == null) {
        logger.w("Bank account with ID $bankAccountId not found.");
        return false;
      }

      // Update the group's balance in the bank account
      final updatedGroupsBalance = {
        ...?bankAccount.groupsBalance,
        groupId: groupBalance,
      };
      final updatedBankTotalBalance =
          (double.parse(bankAccount.totalBalance ?? '0') +
                  double.parse(groupBalance))
              .toString();

      // Update Firestore
      final bankAccountDocRef =
          bankAccountsCollectionReference(uid).doc(bankAccountId);
      final groupDocRef = groupsCollection.doc(groupId);

      batch.update(bankAccountDocRef, {
        'groupsBalance': updatedGroupsBalance,
        'totalBalance': updatedBankTotalBalance,
      });
      batch.update(groupDocRef, {'linkedBankAccountId': bankAccountId});

      // Commit the batch
      await batch.commit();

      // Update the bank account in the local state
      final updatedBankAccounts = state.listOfBankAccounts?.map((account) {
        if (account.bid == bankAccountId) {
          return account.copyWith(
            groupsBalance: updatedGroupsBalance,
            totalBalance: updatedBankTotalBalance,
          );
        }
        return account;
      }).toList();

      // Update the linkedBankAccountId in the Group class
      final updatedGroups = state.listOfGroups?.map((group) {
        if (group.gid == groupId) {
          return group.copyWith(linkedBankAccountId: bankAccountId);
        }
        return group;
      }).toList();

      state = state.copyWith(
        listOfBankAccounts: updatedBankAccounts,
        listOfGroups: updatedGroups,
      );

      logger.i("✅ Bank account linked to group successfully.");
      return true;
    } catch (e) {
      logger.w("❌ Error linking bank account to group: $e");
      return false;
    }
  }

  Future<bool> unlinkBankAccountFromGroup({
    required String uid,
    required String bankAccountId,
    required String groupId,
    required String groupBalance,
  }) async {
    final firestore.WriteBatch batch =
        firestore.FirebaseFirestore.instance.batch();
    try {
      // Fetch the bank account from the state
      final BankAccount? bankAccount = state.listOfBankAccounts
          ?.firstWhere((account) => account.bid == bankAccountId);

      if (bankAccount == null) {
        logger.w("Bank account with ID $bankAccountId not found.");
        return false;
      }

      // Remove the group's balance from the bank account's groupsBalance
      final updatedGroupsBalance =
          Map<String, String>.from(bankAccount.groupsBalance ?? {});
      updatedGroupsBalance.remove(groupId);
      final updatedBankTotalBalance =
          (double.parse(bankAccount.totalBalance ?? '0') -
                  double.parse(groupBalance))
              .toString();

      // Update Firestore
      final bankAccountDocRef =
          bankAccountsCollectionReference(uid).doc(bankAccountId);
      final groupDocRef = groupsCollection.doc(groupId);

      batch.update(bankAccountDocRef, {'groupsBalance': updatedGroupsBalance});
      batch.update(groupDocRef, {'linkedBankAccountId': null});

      // Commit the batch
      await batch.commit();

      // Update the bank account in the local state
      final updatedBankAccounts = state.listOfBankAccounts?.map((account) {
        if (account.bid == bankAccountId) {
          return account.copyWith(
            groupsBalance: updatedGroupsBalance,
            totalBalance: updatedBankTotalBalance,
          );
        }
        return account;
      }).toList();

      // Update the group in the local state
      final updatedGroups = state.listOfGroups?.map((group) {
        if (group.gid == groupId) {
          return group.copyWith(linkedBankAccountId: null);
        }
        return group;
      }).toList();

      state = state.copyWith(
        listOfBankAccounts: updatedBankAccounts,
        listOfGroups: updatedGroups,
      );

      logger.i("✅ Bank account unlinked from group successfully.");
      return true;
    } catch (e) {
      logger.w("❌ Error unlinking bank account from group: $e");
      return false;
    }
  }

  Future<bool> deleteBankAccount(
      String uid, String bankAccountId, WidgetRef ref) async {
    try {
      await bankAccountsCollectionReference(uid).doc(bankAccountId).delete();
      state = state.copyWith(
        listOfBankAccounts: state.listOfBankAccounts
            ?.where((account) => account.bid != bankAccountId)
            .toList(),
      );
      logger.i("✅ Bank account removed successfully.");
      return true;
    } catch (e) {
      logger.w("❌ Error while removing Bank Account: $e");
      return false;
    }
  }

  Future<bool> updateBankAccountDetails({
    required String uid,
    required String bankAccountId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      // Update in Firestore
      await bankAccountsCollectionReference(uid)
          .doc(bankAccountId)
          .update(updateData);

      // Update in local state
      final updatedBankAccounts = state.listOfBankAccounts?.map((bankAccount) {
        if (bankAccount.bid == bankAccountId) {
          return bankAccount.copyWith(
            bankAccountName:
                updateData['bankAccountName'] ?? bankAccount.bankAccountName,
            upiIds: updateData['upiIds'] ?? bankAccount.upiIds,
          );
        }
        return bankAccount;
      }).toList();

      state = state.copyWith(listOfBankAccounts: updatedBankAccounts);

      logger.i("✅ Bank account details updated successfully.");
      return true;
    } catch (e) {
      logger.w("❌ Error updating bank account details: $e");
      return false;
    }
  }

// __________________________________________________________________________ //

  Future<bool> refetchAllGroupData(String uid) async {
    try {
      final List<Group> updatedGroups = [];

      await groupsCollection.get().then((value) async {
        for (var group in value.docs) {
          if (group.data().memberIds?.contains(uid) ?? false) {
            final currentGroup = group.data();
            // fetch group transactions
            await groupTansactionCollection(currentGroup.gid!)
                .get()
                .then((transactionSnapshot) async {
              for (var transaction in transactionSnapshot.docs) {
                currentGroup.listOfTransactions?.add(transaction.data());
              }
              // fetch group members data
              final List<String>? groupMembersIds = currentGroup.memberIds;
              List<UserData> appUsers = await getAllAppUsers();
              currentGroup.listOfMembers?.addAll(
                appUsers
                    .where((user) => groupMembersIds!.contains(user.uid))
                    .toList(),
              );
            });
            updatedGroups.add(currentGroup);
          }
        }
      });

      // Update the state with the new list of groups
      state = state.copyWith(listOfGroups: updatedGroups);

      logger.i("✅ All group data refetched successfully.\n"
          "Groups Found: ${state.listOfGroups?.length}");
      return true;
    } catch (e) {
      logger.w("❌ Error while refetching all group data: $e");
      return false;
    }
  }

  Future<bool> refetchUserTransactions(String uid) async {
    try {
      final List<Transaction> updatedTransactions = [];

      await userTransactionsCollection(uid).get().then((value) {
        for (var transaction in value.docs) {
          updatedTransactions.add(transaction.data());
        }
      });

      // Update the state with the new list of transactions
      state = state.copyWith(listOfUserTransactions: updatedTransactions);

      logger.i("✅ User transactions refetched successfully.\n"
          "Transactions Found: ${state.listOfUserTransactions?.length}");
      return true;
    } catch (e) {
      logger.w("❌ Error while refetching user transactions: $e");
      return false;
    }
  }

  Future<bool> refetchUserAccounts(String uid) async {
    try {
      final List<BankAccount> updatedBankAccounts = [];
      Cash? updatedCash = Cash();

      await bankAccountsCollectionReference(uid).get().then((value) {
        for (var account in value.docs) {
          updatedBankAccounts.add(account.data());
        }
      });
      // fetch cash data
      await userCashDocument(uid).get().then((value) {
        updatedCash = value.data();
      });

      // Update the state with the new list of bank accounts
      state = state.copyWith(
          listOfBankAccounts: updatedBankAccounts, cash: updatedCash);

      logger.i("✅ User bank accounts refetched successfully.\n"
          "Bank Accounts Found: ${state.listOfBankAccounts?.length}");
      return true;
    } catch (e) {
      logger.w("❌ Error while refetching user bank accounts: $e");
      return false;
    }
  }

  void reset() {
    state = UserFinanceData();
    print("user finance data reset");
  }
}
