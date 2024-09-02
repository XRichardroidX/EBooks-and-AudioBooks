import 'package:firebase_auth/firebase_auth.dart';

Future<void> signOutUser() async {
  try {
    await FirebaseAuth.instance.signOut();
    print('User signed out successfully.');
  } catch (e) {
    print('Error signing out: $e');
    // Handle the error as needed
  }
}
