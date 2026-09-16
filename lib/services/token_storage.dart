// lib/services/token_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TokenStorage {
  static const _accessKey = 'recruit_iq_access_token';
  static const _refreshKey = 'recruit_iq_refresh_token';

  // Memory cache to ensure immediate availability after saving
  static String? _cachedAccess;
  static String? _cachedRefresh;

  static Future<void> saveTokens(
      {required String access, required String refresh}) async {
    _cachedAccess = access;
    _cachedRefresh = refresh;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, access);
      await prefs.setString(_refreshKey, refresh);

      if (kDebugMode) {
        print('TokenStorage: Tokens saved and cached.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TokenStorage: Error saving to SharedPreferences: $e');
      }
    }
  }

  static Future<String?> getAccessToken() async {
    if (_cachedAccess != null) {
      if (kDebugMode) {
        print('TokenStorage: Returning access token from memory cache.');
      }
      return _cachedAccess;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessKey);
      _cachedAccess = token; // Update cache
      if (kDebugMode) {
        print(
            'TokenStorage: Retrieving access token from disk: ${token != null ? "FOUND" : "NOT FOUND"}');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('TokenStorage: Error reading from SharedPreferences: $e');
      }
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    if (_cachedRefresh != null) return _cachedRefresh;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_refreshKey);
    _cachedRefresh = token;
    return token;
  }

  static Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);

    if (kDebugMode) {
      print('TokenStorage: Tokens cleared from memory and disk');
    }
  }
}
