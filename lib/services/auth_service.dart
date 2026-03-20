import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Retrieves the familiaId for a user.
  /// First checks the 'users' collection, then falls back to a collectionGroup
  /// query to migrate legacy accounts created before that collection existed.
  Future<String?> getFamiliaIdForUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists && (doc.data()?.containsKey('familiaId') ?? false)) {
        return doc.data()!['familiaId'] as String?;
      }
    } catch (e) {
      debugPrint('AuthService: Error reading familiaId from users/$userId: $e');
    }

    try {
      final query = await _db
          .collectionGroup('miembros')
          .where('email', isEqualTo: _auth.currentUser?.email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final familiaId = query.docs.first.reference.parent.parent?.id;
        if (familiaId != null) {
          await _db.collection('users').doc(userId).set(
            {'familiaId': familiaId},
            SetOptions(merge: true),
          );
          return familiaId;
        }
      }
    } catch (e) {
      debugPrint('AuthService: Error in collectionGroup fallback: $e');
    }

    return null;
  }
}
