import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Authentication service - Email/Password only, Firestore free tier optimized
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }

      // Validate password strength
      final passwordValidation = _validatePassword(password);
      if (passwordValidation != null) {
        return AuthResult.failure(passwordValidation);
      }

      // Strict Gmail Enforcement
      if (!email.trim().toLowerCase().endsWith('@gmail.com')) {
        return AuthResult.failure(
          'Registration is restricted to @gmail.com accounts only.',
        );
      }

      // Create user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to create account');
      }

      // Create user document in Firestore
      final userModel = UserModel.newUser(
        uid: credential.user!.uid,
        email: email.trim().toLowerCase(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An error occurred. Please try again.');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to sign in');
      }

      // Get user document from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        // Create user doc if it doesn't exist (edge case)
        final userModel = UserModel.newUser(
          uid: credential.user!.uid,
          email: email.trim().toLowerCase(),
        );
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());
        return AuthResult.success(userModel);
      }

      final userModel = UserModel.fromFirestore(doc);

      // Update last login and streak (batch write to optimize)
      await _updateLoginStats(credential.user!.uid, userModel);

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An error occurred. Please try again.');
    }
  }

  /// Update login statistics
  Future<void> _updateLoginStats(String uid, UserModel user) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = user.lastLoginDate;

    int newStreak = user.currentStreak;
    int newDaysActive = user.daysActive;

    if (lastLogin != null) {
      final lastLoginDay = DateTime(
        lastLogin.year,
        lastLogin.month,
        lastLogin.day,
      );
      final daysDiff = today.difference(lastLoginDay).inDays;

      if (daysDiff == 1) {
        // Consecutive day - increase streak
        newStreak++;
        newDaysActive++;
      } else if (daysDiff > 1) {
        // Streak broken
        newStreak = 1;
        newDaysActive++;
      }
      // daysDiff == 0 means same day, no update needed
    }

    if (lastLogin == null ||
        today
                .difference(
                  DateTime(lastLogin.year, lastLogin.month, lastLogin.day),
                )
                .inDays >
            0) {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginDate': Timestamp.fromDate(now),
        'currentStreak': newStreak,
        'daysActive': newDaysActive,
      });
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }

      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return AuthResult.successMessage('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An error occurred. Please try again.');
    }
  }

  /// Get user model from Firestore
  Future<UserModel?> getUserModel() async {
    if (currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Stream user model changes
  Stream<UserModel?> userModelStream() {
    if (currentUser == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Validation helpers
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@gmail\.com$',
    ).hasMatch(email.trim().toLowerCase());
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'We couldn\'t find an account with that email. Please check your spelling or sign up!';
      case 'wrong-password':
        return 'The password you entered is incorrect. Double-check and try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in instead!';
      case 'weak-password':
        return 'Your password is too simple. Use 8+ characters with uppercase, lowercase, and numbers for better security.';
      case 'invalid-email':
        return 'That doesn\'t look like a valid email address. Please check and try again.';
      case 'user-disabled':
        return 'This account has been temporarily disabled. Please contact support for help.';
      case 'too-many-requests':
        return 'Too many login attempts! Please wait a few minutes before trying again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is currently unavailable.';
      default:
        return 'Oops! Something went wrong. Please try again';
    }
  }
}

/// Auth result wrapper
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;
  final UserModel? user;

  AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.successMessage,
    this.user,
  });

  factory AuthResult.success(UserModel user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.successMessage(String message) {
    return AuthResult._(isSuccess: true, successMessage: message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
