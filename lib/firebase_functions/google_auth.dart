import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widget/snack_bar_message.dart';

Future<UserCredential?> signInWithGoogle(BuildContext context) async {
  try {
    // Step 1: Initialize the GoogleSignIn object
    final GoogleSignIn googleSignIn = GoogleSignIn();

    // Step 2: Start the Google Sign-In process
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // If the user cancels the sign-in, googleUser will be null
    if (googleUser == null) {
      showCustomSnackbar(context, 'Authentication', 'Google sign-in aborted by user', AppColors.warning);
      print('Google sign-in aborted by user.');
      return null;
    }

    // Step 3: Obtain the Google Sign-In authentication details
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Step 4: Create a new credential for Firebase Authentication
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Step 5: Use the credential to sign in to Firebase
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Step 6: Display success message
    showCustomSnackbar(context, 'Authentication', 'Google sign-in successful. User: ${userCredential.user?.displayName}', AppColors.success);
    print('Google sign-in successful. User: ${userCredential.user?.displayName}');
    return userCredential;

  } catch (e) {
    // Display error message in case of failure
    showCustomSnackbar(context, 'Authentication', 'Failed to sign in with Google: $e', AppColors.error);
    print('Failed to sign in with Google: $e');
    return null;
  }
}
