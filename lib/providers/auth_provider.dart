import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  double _balance = 0.0;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  double get balance => _balance;
  String? get userId => _firebaseService.getUserId();

  // ================= REGISTER =================
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final result = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
      );

      final firebaseUser = result.user;
      if (firebaseUser == null) return false;

      final userData = {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'balance': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _firebaseService.saveUserData(
        userId: firebaseUser.uid,
        data: userData,
      );

      await _storageService.saveUserData(
        userId: firebaseUser.uid,
        fullName: fullName,
        phone: phone,
      );

      _user = userData;
      _balance = 0.0;
      _isAuthenticated = true;

      listenToUserData(); // real-time sync

      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================= LOGIN =================
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final credential = await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) return false;

      final userData = await _firebaseService.getUserData(firebaseUser.uid);

      if (userData != null) {
        _user = userData;
        _balance = (userData['balance'] ?? 0).toDouble();

        await _storageService.saveUserData(
          userId: firebaseUser.uid,
          fullName: userData['full_name'] ?? '',
          phone: userData['phone'] ?? '',
        );
      }

      _isAuthenticated = true;

      listenToUserData(); // real-time updates

      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================= REAL-TIME USER LISTENER =================
  void listenToUserData() {
    final userId = _firebaseService.getUserId();
    if (userId == null) return;

    _firebaseService.getUserStream(userId).listen((data) {
      if (data != null) {
        _user = data;
        _balance = (data['balance'] ?? 0).toDouble();

        notifyListeners();
      }
    });
  }

  // ================= CREATE PIN =================
  Future<bool> createPin(String pin) async {
    _setLoading(true);

    try {
      final user = _firebaseService.getCurrentUser();
      if (user == null) return false;

      await _firebaseService.saveUserData(
        userId: user.uid,
        data: {
          'transaction_pin': pin,
        },
      );

      _user?['transaction_pin'] = pin;

      notifyListeners();

      AppLogger.log('PIN created successfully');
      return true;
    } catch (e) {
      AppLogger.error('Create PIN error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================= LOAD USER =================
  Future<void> loadUser() async {
    try {
      final user = _firebaseService.getCurrentUser();

      if (user != null) {
        final userData = await _firebaseService.getUserData(user.uid);

        if (userData != null) {
          _user = userData;
          _balance = (userData['balance'] ?? 0).toDouble();
          _isAuthenticated = true;

          listenToUserData();
          notifyListeners();
        }
      }
    } catch (e) {
      AppLogger.error('Load user error: $e');
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _firebaseService.signOut();
      await _storageService.clearAll();

      _isAuthenticated = false;
      _user = null;
      _balance = 0.0;

      notifyListeners();
    } catch (e) {
      AppLogger.error('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ================= GOOGLE SIGN-IN =================
  Future<bool> signInWithGoogle() async {
    _setLoading(true);

    try {
      final result = await _firebaseService.signInWithGoogle();

      final firebaseUser = result?.user;
      if (firebaseUser == null) {
        AppLogger.error('Google sign-in failed: No user returned');
        return false;
      }

      final existingUser = await _firebaseService.getUserData(firebaseUser.uid);

      if (existingUser == null) {
        // New user - create profile
        final userData = {
          'full_name': firebaseUser.displayName ?? 'User',
          'email': firebaseUser.email ?? '',
          'phone': '',
          'profile_picture': firebaseUser.photoURL,
          'balance': 0.0,
          'created_at': DateTime.now().toIso8601String(),
          'auth_method': 'google',
        };

        await _firebaseService.saveUserData(
          userId: firebaseUser.uid,
          data: userData,
        );

        _user = userData;
      } else {
        _user = existingUser;
      }

      _balance = (_user?['balance'] ?? 0).toDouble();
      _isAuthenticated = true;

      await _storageService.saveUserData(
        userId: firebaseUser.uid,
        fullName: _user?['full_name'] ?? 'User',
        phone: _user?['phone'] ?? '',
      );

      listenToUserData();
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Google sign-in error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================= UPDATE PROFILE =================
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? profilePicture,
  }) async {
    _setLoading(true);

    try {
      final user = _firebaseService.getCurrentUser();
      if (user == null) return false;

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (profilePicture != null)
        updateData['profile_picture'] = profilePicture;

      await _firebaseService.saveUserData(
        userId: user.uid,
        data: updateData,
      );

      if (fullName != null) _user?['full_name'] = fullName;
      if (phone != null) _user?['phone'] = phone;
      if (profilePicture != null) _user?['profile_picture'] = profilePicture;

      if (phone != null) {
        await _storageService.saveUserData(
          userId: user.uid,
          fullName: _user?['full_name'] ?? 'User',
          phone: phone,
        );
      }

      notifyListeners();
      AppLogger.log('Profile updated successfully');
      return true;
    } catch (e) {
      AppLogger.error('Update profile error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
