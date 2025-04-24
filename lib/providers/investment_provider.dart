import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finmate/models/investment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

final investmentNotifierProvider =
    StateNotifierProvider<InvestmentNotifier, List<Investment>>((ref) {
  return InvestmentNotifier();
});

class InvestmentNotifier extends StateNotifier<List<Investment>> {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  InvestmentNotifier() : super([]);
  
  CollectionReference<Investment> _investmentCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('investments')
        .withConverter<Investment>(
          fromFirestore: (snapshot, _) => 
              Investment.fromJson({...snapshot.data()!, 'id': snapshot.id}),
          toFirestore: (investment, _) => investment.toJson(),
        );
  }
  
  Future<void> loadInvestments(String uid) async {
    try {
      final snapshot = await _investmentCollection(uid).get();
      final investments = snapshot.docs.map((doc) => doc.data()).toList();
      state = investments;
      _logger.i('Loaded ${investments.length} investments');
    } catch (e) {
      _logger.e('Error loading investments: $e');
      state = [];
    }
  }
  
  Future<bool> addInvestment(Investment investment) async {
    try {
      // Generate ID if not provided
      final String investmentId = investment.id.isNotEmpty 
          ? investment.id 
          : const Uuid().v4();
          
      // Calculate progress percentage
      final double progress = investment.targetAmount > 0
          ? (investment.currentAmount / investment.targetAmount * 100).clamp(0.0, 100.0)
          : 0.0;
      
      // Add current value to history
      final now = DateTime.now();
      final initialHistory = [
        {
          'date': Timestamp.fromDate(now),
          'value': investment.currentAmount,
        }
      ];
      
      final newInvestment = investment.copyWith(
        id: investmentId,
        progressPercentage: progress,
        valueHistory: initialHistory,
      );
      
      await _investmentCollection(investment.uid)
          .doc(investmentId)
          .set(newInvestment);
      
      state = [...state, newInvestment];
      _logger.i('Added investment: ${newInvestment.name}');
      return true;
    } catch (e) {
      _logger.e('Error adding investment: $e');
      return false;
    }
  }
  
  Future<bool> updateInvestment(Investment investment) async {
    try {
      // Calculate progress percentage
      final double progress = investment.targetAmount > 0
          ? (investment.currentAmount / investment.targetAmount * 100).clamp(0.0, 100.0)
          : 0.0;
          
      final updatedInvestment = investment.copyWith(progressPercentage: progress);
      
      await _investmentCollection(investment.uid)
          .doc(investment.id)
          .update(updatedInvestment.toJson());
      
      state = state.map((i) => i.id == investment.id ? updatedInvestment : i).toList();
      _logger.i('Updated investment: ${investment.name}');
      return true;
    } catch (e) {
      _logger.e('Error updating investment: $e');
      return false;
    }
  }
  
  Future<bool> updateInvestmentValue(String uid, String investmentId, double newValue) async {
    try {
      // Find investment in state
      final investmentIndex = state.indexWhere((i) => i.id == investmentId);
      if (investmentIndex == -1) {
        _logger.w('Investment not found: $investmentId');
        return false;
      }
      
      final investment = state[investmentIndex];
      
      // Add the new value to history
      final updatedInvestment = investment.addValueEntry(newValue);
      
      await _investmentCollection(uid)
          .doc(investmentId)
          .update({
            'currentAmount': newValue,
            'progressPercentage': updatedInvestment.progressPercentage,
            'valueHistory': updatedInvestment.valueHistory,
          });
      
      // Update state
      state = [
        ...state.sublist(0, investmentIndex),
        updatedInvestment,
        ...state.sublist(investmentIndex + 1),
      ];
      
      _logger.i('Updated investment value: $investmentId to $newValue');
      return true;
    } catch (e) {
      _logger.e('Error updating investment value: $e');
      return false;
    }
  }
  
  Future<bool> deleteInvestment(String uid, String investmentId) async {
    try {
      await _investmentCollection(uid).doc(investmentId).delete();
      
      state = state.where((i) => i.id != investmentId).toList();
      _logger.i('Deleted investment: $investmentId');
      return true;
    } catch (e) {
      _logger.e('Error deleting investment: $e');
      return false;
    }
  }
}
