import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_write_service.dart';

Future<void> loginWithGoogle(BuildContext context) async {
  try {
    final result = await account!.createOAuth2Session(
      provider: OAuthProvider.google,
      success: 'http://localhost:52000', // Use Appwrite's allowed URL
      failure: 'https://cloud.appwrite.io/v1/account/sessions/oauth2/callback/google', // Use Appwrite's allowed URL
    );

    await Future.delayed(Duration(microseconds: 1000));
    if (result != null) {
      // User successfully logged in, redirect to home page
     context.go('/ebooks');
    }
    else {
      // Login failed, display error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed!')),
      );
    }
  } catch (e) {
    print('Google login error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An error occurred during login.')),
    );
  }
}
