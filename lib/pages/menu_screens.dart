import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:novelcity/pages/book_search.dart';
import 'package:novelcity/pages/book_list_page.dart';
import 'package:novelcity/pages/settings_option/settings_page.dart';
import 'package:novelcity/pages/update_app_page.dart';
import 'package:novelcity/style/colors.dart';
import 'package:flutter/material.dart';
import '../constants/app_write_constants.dart';
import 'e_book_pages/e_books_page.dart';
import 'package:appwrite/appwrite.dart'; // Appwrite SDK for checking version
import 'dart:async'; // For periodic checks
import 'package:shared_preferences/shared_preferences.dart'; // For local storage

class MenuScreens extends StatefulWidget {
  int? currentPage;
  MenuScreens({super.key});

  @override
  State<MenuScreens> createState() => _MenuScreensState();
}

class _MenuScreensState extends State<MenuScreens> {
  int? _currentPage;

  String appVersion = 'v2'; // Local app version
  String AppwriteAppVersion = 'v2'; // To be fetched from Appwrite and stored locally

  late Client client;
  late Databases databases;

  @override
  void initState() {
    _currentPage = (widget.currentPage ?? 0);

    // Initialize Appwrite client and databases
    client = Client()
      ..setEndpoint(Constants.endpoint) // Replace with your Appwrite endpoint
      ..setProject(Constants.projectId); // Replace with your Appwrite project ID

    databases = Databases(client);

    super.initState();

    // Load the stored version from local storage
    _loadStoredVersion();

    // Start checking for updates
    _checkForUpdates();

    // Periodically check for updates every 10 seconds
    Timer.periodic(Duration(hours: 1), (timer) {
      _checkForUpdates();
    });
  }

  // Load the stored version from shared preferences
  Future<void> _loadStoredVersion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      AppwriteAppVersion = prefs.getString('appVersion') ?? 'v2'; // Default to 'v1' if not found
    });
  }

  // Store the latest version in shared preferences
  Future<void> _storeVersion(String version) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('appVersion', version);
  }

  // Function to fetch the latest app version from Appwrite
  Future<void> _checkForUpdates() async {
    try {
      var document = await databases.getDocument(
        databaseId: Constants.databaseId, // Replace with your database ID
        collectionId: Constants.configurationCollectionId, // Replace with your collection ID
        documentId: Constants.configurationDocumentId, // Replace with your document ID that contains APPLICATION_VERSION
      );

      String latestVersion = document.data['APPLICATION_VERSION'];

      // Store the version locally
      _storeVersion(latestVersion);

      setState(() {
        AppwriteAppVersion = latestVersion;
      });

      // If there's a version mismatch, trigger the update prompt
      if (AppwriteAppVersion != appVersion) {
        _showUpdatePrompt();
      }
    } catch (e) {
      // Handle errors, e.g., no internet connection
      print('Error fetching application version: $e');
    }
  }

  // Function to show update prompt with 2-second delay
  void _showUpdatePrompt() async {
    if (mounted) {
      await Future.delayed(Duration(seconds: 2));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => UpdatePromptPage()),
      );
    }
  }

  // This List is for Icons that are active
  final List<IconData> _activeIcons = [
    Icons.menu_book_sharp,
    Icons.search,
    Icons.bookmark,
    Icons.settings,
  ];

  // This List is for Icons that are inactive
  final List<IconData> _inactiveIcons = [
    Icons.menu_book_sharp,
    Icons.search,
    Icons.bookmark,
    Icons.settings,
  ];

  // This is widget switches pages on a selected tap
  Widget PageTransition(int currentPage) {
    if (AppwriteAppVersion == appVersion) {
      switch (currentPage) {
        case 0:
          return EBooksPage();
        case 1:
          return FilterBooksPage();
        case 2:
          return BookListPage();
        case 3:
          return SettingsPage();
        default:
          return EBooksPage();
      }
    } else {
      return UpdatePromptPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      // This is the Bottom Navigation bar
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: AppColors.backgroundSecondary,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        items: List.generate(
          _activeIcons.length,
              (index) {
            return _currentPage == index
                ? Icon((_activeIcons[index]), color: AppColors.textPrimary)
                : (Icon((_inactiveIcons[index]), color: AppColors.buttonSecondary));
          },
        ),
      ),
      // This is the App Body
      body: PageTransition(_currentPage!),
    );
  }
}
