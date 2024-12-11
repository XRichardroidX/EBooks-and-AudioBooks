import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // For platform detection
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart'; // For web compatibility
import 'package:flutter/services.dart'; // For closing the app
import 'package:appwrite/appwrite.dart';
import '../constants/app_write_constants.dart';
import '../style/colors.dart';

class UpdatePromptPage extends StatefulWidget {
  @override
  _UpdatePromptPageState createState() => _UpdatePromptPageState();
}

class _UpdatePromptPageState extends State<UpdatePromptPage> {
  late Client _client;
  late Future<Map<String, String>> _urlsFuture;

  @override
  void initState() {
    super.initState();

    // Initialize Appwrite Client
    _client = Client()
      ..setEndpoint(Constants.endpoint) // Replace with your Appwrite endpoint
      ..setProject(Constants.projectId); // Replace with your project ID

    // Fetch URLs from Appwrite
    _urlsFuture = _fetchUrls();

    // Show the update dialog after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUpdateDialog(context);
    });
  }

  // Fetch URLs from Appwrite
  Future<Map<String, String>> _fetchUrls() async {
    final Databases database = Databases(_client);
    try {
      final document = await database.getDocument(
        databaseId: Constants.databaseId,
        collectionId: Constants.configurationCollectionId, // Replace with your collection ID
        documentId: Constants.configurationDocumentId, // Replace with your document ID
      );

      return {
        'androidUrl': document.data['androidUrl'] ?? '',
        'iosUrl': document.data['iosUrl'] ?? '',
        'webUrl': document.data['webUrl'] ?? '',
      };
    } catch (e) {
      throw Exception("Error fetching URLs: $e");
    }
  }

  // Launch a URL in the browser
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (kIsWeb) {
      // On the web, open the URL in a new tab
      if (await canLaunchUrl(uri)) {
        await launchUrlString(
          uri.toString(),
          webOnlyWindowName: '_blank', // Open in a new tab
        );
      } else {
        debugPrint('Could not launch $url');
      }
    } else {
      // For Android and iOS
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch $url');
      }
    }
  }

  // Handle update action based on the platform
  void _handleUpdate(Map<String, String> urls) {
    final url = Platform.isAndroid
        ? urls['androidUrl']
        : Platform.isIOS
        ? urls['iosUrl']
        : urls['webUrl'];

    if (url != null && url.isNotEmpty) {
      _launchURL(url);
    } else {
      _showErrorDialog("No update URL found for your platform.");
    }
  }

  // Show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(
            "Error",
            style: TextStyle(color: AppColors.textHighlight),
          ),
          content: Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "OK",
                style: TextStyle(color: AppColors.textHighlight),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show the update dialog
  void _showUpdateDialog(BuildContext context) async {
    try {
      final urls = await _urlsFuture;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.backgroundPrimary,
            title: Text(
              "Update Available",
              style: TextStyle(
                color: AppColors.textHighlight,
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
                  SystemNavigator.pop();
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
                  backgroundColor: AppColors.buttonPrimary,
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  _handleUpdate(urls); // Launch update URL
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
    } catch (e) {
      _showErrorDialog("Failed to fetch update information. Please try again later.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Empty container, as the dialog handles the UI
  }
}
