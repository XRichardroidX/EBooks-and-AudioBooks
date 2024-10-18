import 'package:flutter/material.dart';
import 'dart:io'; // For platform detection
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // For closing the app

import '../style/colors.dart'; // Assuming this is the path to your AppColors file

class UpdatePromptPage extends StatefulWidget {
  @override
  _UpdatePromptPageState createState() => _UpdatePromptPageState();
}

class _UpdatePromptPageState extends State<UpdatePromptPage> {
  // Play Store and App Store URLs
  final String playStoreUrl = "https://play.google.com/store/apps/details?id=com.example.app"; // Replace with your Play Store URL
  final String appStoreUrl = "https://apps.apple.com/us/app/example-app/id123456789"; // Replace with your App Store URL

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUpdateDialog(context);
    });
  }

  // Function to launch URL (Play Store or App Store)
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Function to determine platform and open the correct store link
  void _handleUpdate(BuildContext context) {
    if (Platform.isAndroid) {
      _launchURL(playStoreUrl);
    } else if (Platform.isIOS) {
      _launchURL(appStoreUrl);
    }
  }

  // Function to show the update dialog
  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(
            "Update Available",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "A new version of the app is available. Please update to continue.",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            // Close button
            TextButton(
              onPressed: () {
                SystemNavigator.pop(); // Close the app completely
              },
              child: Text(
                "Close",
                style: TextStyle(
                  color: AppColors.textHighlight,
                  fontSize: 18,
                ),
              ),
            ),
            // Update button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary, // Netflix Red for primary button
              ),
              onPressed: () {
                _handleUpdate(context); // Redirect to the respective store
              },
              child: Text(
                "Update",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // No need for any other UI elements since the update prompt will pop up immediately
    return Container(); // An empty container as the dialog will handle the UI
  }
}
