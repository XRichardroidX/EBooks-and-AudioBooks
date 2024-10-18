import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String userIdFromFirebase = FirebaseAuth.instance.currentUser!.uid;

class Constants {
  // // AppWrite Constants
  // static const String endpoint = 'https://cloud.appwrite.io/v1';  // Replace with your Appwrite endpoint
  // static const String projectId = '66d3512e003a47f8b5d9';   // Replace with your Appwrite project ID
  // static const String databaseId = '66d713d800147667742b';    // Replace with your Appwrite database ID
  // static const String ebooksCollectionId = '66d7210e001271490533'; // Replace with your E-Books collection ID
  // static const String audiobooksCollectionId = ''; // Replace with your AudioBooks collection ID
  //
  //
  //
  // static const String cloudStorageBookId = '66e046190000af5c2178';
  // static const String cloudStorageBookCoverId = '66e04843002721f16c01';





  static const String endpoint = 'https://cloud.appwrite.io/v1';  // Replace with your Appwrite endpoint
  static const String projectId = '66f5f98b0002c0938374';   // Replace with your Appwrite project ID
  static const String databaseId = '66f6065500037e9d499a';    // Replace with your Appwrite database ID
  static const String ebooksCollectionId = '66f60702000677fcd1c9'; // Replace with your E-Books collection ID
  static const String usersCollectionId = '6706a6c800015eb3b098'; // Replace with your AudioBooks collection ID



  static const String cloudStorageBookId = '66e046190000af5c2178';
  static const String cloudStorageBookCoverId = '66f60f4b001dd27104fa';


  static const PAYSTACK_PUBLIC_KEY = 'pk_live_58453afed05725f6f914137094fc6cc6fce1c83d';
  static const PAYSTACK_SECRET_KEY = 'sk_live_2cb5c0611da9addb24ee696a748c21788da71f09';

  static const PAYSTACK_PUBLIC_TEST_KEY = 'pk_test_b6701cd1b4df226bf77b2434ae99244d7c7f5780';
  static const PAYSTACK_SECRET_TEST_KEY = 'sk_test_adc6b961459dce45a075312db615d2a38055518f';

  // Firebase Constants
  String userId = userIdFromFirebase; // Replace with your Firebase  user ID
}

class Screen {
  static late double width;
  static late double height;
  static late double drawer;

  // Static method to initialize constants
  static void initialize(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    drawer = MediaQuery.of(context).size.width * 0.8;
  }
}
