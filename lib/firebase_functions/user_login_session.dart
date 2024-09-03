import 'package:firebase_auth/firebase_auth.dart';

Future<bool> checkUserLoggedIn() async {
  // Get the current user from FirebaseAuth instance
  User? user = FirebaseAuth.instance.currentUser;
  // If user is not null, user is logged in, return true; otherwise, return false
  return user != null;
}