import 'dart:ui';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import '../constants/app_write_constants.dart';
import '../style/colors.dart';
import '../widget/snack_bar_message.dart';

Future<bool> signInWithGoogle(BuildContext context) async {
  try {
    // Initialize Appwrite client
    Client client = Client();
    Account account = Account(client);

    client
        .setEndpoint(Constants.endpoint) // Set your Appwrite endpoint
        .setProject(Constants.projectId); // Set your Appwrite project ID

    // Start the OAuth2 Google login
    await account.createOAuth2Session(
      provider: OAuthProvider.google,
    //  success: 'localhost',  // Make sure this matches your custom scheme
    //  failure: 'localhost',
      scopes: ['email', 'profile'], // Requesting 'email' and 'profile' scopes
    );

    // Display success message
    showCustomSnackbar(context, 'Authentication', 'Google sign-in successful', AppColors.success);
    print('Google sign-in successful.');
    return true;
  } catch (e) {
    // Display error message in case of failure
    showCustomSnackbar(context, 'Authentication', 'Failed to sign in with Google: $e', AppColors.error);
    print('Failed to sign in with Google: $e');
    return false;
  }
}

void handleIncomingLinks(BuildContext context) {
  // This method checks for incoming links
  if (Platform.isAndroid) {
    // Android-specific deep link handling
    final uri = Uri.tryParse(window.defaultRouteName);

    if (uri != null) {
      if (uri.host == 'login-success') {
        // Handle successful login
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (uri.host == 'login-failure') {
        // Handle failed login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    }
  }
}
