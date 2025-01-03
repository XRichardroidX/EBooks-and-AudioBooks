import 'package:appwrite/appwrite.dart';
import 'package:novelcity/pages/authentication/forgot_password.dart';
import 'package:novelcity/style/colors.dart';
import 'package:novelcity/widget/snack_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_write_constants.dart';

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

  final Client client = Client();
  late Databases databases;

  @override
  void initState() {
    // TODO: implement initState
    initializeAppwrite();
    super.initState();
  }

  void initializeAppwrite() {
    // Initialize the Appwrite client with endpoint and project ID from constants
    client
        .setEndpoint(Constants.endpoint) // e.g., 'https://cloud.appwrite.io/v1'
        .setProject(Constants.projectId); // Your project ID

    databases = Databases(client);
    print('Appwrite Client Initialized');
  }

// Function to log the user in with email and password using Firebase
  Future<void> _loginWithEmailPassword(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Sign in with email and password using Firebase
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Get the Firebase userId after successful login
        String firebaseUserId = userCredential.user!.uid;

        // Now search for the user in the Appwrite database using this Firebase userId
        // Assuming you have a users collection in Appwrite with 'firebaseUserId' as an attribute
        var response = await databases.listDocuments(
          databaseId: Constants.databaseId,
          collectionId: Constants.usersCollectionId,
          queries: [Query.equal('userId', firebaseUserId)],
        );

        if (response.documents.isNotEmpty) {
          // Get the first matching user document
          var userDocument = response.documents.first;

          // Extract the 'startSub' and 'endSub' attributes
          String startSub = userDocument.data['startSub'];
          String endSub = userDocument.data['endSub'];

          // Save the 'startSub' and 'endSub' to Shared Preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('$firebaseUserId+startSub', startSub);
          prefs.setString('$firebaseUserId+endSub', endSub);

         // Navigate to the home screen upon successful login
          context.go('/menuscreens'); // Replace with your home screen route

          // Show success message
          showCustomSnackbar(context, 'Login', 'Login successful!', AppColors.success);
        } else {
          // Handle case where no user is found in the Appwrite database
          showCustomSnackbar(context, 'Login Failed', 'User not found in Appwrite.', AppColors.error);
        }
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
        iconTheme: IconThemeData(
          color: AppColors.textPrimary
        ),
        leading: IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_back_ios)),
        actions: [
          IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_forward_ios)),
        ],
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
                            style: const TextStyle(color: AppColors.textPrimary),
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
                            style: const TextStyle(color: AppColors.textPrimary),
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
                          const SizedBox(height: 15.0),
                          InkWell(
                            onTap: (){
                              context.push('/forgotpassword');
                            },
                            child: Container(
                              alignment: Alignment.topRight,
                              child: Text(
                                  'Forgot password?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textHighlight
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),

                          // Login button
                          ElevatedButton(
                            onPressed: () => _loginWithEmailPassword(context),
                            child: const Text(
                              '         LOGIN          ',
                              style: TextStyle(
                                fontSize: 16,
                                  color: AppColors.backgroundPrimary
                              ),
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
                        'CREATE ACCOUNT',
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
                child: CircularProgressIndicator(color: AppColors.buttonPrimary,),
              ),
          ],
        ),
      ),
    );
  }
}
