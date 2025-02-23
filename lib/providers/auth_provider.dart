import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Listens for changes in authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// ________________________________________________________________________ //

final sharedPreferencesProvider = Provider<Future<SharedPreferences>>((ref) {
  return SharedPreferences.getInstance();
});

// FutureProvider to fetch the value of a specific key from SharedPreferences
final spStringKeyProvider =
    FutureProvider.family<String?, String>((ref, key) async {
  final prefs = await ref.watch(sharedPreferencesProvider);
  // final authState = ref.watch(authStateProvider);
  return prefs.getString(key);
});

// ________________________________________________________________________ //

final userDataExistsProvider = StreamProvider<bool>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges().asyncMap((user) async {
    if (user == null) {
      return false;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists;
  });
});