import 'package:ebooks_and_audiobooks/pages/audio_books_page.dart';
import 'package:ebooks_and_audiobooks/pages/category_page.dart';
import 'package:ebooks_and_audiobooks/pages/download_page.dart';
import 'package:ebooks_and_audiobooks/pages/e_books_page.dart';
import 'package:ebooks_and_audiobooks/pages/payment_plan_page.dart';
import 'package:go_router/go_router.dart';
import 'main.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

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
      path: '/category',
      builder: (context, state) => const CategoryPage(),
    ),
    GoRoute(
      path: '/ebooks',
      builder: (context, state) => const EBooksPage(),
    ),
    GoRoute(
      path: '/audiobooks',
      builder: (context, state) => const AudioBooksPage(),
    ),
    GoRoute(
      path: '/downloads',
      builder: (context, state) => const DownloadPage(),
    ),
    GoRoute(
      path: '/paymentplan',
      builder: (context, state) => const PaymentPlanPage(),
    ),
  ],
  redirect: (context, state) {
    // final isLoggedIn = checkUserLoggedInSync(); // Sync version of checking login status
    // final loggingIn = state.matchedLocation == '/login';
    //
    // if (!isLoggedIn && !loggingIn) return '/login'; // Redirect to login if not logged in
    // if (isLoggedIn && loggingIn) return '/'; // Redirect to home if already logged in
    //
    // return null; // No redirect
  },
);
