import 'dart:math';
import 'package:novel_world/style/colors.dart';
import 'package:novel_world/widget/snack_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:appwrite/appwrite.dart';
import '../constants/app_write_constants.dart';
import 'package:uuid/uuid.dart'; // For generating unique user IDs

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Client client = Client()
      .setEndpoint(Constants.endpoint) // Your Appwrite endpoint
      .setProject(Constants.projectId); // Your Appwrite project ID

  final uuid = Uuid();

  // Function to generate random alphanumeric string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  Future<void> _signup(BuildContext context) async {
    Databases databases = Databases(client);
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        FirebaseAuth auth = FirebaseAuth.instance;
        String username = _usernameController.text.trim();
        String email = _emailController.text.trim();
        String password = _passwordController.text.trim();

        // Check if username is already taken in Appwrite
        var usernameResponse = await databases.listDocuments(
          databaseId: Constants.databaseId,
          collectionId: Constants.usersCollectionId,
          queries: [Query.equal('userName', username)],
        );

        if (usernameResponse.documents.isNotEmpty) {
          showCustomSnackbar(
              context, 'Signup Failed', 'Username already in use.', AppColors.error);
          return;
        }

        // Check if email is already taken in Appwrite
        var emailResponse = await databases.listDocuments(
          databaseId: Constants.databaseId,
          collectionId: Constants.usersCollectionId,
          queries: [Query.equal('email', email)],
        );

        if (emailResponse.documents.isNotEmpty) {
          showCustomSnackbar(
              context, 'Signup Failed', 'Email already in use.', AppColors.error);
          return;
        }

        // Sign up user with Firebase Authentication
        UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          // Get Firebase user ID
          String firebaseUserId = firebaseUser.uid;

          // Add user data to Appwrite database
          await databases.createDocument(
            databaseId: Constants.databaseId,
            collectionId: Constants.usersCollectionId,
            documentId: uuid.v4(),
            data: {
              'userName': username.toLowerCase(),
              'email': email,
              'password': password, // Ideally, you should hash passwords
              'timeStamp': DateTime.now().toIso8601String(),
              'startSub': '',
              'endSub': '',
              'userId': '$firebaseUserId', // Store Firebase user ID in Appwrite
            },
            permissions: [
              Permission.read(Role.any()), // Allow any user to read the document
              Permission.write(Role.any()), // Allow any user to write to the document
            ],
          );

          showCustomSnackbar(context, 'Signup', 'Signup successful!', AppColors.success);
          context.go('/menuscreens'); // Navigate to the home page
        }
      } catch (e) {
        String errorMessage;

        if (e is FirebaseAuthException) {
          if (e.code == 'email-already-in-use') {
            errorMessage = 'This email is already in use';
          } else if (e.code == 'weak-password') {
            errorMessage = 'The password is too weak';
          } else {
            errorMessage = 'Authentication error: ${e.message}';
          }
        } else {
          errorMessage = '$e An error occurred. Please try again.';
          print(e);
        }

        showCustomSnackbar(context, 'Signup Failed', errorMessage, AppColors.error);
        print('Signup error: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // Improved email validation pattern
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailPattern);

    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    Screen.initialize(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Center(
          child: Text(
            'Signup Page',
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
                          // Username input
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              labelStyle: TextStyle(color: AppColors.textHighlight),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),
                          // Email input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: AppColors.textHighlight),
                              border: OutlineInputBorder(),
                            ),
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 20.0),
                          // Password input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: AppColors.textHighlight),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
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
                          // Confirm password input
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: const TextStyle(color: AppColors.textHighlight),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),
                          // Signup button
                          ElevatedButton(
                            onPressed: () => _signup(context),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(color: AppColors.backgroundPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
