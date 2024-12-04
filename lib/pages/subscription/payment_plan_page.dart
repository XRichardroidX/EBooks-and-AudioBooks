import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:novel_world/style/colors.dart';
import 'package:novel_world/widget/snack_bar_message.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  // Function to handle subscription button tap for recurring payment
  void _onSubscribeTap(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      showCustomSnackbar(
        context,
        'Subscription Failed',
        'No user is currently logged in.',
        AppColors.error,
      );
      print('User is not logged in.');
      return;
    }

    final email = currentUser.email;

    // Redirect user to Paystack recurring payment page
    _redirectToPaystackRecurringPayment(context, email!);
  }

  // Redirects the user to Paystack recurring payment page with their email prefilled
  Future<void> _redirectToPaystackRecurringPayment(BuildContext context, String email) async {
    const String paystackUrl = 'https://paystack.com/pay/j9dmo9lc0f';
    final Uri paymentUri = Uri.parse('$paystackUrl?email=$email');

    try {
      // Launch the Paystack payment page
      if (await canLaunchUrl(paymentUri)) {
        await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $paymentUri';
      }
    } catch (e) {
      showCustomSnackbar(
        context,
        'Error',
        'Failed to redirect to payment page: ${e.toString()}',
        AppColors.error,
      );
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Netflix-style dark background
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_back_ios)),
        actions: [
          IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_forward_ios)),
        ],
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        title: const Center(
          child: Text(
            'Subscribe to Novel City',
            style: TextStyle(
              color: AppColors.textHighlight,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                'Unlimited Access to Thousands of Books!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Choose a plan that works best for you and your family.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Subscription Plan
              _buildSubscriptionPlan(
                context,
                'Recurring Plan',
                'Unlimited books for a recurring subscription',
                '₦1000/month',
                'Subscribe Now',
                AppColors.textHighlight,
                    () => _onSubscribeTap(context),
              ),
              const SizedBox(height: 40),

              // Footer section or additional message
              Text(
                'Enjoy thousands of books, no ads, and offline reading!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White button
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    color: AppColors.textHighlight,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build the subscription plan card
  Widget _buildSubscriptionPlan(
      BuildContext context,
      String title,
      String description,
      String price,
      String buttonText,
      Color color,
      VoidCallback onTap,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            price,
            style: TextStyle(
              color: AppColors.textHighlight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textHighlight,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                buttonText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
