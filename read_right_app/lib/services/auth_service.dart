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

  // Return list of class objects for a teacher (each Map includes the classId in 'id')
  Future<List<Map<String, dynamic>>> getClassesForTeacher(String teacherUid) async {
    try {
      // Try reading an index at /teacherClasses/{teacherUid} which should contain
      // a map of classId -> true. This avoids needing broad query permissions.
      final idxEvent = await _database.child('teacherClasses').child(teacherUid).once();
      final idxRaw = idxEvent.snapshot.value;
      final List<Map<String, dynamic>> out = [];
      if (idxRaw is Map) {
        for (final entry in idxRaw.entries) {
          final classId = entry.key.toString();
          final clsEvent = await _database.child('classes').child(classId).once();
          final clsRaw = clsEvent.snapshot.value;
          if (clsRaw is Map) {
            final map = clsRaw.map((k, v) => MapEntry(k.toString(), v));
            map['id'] = classId;
            out.add(map.cast<String, dynamic>());
          }
        }
        return out;
      }

      // Fallback: use a query (requires index permissions in rules)
      DatabaseEvent event = await _database.child('classes').orderByChild('teacherUid').equalTo(teacherUid).once();
      final raw = event.snapshot.value;
      if (raw == null) return [];
      if (raw is Map) {
        raw.forEach((key, value) {
          if (value is Map) {
            final map = value.map((k, v) => MapEntry(k.toString(), v));
            map['id'] = key.toString();
            out.add(map.cast<String, dynamic>());
          }
        });
      }
      return out;
    } catch (e) {
      rethrow;
    }
  }

  // Given a list of student UIDs, fetch their user profiles from /users
  Future<List<Map<String, dynamic>>> getUserProfilesByUids(List<String> uids) async {
    final List<Map<String, dynamic>> profiles = [];
    for (final uid in uids) {
      final p = await getUserData(uid);
      if (p != null) profiles.add(p);
    }
    return profiles;
  }
}