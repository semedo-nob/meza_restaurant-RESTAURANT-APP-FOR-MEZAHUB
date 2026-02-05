// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:hive/hive.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Box _authBox = Hive.box('auth');
  final Box _userBox = Hive.box('user');

  // Login with email and password using Firebase
  Future<Map<String, dynamic>> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        final user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          restaurantName: firebaseUser.displayName ?? 'My Restaurant',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          role: 'restaurant_owner',
          createdAt: DateTime.now(),
        );

        // Store user data in Hive
        await _storeUser(user);

        return {
          'success': true,
          'user': user.toJson(),
        };
      } else {
        return {
          'success': false,
          'error': 'Login failed: No user data returned',
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
        'error': 'Login failed: $e',
      };
    }
  }

  // Register new user with Firebase
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String restaurantName,
    required String phoneNumber,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;

        // Update display name with restaurant name
        await firebaseUser.updateDisplayName(restaurantName);

        final user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          restaurantName: restaurantName,
          phoneNumber: phoneNumber,
          role: 'restaurant_owner',
          createdAt: DateTime.now(),
        );

        // Store user data in Hive
        await _storeUser(user);

        return {
          'success': true,
          'user': user.toJson(),
        };
      } else {
        return {
          'success': false,
          'error': 'Registration failed: No user data returned',
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
        'error': 'Registration failed: $e',
      };
    }
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

  // Verify user authentication status
  Future<Map<String, dynamic>> verifyAuthStatus() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Check if user data exists in Hive
        final storedUser = _userBox.get('currentUser');
        User user;

        if (storedUser != null) {
          user = User.fromJson(Map<String, dynamic>.from(storedUser));
        } else {
          // Create user from Firebase auth if not in Hive
          user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            restaurantName: firebaseUser.displayName ?? 'My Restaurant',
            phoneNumber: firebaseUser.phoneNumber ?? '',
            role: 'restaurant_owner',
            createdAt: DateTime.now(),
          );
          await _storeUser(user);
        }

        return {
          'success': true,
          'user': user.toJson(),
          'isAuthenticated': true,
        };
      } else {
        return {
          'success': true,
          'user': null,
          'isAuthenticated': false,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Auth verification failed: $e',
      };
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      await _auth.signOut();
      await _clearStorage();

      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Logout failed: $e',
      };
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? restaurantName,
    String? phoneNumber,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && restaurantName != null) {
        await currentUser.updateDisplayName(restaurantName);
      }

      // Get current user data
      final storedUser = _userBox.get('currentUser');
      if (storedUser != null) {
        final user = User.fromJson(Map<String, dynamic>.from(storedUser));
        final updatedUser = user.copyWith(
          restaurantName: restaurantName ?? user.restaurantName,
          phoneNumber: phoneNumber ?? user.phoneNumber,
          updatedAt: DateTime.now(),
        );

        // Update stored user data in Hive
        await _storeUser(updatedUser);

        return {
          'success': true,
          'user': updatedUser.toJson(),
          'message': 'Profile updated successfully',
        };
      }

      return {
        'success': false,
        'error': 'User not found',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Profile update failed: $e',
      };
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

  // Hive storage methods
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