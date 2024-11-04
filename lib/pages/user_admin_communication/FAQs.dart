import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../constants/app_write_constants.dart';
import '../../style/colors.dart';

class FAQsPage extends StatefulWidget {
  @override
  _FAQsPageState createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  final Client _client = Client()
    ..setEndpoint(Constants.endpoint)
    ..setProject(Constants.projectId);

  late final Databases _databases;
  List<Document> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databases = Databases(_client);
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedQuestions');

    if (cachedData != null && cachedData.isNotEmpty) {
      // Load data from cache
      final List<dynamic> jsonData = jsonDecode(cachedData);
      setState(() {
        _questions = jsonData.map((data) => Document.fromMap(data)).toList();
        _isLoading = false;
      });
      // Fetch updates in the background
      fetchQuestionsInBackground();
    } else {
      // Load data from Appwrite if no cached data
      await fetchQuestionsFromAppwrite();
    }
  }

  Future<void> fetchQuestionsFromAppwrite() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: Constants.databaseId,
        collectionId: Constants.questionCollectionId,
      );
      final questions = response.documents.reversed.toList();

      // Cache the fetched data
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('cachedQuestions', jsonEncode(questions.map((q) => q.toMap()).toList()));

      // Update UI
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load FAQs')),
      );
    }
  }

  Future<void> fetchQuestionsInBackground() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: Constants.databaseId,
        collectionId: Constants.questionCollectionId,
      );
      final questions = response.documents.reversed.toList();

      // Update cache if new data is available
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('cachedQuestions', jsonEncode(questions.map((q) => q.toMap()).toList()));

      // Update UI with new data if necessary
      if (mounted) {
        setState(() {
          _questions = questions;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update FAQs')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_back_ios)),
        title: Text('FAQs', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.backgroundSecondary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
          : _questions.isEmpty
          ? Center(child: Text('No FAQs available', style: TextStyle(color: AppColors.textPrimary)))
          : ListView.builder(
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final question = _questions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              color: AppColors.cardBackground,
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                title: Text(
                  question.data['questionTitle'] ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.data['questionContent'] ?? 'No content available',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 10),
                        Text(
                          question.data['questionReply'] ?? "No reply yet",
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
