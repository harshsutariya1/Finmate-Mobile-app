// Provider for UserFinanceDataNotifier
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
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
    List<Wallet> wallets = [];
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

      // fetch wallets data
      await walletCollectionReference(uid).get().then((value) {
        for (var doc in value.docs) {
          wallets.add(doc.data());
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
          listOfWallets: wallets,
          cash: cash,
        );
        logger.i(
            "✅ User Finance data fetched successfully. \nTransactions: ${state.listOfUserTransactions?.length} \nCash Amount: ${state.cash?.amount} \nGroups: ${state.listOfGroups?.length} \nBank Accounts: ${state.listOfBankAccounts?.length} \nWallets: ${state.listOfWallets?.length}");
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
            category: TransactionCategory.balanceAdjustment.displayName,
            methodOfPayment: PaymentModes.cash.displayName,
            type: (double.parse(adjustmentAmount).isNegative)
                ? TransactionType.expense
                : TransactionType.income,
          ),
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
    required String newBalance,
    BankAccount? bankAccount,
    bool isBalanceAdjustment = false,
  }) async {
    try {
      if (isBalanceAdjustment) {
        // adjustmentAmount = newAmount - currentAmount
        final String adjustmentAmount = (double.parse(newBalance) -
                double.parse(bankAccount?.totalBalance ?? '0'))
            .toString();
        await addTransactionToUserData(
          uid: uid,
          transactionData: Transaction(
            uid: uid,
            amount: adjustmentAmount,
            description: "Bank Balance Adjustment",
            category: TransactionCategory.balanceAdjustment.displayName,
            methodOfPayment: PaymentModes.bankAccount.displayName,
            bankAccountId: bankAccount?.bid,
            type: (double.parse(adjustmentAmount).isNegative)
                ? TransactionType.expense
                : TransactionType.income,
          ),
        );
      }

      // Update the balance in Firestore
      await bankAccountsCollectionReference(uid)
          .doc(bankAccountId)
          .update({'availableBalance': newBalance, 'totalBalance': newBalance});

      // Update the balance in the local state
      final updatedBankAccounts = state.listOfBankAccounts?.map((bankAccount) {
        if (bankAccount.bid == bankAccountId) {
          return bankAccount.copyWith(
            availableBalance: newBalance,
            totalBalance: newBalance,
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

  Future<bool> updateWalletBalance({
    required String uid,
    required String walletId,
    required String newBalance,
    Wallet? wallet,
    bool isBalanceAdjustment = false,
  }) async {
    try {
      if (isBalanceAdjustment) {
        // adjustmentAmount = newAmount - currentAmount
        final String adjustmentAmount =
            (double.parse(newBalance) - double.parse(wallet?.balance ?? '0'))
                .toString();
        await addTransactionToUserData(
          uid: uid,
          transactionData: Transaction(
            uid: uid,
            amount: adjustmentAmount,
            description: "Wallet Balance Adjustment",
            category: TransactionCategory.balanceAdjustment.displayName,
            methodOfPayment: PaymentModes.wallet.displayName,
            bankAccountId: walletId,
            type: (double.parse(adjustmentAmount).isNegative)
                ? TransactionType.expense
                : TransactionType.income,
          ),
        );
      }

      // Update the balance in Firestore
      await walletCollectionReference(uid)
          .doc(walletId)
          .update({'balance': newBalance});

      // Update the balance in the local state
      final updatedWallets = state.listOfWallets?.map((wallet) {
        if (wallet.wid == walletId) {
          return wallet.copyWith(balance: newBalance);
        }
        return wallet;
      }).toList();

      state = state.copyWith(listOfWallets: updatedWallets);

      logger.i("✅ Wallet balance updated successfully.");
      return true;
    } catch (e) {
      logger.w("❌ Error updating wallet balance: $e");
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
      // updating group in firestore
      await groupsCollection.doc(gid).update({
        'totalAmount': amount,
        'membersBalance': state.listOfGroups
            ?.firstWhere((group) => group.gid == gid)
            .membersBalance
            ?.map((key, value) {
          return MapEntry(key, key == uid ? memberAmount : value);
        }),
      }).then((value) {
        // updating group in provider state
        final group =
            state.listOfGroups?.firstWhere((group) => group.gid == gid);
        if (group != null) {
          final updatedGroup =
              group.copyWith(totalAmount: amount, membersBalance: {
            ...group.membersBalance!,
            uid: memberAmount,
          });
          final updatedGroupsList = state.listOfGroups?.map((oldGroup) {
            return oldGroup.gid == gid ? updatedGroup : oldGroup;
          }).toList();

          state = state.copyWith(
            listOfGroups: updatedGroupsList,
          );
          logger.i("Group amount updated successfully.");
        }
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
        final updatedGroup = group.copyWith(listOfMembers: groupMembersList);
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

      print("Transaction added to user");
      return true;
    } catch (e) {
      print("Error adding transaction to user: $e");
      return false;
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
      final batch = firestore.FirebaseFirestore.instance.batch();
      final Transaction userTransactionIndividual = transactionData;
      final userTransaction1 = transactionData.copyWith(
        amount: transactionData.amount,
      );
      final groupTransaction1 = transactionData.copyWith(
        amount: (-double.parse(transactionData.amount ?? "0.0")).toString(),
      );
      final userTransaction2 = transactionData.copyWith(
        amount: (-double.parse(transactionData.amount ?? "0.0")).toString(),
      );
      final groupTransaction2 = transactionData.copyWith(
        amount: transactionData.amount,
      );
      if (!transactionData.isGroupTransaction) {
        final userTransactionRef = userTransactionsCollection(uid).doc();
        batch.set(userTransactionRef, userTransactionIndividual);
        batch.update(userTransactionRef, {'tid': userTransactionRef.id});
        userTransactionIndividual.tid = userTransactionRef.id;
      } else {
        if (transactionData.methodOfPayment == PaymentModes.group.displayName) {
          final groupTransactionRef =
              groupTansactionCollection(transactionData.gid ?? "").doc();
          batch.set(groupTransactionRef, groupTransaction1);
          batch.update(groupTransactionRef, {'tid': groupTransactionRef.id});
          groupTransaction1.tid = groupTransactionRef.id;

          final userTransactionRef = userTransactionsCollection(uid).doc();
          batch.set(userTransactionRef, userTransaction1);
          batch.update(userTransactionRef, {'tid': userTransactionRef.id});
          userTransaction1.tid = userTransactionRef.id;
        } else if (transactionData.methodOfPayment2 ==
            PaymentModes.group.displayName) {
          final userTransactionRef = userTransactionsCollection(uid).doc();
          batch.set(userTransactionRef, userTransaction2);
          batch.update(userTransactionRef, {'tid': userTransactionRef.id});
          userTransaction2.tid = userTransactionRef.id;
          final groupTransactionRef =
              groupTansactionCollection(transactionData.gid2 ?? "").doc();
          batch.set(groupTransactionRef, transactionData);
          batch.update(groupTransactionRef, {'tid': groupTransactionRef.id});

          groupTransaction2.tid = groupTransactionRef.id;
        }
      }

      // Commit the batch
      await batch.commit();

      if (!transactionData.isGroupTransaction) {
        // Update provider state
        final List<Transaction>? listOfUserTransactions =
            state.listOfUserTransactions?.toList();
        listOfUserTransactions?.add(userTransactionIndividual);
        state = state.copyWith(listOfUserTransactions: listOfUserTransactions);
      } else {
        if (transactionData.methodOfPayment == PaymentModes.group.displayName) {
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
      if (groupProfile.creatorId != null) {
        final result = await groupsCollection
            .add(groupProfile.copyWith(listOfMembers: []));
        await result.update({'gid': result.id});

        state = state.copyWith(
          listOfGroups: state.listOfGroups!
            ..add(groupProfile.copyWith(gid: result.id)),
        );
      } else {
        Logger().w("❗groupProfile.creatorId is null");
        throw ArgumentError("❗groupProfile.creatorId cannot be null");
      }
      Logger().i("✅Group profile created successfully");
      return true;
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

  Future<bool> addBankAccount(
      String uid, BankAccount bankAccount, WidgetRef ref) async {
    try {
      if (bankAccount.bankAccountName != null) {
        if (uid.isNotEmpty && bankAccount.bankAccountName!.isNotEmpty) {
          // add bank account to firestore
          final bankAccountColRef = bankAccountsCollectionReference(uid);
          await bankAccountColRef
              .doc(bankAccount.bankAccountName)
              .set(bankAccount);
          // add bank account to state provider
          state = state.copyWith(
            listOfBankAccounts: [
              ...?state.listOfBankAccounts,
              bankAccount,
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

  Future<bool> addWallet(String uid, Wallet wallet, WidgetRef ref) async {
    try {
      if (wallet.walletName != null) {
        if (uid.isNotEmpty && wallet.walletName!.isNotEmpty) {
          // add wallet to firestore
          final walletColRef = walletCollectionReference(uid);
          await walletColRef.doc(wallet.walletName).set(wallet);
          // add wallet to state provider
          state = state.copyWith(
            listOfWallets: [
              ...?state.listOfWallets,
              wallet,
            ],
          );
        } else {
          throw Exception("Uid or Wallet Name fields are empty");
        }
      } else {
        Logger().w("❗Error wallet name cannot be null");
        throw ArgumentError("Wallet name cannot be null");
      }
      return true;
    } catch (e) {
      Logger().w("❗Error adding Wallet: $e");
      return false;
    }
  }

// __________________________________________________________________________ //

  void reset() {
    state = UserFinanceData();
    print("user finance data reset");
  }
}
