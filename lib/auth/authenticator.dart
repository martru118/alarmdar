import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Authenticator {
  final auth = FirebaseAuth.instance;
  final GoogleSignIn signIn = GoogleSignIn();

  //get current user
  User getUser() => auth.currentUser;

  //sign in to Google account
  Future<User> login() async {
    //get authentication details from request
    final GoogleSignInAccount googleUser = await signIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    //create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //get user
    UserCredential userCredential = await auth.signInWithCredential(credential);
    return userCredential.user;
  }

  //sign out from Google account
  Future<void> logout() async {
    await signIn.signOut();
    await auth.signOut();
  }
}