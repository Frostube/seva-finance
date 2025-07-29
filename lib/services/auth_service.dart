import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  UserService? _userService;
  User? _user;
  bool _isLoading = false;

  AuthService(this._auth, this._firestore) {
    // Set persistence to LOCAL to maintain session
    _auth.setPersistence(Persistence.LOCAL);
    print('AuthService: Persistence set to LOCAL.');

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      print('AuthService: authStateChanges fired. User is: \${user?.uid}');
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  // Expose the auth state changes stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Inject UserService (called from main.dart after providers are set up)
  void setUserService(UserService userService) {
    _userService = userService;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Creating user account...'); // Debug log
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User account created successfully'); // Debug log

      // Update Firebase Auth profile with display name
      try {
        await userCredential.user!.updateDisplayName(name);
        print('DEBUG: Firebase Auth display name updated');
      } catch (e) {
        print('DEBUG: Error updating display name: $e');
      }

      // UserService will automatically create the user profile with ProPlan features
      // when it detects the new Firebase Auth user
      print('DEBUG: UserService will handle ProPlan user profile creation');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error in signUp: $e'); // Debug log
      if (e is FirebaseAuthException) {
        print('Firebase Auth Error Code: ${e.code}'); // Debug log
        print('Firebase Auth Error Message: ${e.message}'); // Debug log
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      print('DEBUG: Starting sign in process for: $emailOrUsername');
      _isLoading = true;
      notifyListeners();

      String email = emailOrUsername;

      // If the input doesn't look like an email, try to find the email by username
      if (!emailOrUsername.contains('@')) {
        print('DEBUG: Input looks like a username, searching in Firestore');
        final usersRef = _firestore.collection('users');

        // Debug: Check collection structure
        print('DEBUG: Checking Firestore collection structure...');
        try {
          final usersSnapshot = await usersRef.limit(1).get();
          print(
              'DEBUG: Users collection exists: ${usersSnapshot.docs.isNotEmpty}');
          if (usersSnapshot.docs.isNotEmpty) {
            print(
                'DEBUG: Sample user document fields: ${usersSnapshot.docs.first.data().keys.toList()}');
          }
        } catch (e) {
          print('DEBUG: Error checking Firestore structure: $e');
        }

        // Normalize the username input the same way we do during signup
        final normalizedUsername =
            emailOrUsername.toLowerCase().replaceAll(' ', '').trim();
        print('DEBUG: Searching for normalized username: $normalizedUsername');

        try {
          print('DEBUG: Executing Firestore query...');
          final querySnapshot = await usersRef
              .where('username', isEqualTo: normalizedUsername)
              .get()
              .timeout(const Duration(seconds: 10));

          print(
              'DEBUG: Firestore query completed. Found ${querySnapshot.docs.length} matches');
          print('DEBUG: Query path: ${usersRef.path}');

          if (querySnapshot.docs.isEmpty) {
            print('DEBUG: No user found with username: $normalizedUsername');
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'No user found with this username',
            );
          }

          email = querySnapshot.docs.first.get('email') as String;
          print(
              'DEBUG: Found corresponding email: $email for username: $normalizedUsername');
        } catch (e) {
          print('DEBUG: Error during username lookup: $e');
          print('DEBUG: Error type: ${e.runtimeType}');
          if (e is FirebaseException) {
            print('DEBUG: Firebase error code: ${e.code}');
            print('DEBUG: Firebase error message: ${e.message}');
          }
          rethrow;
        }
      } else {
        print('DEBUG: Input is an email address: $email');
      }

      print('DEBUG: Attempting Firebase sign in with email: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(
          'DEBUG: Sign in successful for user: ${userCredential.user?.email}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error during sign in: $e');
      if (e is FirebaseAuthException) {
        print('DEBUG: Firebase Auth Error Code: ${e.code}');
        print('DEBUG: Firebase Auth Error Message: ${e.message}');
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // UserService will automatically clear data when auth state changes
      await _auth.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (name != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'name': name,
        }).timeout(const Duration(seconds: 10)); // Add 10 second timeout
      }

      if (email != null) {
        await _user!.updateEmail(email);
        await _firestore.collection('users').doc(_user!.uid).update({
          'email': email,
        }).timeout(const Duration(seconds: 10)); // Add 10 second timeout
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (_user == null) {
      print('deleteAccount: No user logged in');
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently logged in.',
      );
    }

    try {
      print(
          'deleteAccount: Starting account deletion process for user ${_user!.email}');
      _isLoading = true;
      notifyListeners();

      // Delete user data from Firestore first
      print('deleteAccount: Starting Firestore data deletion');
      try {
        // Delete user profile
        print('deleteAccount: Deleting user profile');
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .delete()
            .timeout(const Duration(seconds: 10));
        print('deleteAccount: User profile deleted successfully');

        // Delete user's wallets
        print('deleteAccount: Deleting user wallets');
        final walletSnapshot = await _firestore
            .collection('wallets')
            .where('userId', isEqualTo: _user!.uid)
            .get();
        print(
            'deleteAccount: Found ${walletSnapshot.docs.length} wallets to delete');
        for (var doc in walletSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete user's expenses
        print('deleteAccount: Deleting user expenses');
        final expenseSnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: _user!.uid)
            .get();
        print(
            'deleteAccount: Found ${expenseSnapshot.docs.length} expenses to delete');
        for (var doc in expenseSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete user's savings goals
        print('deleteAccount: Deleting user savings goals');
        final savingsSnapshot = await _firestore
            .collection('savings_goals')
            .where('userId', isEqualTo: _user!.uid)
            .get();
        print(
            'deleteAccount: Found ${savingsSnapshot.docs.length} savings goals to delete');
        for (var doc in savingsSnapshot.docs) {
          await doc.reference.delete();
        }

        print(
            'deleteAccount: All user data deleted from Firestore successfully');
      } catch (e) {
        print('deleteAccount: Error deleting user data from Firestore: $e');
        // Continue with account deletion even if Firestore cleanup fails
      }

      try {
        // Delete the user's authentication account
        print('deleteAccount: Attempting to delete authentication account');
        await _user!.delete();
        print('deleteAccount: Authentication account deleted successfully');
      } catch (e) {
        print('deleteAccount: Error deleting auth account: $e');
        if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
          _isLoading = false;
          notifyListeners();
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message:
                'For security reasons, please log out and log in again before deleting your account.',
          );
        }
        rethrow;
      }

      _isLoading = false;
      notifyListeners();
      print('deleteAccount: Account deletion process completed successfully');
    } catch (e) {
      print('deleteAccount: Error in deletion process: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
