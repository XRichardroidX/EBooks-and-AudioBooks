import 'package:flutter/material.dart';
import 'package:novel_world/pages/book_search.dart';
import 'package:novel_world/pages/book_list_page.dart';
import 'package:novel_world/pages/settings_option/settings_page.dart';
import 'package:novel_world/pages/update_app_page.dart';
import 'package:novel_world/style/colors.dart';
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

  Future<void> _loadStoredVersion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      AppwriteAppVersion = prefs.getString('appVersion') ?? 'v2';
    });
  }

  Future<void> _storeVersion(String version) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('appVersion', version);
  }

  Future<void> _checkForUpdates() async {
    try {
      var document = await databases.getDocument(
        databaseId: Constants.databaseId,
        collectionId: Constants.configurationCollectionId,
        documentId: Constants.configurationDocumentId,
      );

      String latestVersion = document.data['APPLICATION_VERSION'];
      _storeVersion(latestVersion);

      setState(() {
        AppwriteAppVersion = latestVersion;
      });

      if (AppwriteAppVersion != appVersion) {
        _showUpdatePrompt();
      }
    } catch (e) {
      print('Error fetching application version: $e');
    }
  }

  void _showUpdatePrompt() async {
    if (mounted) {
      await Future.delayed(Duration(seconds: 2));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => UpdatePromptPage()),
      );
    }
  }

  final List<Widget> _pages = [
    EBooksPage(),
    FilterBooksPage(),
    BookListPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        // Limit the screen size
        final double limitedWidth = maxWidth > 1200 ? 1200 : maxWidth;
        final double limitedHeight = maxHeight > 1200 ? 1200 : maxHeight;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: limitedWidth,
              maxHeight: limitedHeight,
            ),
            child: DefaultTabController(
              length: _pages.length,
              child: Scaffold(
                appBar: AppBar(
                  toolbarHeight: 12,
                  backgroundColor: AppColors.backgroundSecondary,
                  bottom: TabBar(
                    indicatorColor: AppColors.textHighlight,
                    onTap: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    tabs: [
                      Tab(
                        icon: Icon(Icons.menu_book_sharp, color: AppColors.iconColor),
                        child: Text('E-Books', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                      Tab(
                        icon: Icon(Icons.search, color: AppColors.iconColor),
                        child: Text('Search', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                      Tab(
                        icon: Icon(Icons.bookmark, color: AppColors.iconColor),
                        child: Text('Return', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                      Tab(
                        icon: Icon(Icons.settings, color: AppColors.iconColor),
                        child: Text('Settings', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                ),
                body: AppwriteAppVersion == appVersion
                    ? TabBarView(children: _pages)
                    : UpdatePromptPage(),
                backgroundColor: AppColors.backgroundPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
