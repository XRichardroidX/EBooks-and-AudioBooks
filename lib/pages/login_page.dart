import 'package:novel_world/style/colors.dart';
import 'package:novel_world/widget/snack_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_write_constants.dart'; // Firebase for email/password authentication

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false; // State to track loading
  bool _isPasswordVisible = false; // State to track password visibility

  // Function to log the user in with email and password using Firebase
  Future<void> _loginWithEmailPassword(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Sign in with email and password using Firebase
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Navigate to the home screen upon successful login
        context.go('/menuscreens'); // Replace with your home screen route

        // Show success message
        showCustomSnackbar(context, 'Login', 'Login successful!', AppColors.success);
      } catch (e) {
        showCustomSnackbar(context, 'Login Failed', 'Invalid credentials or error occurred.', AppColors.error);
        print('Login error: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Screen.initialize(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Center(
          child: Text(
            'Login Page',
            style: TextStyle(color: AppColors.textHighlight),
          ),
        ),
      ),
      body: Container(
        color: AppColors.backgroundPrimary,
        height: Screen.height,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.2,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email input field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: AppColors.textHighlight),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),

                          // Password input field with show/hide toggle
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible, // Toggle visibility
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: AppColors.textHighlight),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),

                          // Login button
                          ElevatedButton(
                            onPressed: () => _loginWithEmailPassword(context),
                            child: const Text(
                              'Login with Email',
                              style: TextStyle(color: AppColors.backgroundPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Button to navigate to signup page
                    ElevatedButton(
                      onPressed: () {
                        context.push('/signup'); // Navigate to the signup page
                      },
                      child: const Text(
                        'Create an account',
                        style: TextStyle(color: AppColors.textHighlight),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading indicator
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
