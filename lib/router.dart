// router.dart
import 'package:ebooks_and_audiobooks/pages/category_page.dart';
import 'package:ebooks_and_audiobooks/pages/e_books_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_write_functions/check_user_logged_in.dart';
import 'main.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/profile_page.dart';

// Set up the router
final GoRouter router = GoRouter(
  initialLocation: '/', // Start at home by default
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/ebooks',
      builder: (context, state) => const EBooksPage(),
    ),
  ],
  redirect: (context, state) {
    final isLoggedIn = checkUserLoggedInSync(); // Sync version of checking login status
    final loggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn && !loggingIn) return '/login'; // Redirect to login if not logged in
    if (isLoggedIn && loggingIn) return '/'; // Redirect to home if already logged in

    return null; // No redirect
  },
);
