import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    final googleAccount = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleAccount.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    await _upsertUserProfile(userCredential.user);
    return userCredential;
  }

  Future<void> signOut({bool disconnectGoogle = false}) async {
    if (disconnectGoogle) {
      await GoogleSignIn.instance.disconnect();
    } else {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  Future<void> _upsertUserProfile(User? user) async {
    if (user == null) {
      return;
    }
    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
