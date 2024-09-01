// pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/profile'); // Navigate to ProfilePage
          },
          child: const Text('Go to Profile'),
        ),
      ),
    );
  }
}
