// lib/viewmodels/auth_viewmodel.dart
// ─────────────────────────────────────────────────────────────
//  CONNECTED TO REAL DJANGO BACKEND
//  Calls: POST /api/v1/auth/login/  and  /api/v1/auth/register/
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/error_message.dart';
import '../services/api_service.dart';
import '../utils/error_message.dart';
import '../services/token_storage.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  UserModel? _currentUser;
  String? _accessToken;
  String? _refreshToken;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _currentUser != null && _accessToken != null;
  bool get isLoading => _status == AuthStatus.loading;

  // ══════════════════════════════════════════════
  //  LOGIN — calls real Django API
  // ══════════════════════════════════════════════
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please enter email and password');
      }

      final result = await ApiService.login(email, password);

      _accessToken = result['access'];
      _refreshToken = result['refresh'];
      _currentUser = UserModel(
        uid: result['user']['id'].toString(),
        email: result['user']['email'],
        name: result['user']['name'],
        role: result['user']['role'] ?? 'hr_manager',
        createdAt: DateTime.now(),
      );

      // Save tokens using central TokenStorage
      if (_accessToken != null && _refreshToken != null) {
        await TokenStorage.saveTokens(
            access: _accessToken!, refresh: _refreshToken!);
      }

      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          ErrorMessage.from(e, fallback: 'Login failed. Please try again.');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════
  //  REGISTER — calls real Django API
  // ══════════════════════════════════════════════
  Future<bool> register(String name, String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('Please fill all fields');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final result = await ApiService.register(name, email, password);

      _accessToken = result['access'];
      _refreshToken = result['refresh'];
      _currentUser = UserModel(
        uid: result['user']['id'].toString(),
        email: result['user']['email'],
        name: result['user']['name'],
        role: result['user']['role'] ?? 'hr_manager',
        createdAt: DateTime.now(),
      );

      if (_accessToken != null && _refreshToken != null) {
        await TokenStorage.saveTokens(
            access: _accessToken!, refresh: _refreshToken!);
      }

      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMessage.from(e,
          fallback: 'Registration failed. Please try again.');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════
  //  LOGOUT
  // ══════════════════════════════════════════════
  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await ApiService.logout(_accessToken!, _refreshToken!);
      }
    } catch (_) {
      // ignore errors on logout
    }
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _status = AuthStatus.idle;
    await TokenStorage.clear();
    notifyListeners();
  }

  // ══════════════════════════════════════════════
  //  CHECK AUTH STATE on app start
  //  Restores login if a saved token exists
  // ══════════════════════════════════════════════
  Future<void> checkAuthState() async {
    final token = await TokenStorage.getAccessToken();

    if (token != null) {
      try {
        final profile = await ApiService.getProfile(token);
        _accessToken = token;
        _refreshToken = await TokenStorage.getRefreshToken();
        _currentUser = UserModel(
          uid: profile['id'].toString(),
          email: profile['email'],
          name: profile['name'],
          role: profile['role'] ?? 'hr_manager',
          createdAt: DateTime.now(),
        );
        notifyListeners();
      } catch (_) {
        // Token expired or invalid — clear it
        await TokenStorage.clear();
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }
}
