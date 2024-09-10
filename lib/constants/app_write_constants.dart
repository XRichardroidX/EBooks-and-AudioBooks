import 'package:firebase_auth/firebase_auth.dart';

String userIdFromFirebase = FirebaseAuth.instance.currentUser!.uid;

class Constants {
  // AppWrite Constants
  static const String endpoint = 'https://cloud.appwrite.io/v1';  // Replace with your Appwrite endpoint
  static const String projectId = '66d3512e003a47f8b5d9';   // Replace with your Appwrite project ID
  static const String databaseId = '66d713d800147667742b';    // Replace with your Appwrite database ID
  static const String ebooksCollectionId = '66d7210e001271490533'; // Replace with your E-Books collection ID
  static const String audiobooksCollectionId = ''; // Replace with your AudioBooks collection ID



  static const String cloudStorageBookId = '66e046190000af5c2178';
  static const String cloudStorageBookCoverId = '66e04843002721f16c01';

  // Firebase Constants
  String userId = userIdFromFirebase; // Replace with your Firebase  user ID
}
