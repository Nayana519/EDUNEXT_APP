import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

bool _googleReady = false;

Future<UserCredential> signInWithGoogle() async {
  final gs = GoogleSignIn.instance;
  if (!_googleReady) {
    await gs.initialize(); // v7: must be done once
    _googleReady = true;
  }
  final account = await gs.authenticate();
  final credential = GoogleAuthProvider.credential(
    idToken: account.authentication.idToken,
  );
  return FirebaseAuth.instance.signInWithCredential(credential);
}