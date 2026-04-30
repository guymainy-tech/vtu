// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  factory FirebaseService() => _instance;

  FirebaseService._internal();

  bool get isInitialized => _isInitialized;

  // ================= SETUP =================
  void setup() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      if (!kIsWeb) {
        _googleSignIn = GoogleSignIn();
      }

      _isInitialized = true;
      AppLogger.log('Firebase initialized');
    } catch (e) {
      AppLogger.error('Firebase setup error: $e');
      _isInitialized = false;
    }
  }

  // ================= AUTH =================

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      AppLogger.error('Sign-up error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      AppLogger.error('Login error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      AppLogger.error('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();

      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
    } catch (e) {
      AppLogger.error('Logout error: $e');
      rethrow;
    }
  }

  // ================= USER =================

  User? getCurrentUser() => _auth.currentUser;

  String? getUserId() => _auth.currentUser?.uid;

  bool isUserAuthenticated() => _auth.currentUser != null;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ================= FIRESTORE (USER) =================

  Future<void> saveUserData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(
            data,
            SetOptions(merge: true),
          );
    } catch (e) {
      AppLogger.error('Save user error: $e');
      rethrow;
    }
  }

  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).set(
            data,
            SetOptions(merge: true), // ✅ safe update
          );
    } catch (e) {
      AppLogger.error('Update error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      AppLogger.error('Get user error: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  // ================= WALLET =================

  Future<double> getWalletBalance(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['balance'] ?? 0).toDouble();
  }

  Future<void> creditWallet({
    required String userId,
    required double amount,
  }) async {
    final ref = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      final currentBalance =
          (snapshot.data()?['balance'] ?? 0).toDouble();

      transaction.set(ref, {
        'balance': currentBalance + amount,
      }, SetOptions(merge: true));
    });
  }

  Future<void> debitWallet({
    required String userId,
    required double amount,
  }) async {
    final ref = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      final currentBalance =
          (snapshot.data()?['balance'] ?? 0).toDouble();

      if (currentBalance < amount) {
        throw Exception('Insufficient balance');
      }

      transaction.set(ref, {
        'balance': currentBalance - amount,
      }, SetOptions(merge: true));
    });
  }

  // ================= TRANSACTIONS =================

  Future<void> createTransaction({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add({
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Transaction error: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}