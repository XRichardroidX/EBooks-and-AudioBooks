// pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/'); // Navigate back to HomePage
          },
          child: const Text('Back to Home'),
        ),
      ),
    );
  }
}
