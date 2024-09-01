// pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_write_functions/app_write_auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Login Page')),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Perform login logic here and navigate to home on success
                loginWithGoogle(context);
              },
              child: const Text('Sign in with Google'),
            ),
          ),
          SizedBox(
            height: 20.0,
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Perform login logic here and navigate to home on success
                context.push('/signup');
              },
              child: const Text('Create an account'),
            ),
          ),
        ],
      ),
    );
  }
}
