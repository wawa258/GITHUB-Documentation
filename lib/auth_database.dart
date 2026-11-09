import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthDatabase {
  AuthDatabase({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static final AuthDatabase instance = AuthDatabase();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String playerName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      final name = playerName.trim();
      if (name.isNotEmpty) {
        await user.updateDisplayName(name);
      }
      await _saveUserProfile(user, playerName: name);
    }
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) await _saveUserProfile(user);
    return credential;
  }

  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    final credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    final user = credential.user;
    if (user != null) await _saveUserProfile(user);
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _saveUserProfile(User user, {String? playerName}) async {
    final profileRef = _firestore.collection('users').doc(user.uid);
    final existingProfile = await profileRef.get();
    final profile = <String, Object>{
      'providerIds': user.providerData
          .map((provider) => provider.providerId)
          .toList(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    final email = user.email;
    if (email != null) profile['email'] = email;
    final name = playerName?.isNotEmpty == true ? playerName : user.displayName;
    if (name != null && name.isNotEmpty) profile['playerName'] = name;
    if (!existingProfile.exists) {
      profile['createdAt'] = FieldValue.serverTimestamp();
    }

    await profileRef.set(profile, SetOptions(merge: true));
  }
}
