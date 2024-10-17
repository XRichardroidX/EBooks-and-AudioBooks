import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:novel_world/pages/subscription/update_subscription.dart';
import 'package:novel_world/style/colors.dart';
import 'package:novel_world/widget/snack_bar_message.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  // Function to handle subscription button tap
  void _onSubscribeTap(BuildContext context, String planName) async {
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

    try {
      await updateSubscription(currentUser.uid, 'success');
      showCustomSnackbar(
        context,
        'Payment',
        'Payment successful for $planName Plan!',
        AppColors.success,
      );
    } catch (e) {
      showCustomSnackbar(
        context,
        'Subscription Failed',
        'An error occurred while updating your subscription.',
        AppColors.error,
      );
      print('Error processing subscription: $e');
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
        iconTheme: IconThemeData(
          color: AppColors.textPrimary
        ),
        title: const Center(
          child: Text(
            'Subscribe to NovelWorld',
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
              // Title and description section
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

              // Subscription Plans
              _buildSubscriptionPlan(
                context,
                'Monthly Plan',
                'Unlimited books for a month',
                '\₦900/month',
                'Subscribe for 1 Month',
                  AppColors.textHighlight,
                    () => _onSubscribeTap(context, 'for 1 Month'),
              ),
              const SizedBox(height: 30),
              _buildSubscriptionPlan(
                context,
                'Yearly Plan',
                'Unlimited books for 12 whole month',
                '\₦9,000/year',
                'Subscribe for 1 Year',
                  AppColors.textHighlight,
                    () => _onSubscribeTap(context, 'for 1 Year'),
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
                  // Navigate back or to another screen if needed
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

  // Function to build each subscription plan card
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
        color: Colors.grey[900], // Dark grey background for the plan card
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
              backgroundColor: AppColors.textHighlight, // Red Netflix-style button
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
