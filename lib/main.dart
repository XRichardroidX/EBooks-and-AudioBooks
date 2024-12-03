import 'dart:async'; // Required for StreamController
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for authentication
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:novel_world/pages/menu_screens.dart';
import 'package:novel_world/router.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

import 'firebase_options.dart'; // Import universal_io for platform checks

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black54),
        useMaterial3: true,
      ),
      routerConfig: router, // Use your GoRouter instance here
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkUserLoggedIn(), // Future to check user login status
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Loading indicator while checking
        } else if (snapshot.hasData && snapshot.data == true) {
          return MenuScreens(); // User is logged in, show home page
        } else {
          return MenuScreens(); // User is not logged in, show login page
        }
      },
    );
  }



Future<bool> checkUserLoggedIn() async {
  // Check Firebase Authentication to see if the user is logged in
  User? user = FirebaseAuth.instance.currentUser;
  return user != null; // Returns true if a user is logged in, otherwise false
}

// void handleIncomingLinks(BuildContext context) {
//   // This method checks for incoming links
//   if (Platform.isAndroid || Platform.isIOS) {
//     // Android/iOS specific deep link handling
//     final uri = Uri.tryParse(window.defaultRouteName);
//
//     if (uri != null) {
//       if (uri.host == 'login-success') {
//         // Handle successful login
//         Navigator.of(context).pushReplacementNamed('/home');
//       } else if (uri.host == 'login-failure') {
//         Navigator.of(context).pushReplacementNamed('/login');
//         // Handle failed login
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Login failed. Please try again.')),
//         );
//       }
//     }
//  }
}
