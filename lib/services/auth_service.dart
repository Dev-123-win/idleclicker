import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'hive_service.dart';
import 'device_service.dart';
import 'sync_service.dart';
import 'service_locator.dart';

/// Authentication service using Firebase Auth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register new user with email and password
  Future<({UserModel? user, String? error})> registerWithEmail({
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      final deviceId = getService<DeviceService>().deviceId;

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return (user: null, error: 'Failed to create account');
      }

      // Generate unique referral code for this user
      final userReferralCode = _generateReferralCode(credential.user!.uid);

      // Create user model
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        deviceId: deviceId,
        referralCode: userReferralCode,
        referredBy: referralCode,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(user.toJson());

      // Save to local storage
      await getService<HiveService>().saveUser(user);

      return (user: user, error: null);
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration Firebase error: ${e.code} - ${e.message}');
      return (user: null, error: _getAuthErrorMessage(e.code));
    } catch (e, stack) {
      debugPrint('Registration unexpected error: $e');
      debugPrint('Stack trace: $stack');
      return (user: null, error: 'An unexpected error occurred: $e');
    }
  }

  /// Login with email and password
  Future<({UserModel? user, String? error})> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Starting login for $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        debugPrint('Login failed: Credential.user is null');
        return (user: null, error: 'Failed to login');
      }

      debugPrint('Login success, fetching user ${credential.user!.uid}');

      // Get user from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        debugPrint(
          'Firestore document does not exist for uid: ${credential.user!.uid}',
        );
        await _auth.signOut();
        return (user: null, error: 'User data not found');
      }

      final user = UserModel.fromJson(doc.data()!);
      debugPrint('User data fetched successfully for ${user.email}');

      // Verify device ID
      final currentDeviceId = getService<DeviceService>().deviceId;
      debugPrint(
        'Verifying device: stored=${user.deviceId}, current=$currentDeviceId',
      );

      if (user.deviceId != currentDeviceId) {
        debugPrint('Device ID mismatch');
        await _auth.signOut();
        return (
          user: null,
          error:
              'This account is registered on a different device. Only one device per account is allowed.',
        );
      }

      // Save to local storage
      await getService<HiveService>().saveUser(user);
      debugPrint('Login complete');

      return (user: user, error: null);
    } on FirebaseAuthException catch (e) {
      debugPrint('Login Firebase error: ${e.code} - ${e.message}');
      return (user: null, error: _getAuthErrorMessage(e.code));
    } catch (e, stack) {
      debugPrint('Login unexpected error: $e');
      debugPrint('Stack trace: $stack');
      return (user: null, error: 'An unexpected error occurred: $e');
    }
  }

  /// Send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  /// Manually reset password with device verification via worker
  Future<String?> manuallyResetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final deviceId = getService<DeviceService>().deviceId;
      final result = await getService<SyncService>().resetPassword(
        email: email,
        deviceId: deviceId,
        newPassword: newPassword,
      );

      if (result.success) {
        return null;
      } else {
        return result.message ?? 'Password reset failed';
      }
    } catch (e) {
      debugPrint('Manual reset error: $e');
      return 'An unexpected error occurred';
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
    await getService<HiveService>().clearAll();
  }

  /// Generate unique referral code
  String _generateReferralCode(String uid) {
    final code =
        uid.substring(0, 4).toUpperCase() +
        _uuid.v4().substring(0, 4).toUpperCase();
    return code;
  }

  /// Get human-readable auth error message
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
