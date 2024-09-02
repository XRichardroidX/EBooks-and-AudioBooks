import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:ebooks_and_audiobooks/widget/snack_bar_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../firebase_functions/google_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false; // State to track loading

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Center(child: Text(
            'Login Page',
          style: TextStyle(
            color: AppColors.textHighlight
          ),
        )),
      ),
      body: Container(
        color: AppColors.backgroundPrimary,
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.5,
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true; // Start loading indicator
                      });

                      try {
                        UserCredential? userCredential = await signInWithGoogle(context);

                        if (userCredential != null) {
                          // Handle successful sign-in, e.g., navigate to the home page
                          print('Sign-in successful: ${userCredential.user?.email}');
                          // Navigate to EBooksPage
                          context.go('/menuscreens'); // Replace with your route name
                        } else {
                          // Handle sign-in failure
                          showCustomSnackbar(context, 'Authentication', 'Sign-in failed. Please try again.', AppColors.warning);
                        }
                      } catch (e) {
                        // Handle any errors during sign-in
                        showCustomSnackbar(context, 'Authentication', 'An error occurred during sign-in.', AppColors.error);
                      } finally {
                        setState(() {
                          isLoading = false; // Stop loading indicator
                        });
                      }
                    },
                    child: const Text(
                        'Sign in with Google',
                      style: TextStyle(
                        color: AppColors.backgroundPrimary
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/signup'); // Navigate to the signup page
                    },
                    child: Container(
                      child: const Text(
                          'Create an account',
                        style: TextStyle(
                            color: AppColors.textHighlight
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(), // Loading indicator
              ),
          ],
        ),
      ),
    );
  }
}
