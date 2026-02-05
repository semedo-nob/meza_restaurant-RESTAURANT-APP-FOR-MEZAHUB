// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  final AuthService _authService = AuthService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if user is authenticated
  bool get isAuthenticated => _user != null;

  // Initialize user from storage
  Future<void> initialize() async {
    if (_isLoading) return; // Prevent multiple initializations

    _isLoading = true;
    // Don't call notifyListeners() here to avoid rebuild during initialization

    try {
      final result = await _authService.verifyAuthStatus();

      if (result['success'] == true) {
        if (result['isAuthenticated'] == true && result['user'] != null) {
          _user = User.fromJson(result['user']);
        }
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Initialization failed: $e';
    } finally {
      _isLoading = false;
      // Only notify after the entire initialization is complete
      notifyListeners();
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.loginWithEmailAndPassword(email, password);

      if (result['success'] == true) {
        _user = User.fromJson(result['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String restaurantName,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        restaurantName: restaurantName,
        phoneNumber: phoneNumber,
      );

      if (result['success'] == true) {
        _user = User.fromJson(result['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Password reset
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.resetPassword(email);

      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Password reset failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Password change failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.deleteAccount(password);

      if (result['success'] == true) {
        _user = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Account deletion failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.logout();

      if (result['success'] == true) {
        _user = null;
        _error = null;
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Logout failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({
    String? restaurantName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_user != null) {
        final result = await _authService.updateProfile(
          userId: _user!.id,
          restaurantName: restaurantName,
          phoneNumber: phoneNumber,
        );

        if (result['success'] == true) {
          _user = User.fromJson(result['user']);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = result['error'];
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _error = 'No user found';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Profile update failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      final result = await _authService.getCurrentUser();
      if (result['success'] == true) {
        _user = User.fromJson(result['user']);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to refresh user: $e';
    }
  }
}