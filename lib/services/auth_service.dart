import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'hive_service.dart';
import 'device_service.dart';
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

      // Check if device is already registered
      final existingDevice = await _firestore
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      if (existingDevice.docs.isNotEmpty) {
        return (
          user: null,
          error:
              'This device already has an account. Only one account per device is allowed.',
        );
      }

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

      // Handle referral bonus if referral code provided
      if (referralCode != null && referralCode.isNotEmpty) {
        await _processReferral(user.uid, referralCode);
      }

      return (user: user, error: null);
    } on FirebaseAuthException catch (e) {
      return (user: null, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('Registration error: $e');
      return (user: null, error: 'An unexpected error occurred');
    }
  }

  /// Login with email and password
  Future<({UserModel? user, String? error})> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return (user: null, error: 'Failed to login');
      }

      // Get user from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        return (user: null, error: 'User data not found');
      }

      final user = UserModel.fromJson(doc.data()!);

      // Verify device ID
      final currentDeviceId = getService<DeviceService>().deviceId;
      if (user.deviceId != currentDeviceId) {
        await _auth.signOut();
        return (
          user: null,
          error:
              'This account is registered on a different device. Only one device per account is allowed.',
        );
      }

      // Save to local storage
      await getService<HiveService>().saveUser(user);

      return (user: user, error: null);
    } on FirebaseAuthException catch (e) {
      return (user: null, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('Login error: $e');
      return (user: null, error: 'An unexpected error occurred');
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

  /// Process referral bonus
  Future<void> _processReferral(String newUserId, String referralCode) async {
    try {
      // Find referrer by referral code
      final referrerQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (referrerQuery.docs.isEmpty) {
        debugPrint('Referral code not found: $referralCode');
        return;
      }

      final referrerId = referrerQuery.docs.first.id;

      // Award referrer bonus (2000 coins)
      await _firestore.collection('users').doc(referrerId).update({
        'totalCoins': FieldValue.increment(2000),
        'lifetimeCoins': FieldValue.increment(2000),
      });

      // Award new user bonus (5000 coins)
      await _firestore.collection('users').doc(newUserId).update({
        'totalCoins': FieldValue.increment(5000),
        'lifetimeCoins': FieldValue.increment(5000),
      });

      debugPrint('Referral processed: $referralCode');
    } catch (e) {
      debugPrint('Error processing referral: $e');
    }
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
