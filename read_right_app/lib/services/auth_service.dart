import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    try {
      // Create the user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If user creation successful, store additional info in Realtime Database
      if (userCredential.user != null) {
        await _database.child('users').child(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'username': username,
          'role': role,
          'createdAt': ServerValue.timestamp,
        });
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Realtime Database
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DatabaseEvent event = await _database.child('users').child(uid).once();
      final raw = event.snapshot.value;
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      if (raw is Map) {
        // Convert Map<Object?, Object?> (or other loose map) to Map<String, dynamic>
        return raw.map((key, value) => MapEntry(key.toString(), value));
      }
      // Unexpected shape; return null or throw depending on your preference
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _database.child('users').child(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }
}