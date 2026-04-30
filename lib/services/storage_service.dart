// lib/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // ================= FIRST LAUNCH =================
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('is_first_launch', false);
      return true;
    }
    return false;
  }

  // ================= USER DATA =================
  Future<void> saveUserData({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    await _secureStorage.write(key: 'user_id', value: userId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', fullName);
    await prefs.setString('phone', phone);
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'full_name': prefs.getString('full_name'),
      'phone': prefs.getString('phone'),
    };
  }

  // ================= CLEAR =================
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}