import 'package:ebooks_and_audiobooks/pages/e_books_page.dart';
import 'package:ebooks_and_audiobooks/pages/login_page.dart';
import 'package:ebooks_and_audiobooks/router.dart';
import 'package:flutter/material.dart';
import 'app_write_service.dart'; // Import the Appwrite configuration

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter environment is initialized
  await appWriteId(); // Initialize Appwrite client
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

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkUserLoggedIn(), // Future to check user login status
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: const CircularProgressIndicator()); // Loading indicator while checking
        } else if (snapshot.hasData && snapshot.data == true) {
          return const EBooksPage(); // User is logged in, show home page
        } else {
          return const LoginPage(); // User is not logged in, show login page
        }
      },
    );
  }
}




