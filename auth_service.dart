import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  // =========================
  // REGISTER
  // =========================
  Future<String?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role,
  }) async {
    try {
      // CLEAN INPUTS
      email = email.trim().toLowerCase();
      password = password.trim();
      firstName = firstName.trim();
      lastName = lastName.trim();
      phone = phone.trim();

      // CREATE USER
      UserCredential result =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // CREATE USER MODEL
        UserModel userModel = UserModel(
          uid: user.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
          isOnline: false,
        );

        // SAVE TO USERS COLLECTION
        await _db
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        // SAVE TO ROLE COLLECTION
        if (role == 'Customer') {
          await _db
              .collection('customers')
              .doc(user.uid)
              .set(userModel.toMap());
        } else {
          await _db
              .collection('riders')
              .doc(user.uid)
              .set(userModel.toMap());
        }

        // IMPORTANT:
        // SIGN OUT AFTER REGISTER
        // So login screen works correctly
        await _auth.signOut();

        return null;
      }

      return "Registration failed";
    }

    // FIREBASE AUTH ERRORS
    on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return "Email is already registered";

        case 'invalid-email':
          return "Invalid email address";

        case 'weak-password':
          return "Password is too weak";

        case 'network-request-failed':
          return "No internet connection";

        default:
          return e.message;
      }
    } catch (e) {
      debugPrint("Register Error: $e");
      return "Something went wrong";
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<String?> login(
      String email,
      String password,
      ) async {
    try {
      // CLEAN INPUTS
      email = email.trim().toLowerCase();
      password = password.trim();

      // LOGIN
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null;
    }

    // FIREBASE AUTH ERRORS
    on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return "Account not found";

        case 'wrong-password':
          return "Incorrect password";

        case 'invalid-email':
          return "Invalid email";

        case 'invalid-credential':
          return "Invalid email or password";

        case 'network-request-failed':
          return "No internet connection";

        default:
          return e.message;
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      return "Something went wrong";
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    final user = _auth.currentUser;
    if (user != null) {
      await updateOnlineStatus(user.uid, false);
    }
    await _auth.signOut();
  }

  // =========================
  // GET USER DATA
  // =========================
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
      await _db.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }

    return null;
  }

  // =========================
  // UPDATE ONLINE STATUS
  // =========================
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await _db.collection('users').doc(uid).update({'isOnline': isOnline});
      
      // Also update in riders collection if applicable
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final role = doc.get('role');
        if (role == 'Rider') {
          await _db.collection('riders').doc(uid).update({'isOnline': isOnline});
        }
      }
    } catch (e) {
      debugPrint("Error updating online status: $e");
    }
  }

  // =========================
  // CURRENT USER
  // =========================
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
