import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserAuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  auth.User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      // Create user with email and password
      final auth.UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final User user = User(
        id: result.user!.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.id).set(user.toMap());

      return user;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc =
          await _firestore.collection('users').doc(result.user!.uid).get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      return User.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user data
  Future<User> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }
      return User.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Add pet to user
  Future<void> addPetToUser(String userId, String petId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'petIds': FieldValue.arrayUnion([petId])
      });
    } catch (e) {
      throw Exception('Failed to add pet to user: $e');
    }
  }
}
