// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../utils/error_message.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = {};
  
  UserModel? _currentUser;
  String? _accessToken;
  String? _refreshToken;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => _fieldErrors;
  
  UserModel? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _currentUser != null && _accessToken != null;
  bool get isLoading => _status == AuthStatus.loading;

  void _clearErrors() {
    _errorMessage = null;
    _fieldErrors.clear();
  }

  // ══════════════════════════════════════════════
  //  LOGIN
  // ══════════════════════════════════════════════
  Future<bool> login(String email, String password) async {
    _clearErrors();
    HapticFeedback.mediumImpact(); // Professional UX touch
    
    if (email.trim().isEmpty) _fieldErrors['email'] = 'Enter your email address';
    if (password.isEmpty) _fieldErrors['password'] = 'Enter your password';
    
    if (_fieldErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final result = await ApiService.login(email.trim(), password);

      _accessToken = result['access'];
      _refreshToken = result['refresh'];
      _currentUser = UserModel.fromJson(result['user']);

      if (_accessToken != null && _refreshToken != null) {
        await TokenStorage.saveTokens(access: _accessToken!, refresh: _refreshToken!);
      }

      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = ErrorMessage.from(e, fallback: 'Login failed. Please try again.');
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════
  //  REGISTER
  // ══════════════════════════════════════════════
  Future<bool> register(String name, String email, String password) async {
    _clearErrors();
    HapticFeedback.lightImpact();

    if (name.trim().isEmpty) _fieldErrors['name'] = 'Your full name is required';
    if (email.trim().isEmpty) _fieldErrors['email'] = 'Valid email is required';
    else if (!email.contains('@')) _fieldErrors['email'] = 'Enter a valid email address';
    
    if (password.isEmpty) _fieldErrors['password'] = 'Password is required';
    else if (password.length < 6) _fieldErrors['password'] = 'Must be at least 6 characters';

    if (_fieldErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final result = await ApiService.register(name.trim(), email.trim(), password);

      _accessToken = result['access'];
      _refreshToken = result['refresh'];
      _currentUser = UserModel.fromJson(result['user']);

      if (_accessToken != null && _refreshToken != null) {
        await TokenStorage.saveTokens(access: _accessToken!, refresh: _refreshToken!);
      }

      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = ErrorMessage.from(e, fallback: 'Registration failed.');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    HapticFeedback.selectionClick();
    try {
      if (_refreshToken != null && _accessToken != null) {
        await ApiService.logout(_accessToken!, _refreshToken!);
      }
    } catch (_) {}
    
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _status = AuthStatus.idle;
    
    await TokenStorage.clear();
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      try {
        final profile = await ApiService.getProfile(token);
        _accessToken = token;
        _refreshToken = await TokenStorage.getRefreshToken();
        _currentUser = UserModel.fromJson(profile);
        notifyListeners();
      } catch (_) {
        // COMMITTEE FIX: Ensure memory is cleared if token is invalid/expired
        _accessToken = null;
        _refreshToken = null;
        _currentUser = null;
        await TokenStorage.clear();
        notifyListeners();
      }
    }
  }

  void clearError() {
    _clearErrors();
    _status = AuthStatus.idle;
    notifyListeners();
  }
}
