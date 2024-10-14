import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/appwrite.dart';

import '../../constants/app_write_constants.dart'; // Import Appwrite SDK

class LogoutPage extends StatelessWidget {
  const LogoutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logout'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showLogoutDialog(context);
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                Navigator.of(context).pop(); // Close the dialog
                context.go('/login'); // Navigate to the login page
                await _logoutFromAppwrite(context); // Log out of Appwrite
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logoutFromAppwrite(BuildContext context) async {
    Client client = Client();
    Account account = Account(client);

    // Initialize the Appwrite client
    client
        .setEndpoint(Constants.endpoint) // Set your Appwrite API endpoint
        .setProject(Constants.projectId); // Set your Appwrite project ID

    try {
      // Call the Appwrite logout API
      await account.deleteSession(sessionId: 'current'); // Log out of the current session
      context.go('/login'); // Navigate to the login page after logout
    } catch (e) {
      // Handle error (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
}
