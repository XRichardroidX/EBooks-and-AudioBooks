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
  void _onSubscribeTap(BuildContext context, subType) async {
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
    _redirectToPaystackRecurringPayment(context, email!, subType);
  }

  // Redirects the user to Paystack recurring payment page with their email prefilled
  Future<void> _redirectToPaystackRecurringPayment(BuildContext context, String email, String subType) async {


    String paystackUrl = subType == 'monthly' ? 'https://paystack.com/pay/kyvcpqze50' : 'https://paystack.com/pay/y6kawu2nlz';
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                'Unlimited Access to Millions of Stories!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'Choose a plan that works best for you and your family.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subscription Plan
              _buildSubscriptionPlan(
                context,
                'Monthly Plan',
                'Unlimited books for a whole Month on a recurring subscription plan',
                '₦2,500/Month',
                'Subscribe Now',
                AppColors.textHighlight,
                    () => doNotModifyEmailWarning(context, 'monthly'),
              ),
              const SizedBox(height: 10),
             // Subscription Plan
              _buildSubscriptionPlan(
                context,
                'Yearly Plan',
                'Unlimited books for 12 whole Months on a recurring subscription plan',
                '₦25,000/Year',
                'Subscribe Now',
                AppColors.textHighlight,
                    () => doNotModifyEmailWarning(context, 'yearly'),
              ),
              // Footer section or additional message
              Text(
                'Enjoy thousands of books, no ads, and offline reading!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
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

  // Cancel Subscription Pop-Up message
  void doNotModifyEmailWarning(BuildContext context, String subType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: const Text(
            'About to subscribe',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please do not change the email and replace it with a different one, it is linked with your account, reach out to us if you have any questions.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
               _onSubscribeTap(context, subType); // Close the dialog
               context.pop();
               context.pop();
               context.pushReplacement('/menuscreens');
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                    color: AppColors.textPrimary
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}



