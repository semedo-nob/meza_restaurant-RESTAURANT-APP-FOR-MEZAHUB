// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import 'backend_api.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final Box _authBox = Hive.box('auth');
  final Box _userBox = Hive.box('user');

  // Login with email and password using backend (JWT)
  Future<Map<String, dynamic>> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      final data = await BackendApi.login(email, password);
      final userMap = data['user'];
      if (userMap == null) {
        final profile = await BackendApi.getProfile();
        await _storeUserFromMap(profile);
        return {'success': true, 'user': profile};
      }
      await _storeUserFromMap(Map<String, dynamic>.from(userMap as Map));
      return {'success': true, 'user': userMap};
    } catch (e) {
      return {'success': false, 'error': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  // Register new user with backend (role: restaurant)
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String restaurantName,
    required String phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = await BackendApi.register(
        name: restaurantName,
        email: email,
        password: password,
        role: 'restaurant',
        phone: phoneNumber,
      );
      final userMap = data['user'];
      if (userMap == null) {
        final profile = await BackendApi.getProfile();
        await _storeUserFromMap(profile);
      } else {
        await _storeUserFromMap(Map<String, dynamic>.from(userMap as Map));
      }
      // Create the restaurant in the backend (details + location from sign-up form).
      try {
        final myRestaurants = await BackendApi.getMyRestaurants();
        if (myRestaurants.isEmpty) {
          await BackendApi.createRestaurant(
            name: restaurantName,
            phone: phoneNumber,
            address: address,
            latitude: latitude,
            longitude: longitude,
          );
        }
      } catch (_) {
        // Non-fatal: user is registered; they can create restaurant later from profile if needed.
      }
      return {'success': true, 'user': userMap ?? (await BackendApi.getProfile())};
    } catch (e) {
      return {'success': false, 'error': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  Future<void> _storeUserFromMap(Map<String, dynamic> m) async {
    final user = User.fromJson(m);
    await _userBox.put('currentUser', user.toJson());
  }

  // Password reset with Firebase
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent successfully',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getFirebaseAuthErrorMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Password reset failed: $e',
      };
    }
  }

  // Verify user authentication status (backend JWT in Hive)
  Future<Map<String, dynamic>> verifyAuthStatus() async {
    try {
      final token = _authBox.get('access_token') as String?;
      if (token == null || token.isEmpty) {
        return {'success': true, 'user': null, 'isAuthenticated': false};
      }
      var storedUser = _userBox.get('currentUser');
      if (storedUser != null) {
        final user = User.fromJson(Map<String, dynamic>.from(storedUser));
        return {'success': true, 'user': user.toJson(), 'isAuthenticated': true};
      }
      try {
        final profile = await BackendApi.getProfile();
        await _storeUserFromMap(profile);
        return {'success': true, 'user': profile, 'isAuthenticated': true};
      } catch (_) {
        await _clearStorage();
        return {'success': true, 'user': null, 'isAuthenticated': false};
      }
    } catch (e) {
      return {'success': false, 'error': 'Auth verification failed: $e'};
    }
  }

  // Logout (clear backend JWT and user from Hive; optionally Firebase)
  Future<Map<String, dynamic>> logout() async {
    try {
      await _auth.signOut();
      await _clearStorage();
      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Logout failed: $e'};
    }
  }

  // Update user profile via backend
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? restaurantName,
    String? phoneNumber,
  }) async {
    try {
      await BackendApi.updateProfile(name: restaurantName, phone: phoneNumber);
      final profile = await BackendApi.getProfile();
      await _storeUserFromMap(profile);
      return {'success': true, 'user': profile, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {'success': false, 'error': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final storedUser = _userBox.get('currentUser');
      if (storedUser != null) {
        final user = User.fromJson(Map<String, dynamic>.from(storedUser));
        return {
          'success': true,
          'user': user.toJson(),
        };
      }
      return {
        'success': false,
        'error': 'No user found',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get user: $e',
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user before changing password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);

        return {
          'success': true,
          'message': 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getFirebaseAuthErrorMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Password change failed: $e',
      };
    }
  }

  // Delete user account
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user before deleting account
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);
        await user.delete();
        await _clearStorage();

        return {
          'success': true,
          'message': 'Account deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getFirebaseAuthErrorMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Account deletion failed: $e',
      };
    }
  }

  Future<void> _storeUser(User user) async {
    await _userBox.put('currentUser', user.toJson());
  }

  Future<void> _clearStorage() async {
    await _userBox.clear();
    await _authBox.clear();
  }

  // Firebase Auth error message helper
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}