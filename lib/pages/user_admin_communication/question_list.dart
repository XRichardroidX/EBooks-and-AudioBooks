import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../constants/app_write_constants.dart';
import '../../style/colors.dart';
import 'admin_anwsers.dart';

class QuestionsListPage extends StatefulWidget {
  @override
  _QuestionsListPageState createState() => _QuestionsListPageState();
}

class _QuestionsListPageState extends State<QuestionsListPage> {
  final Client _client = Client()
    ..setEndpoint(Constants.endpoint)
    ..setProject(Constants.projectId);

  late final Databases _databases;
  List<Document> _questions = [];
  bool _isLoading = true;
  bool _isSlowLoading = false;

  @override
  void initState() {
    super.initState();
    _databases = Databases(_client);
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    // Start a timer to track slow loading
    Future.delayed(Duration(seconds: 1), () {
      if (_isLoading) {
        setState(() {
          _isSlowLoading = true; // Turn indicator red if loading takes over 1 second
        });
      }
    });

    // Load cached data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedQuestionsList');

    if (cachedData != null && cachedData.isNotEmpty) {
      // Parse the cached data
      final List<dynamic> jsonData = jsonDecode(cachedData);
      setState(() {
        _questions = jsonData.map((data) => Document.fromMap(data)).toList();
        _isLoading = false;
      });
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
      prefs.setString('cachedQuestionsList', jsonEncode(questions.map((q) => q.toMap()).toList()));

      // Update UI
      setState(() {
        _questions = questions;
        _isLoading = false;
        _isSlowLoading = false; // Reset loading state
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load questions')),
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
      prefs.setString('cachedQuestionsList', jsonEncode(questions.map((q) => q.toMap()).toList()));

      // Update UI with new data if necessary
      if (mounted) {
        setState(() {
          _questions = questions;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update questions')),
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
        title: Text('User Questions', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.backgroundSecondary,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: _isSlowLoading ? Colors.red : AppColors.buttonPrimary,
        ),
      )
          : _questions.isEmpty
          ? Center(child: Text('No questions available', style: TextStyle(color: AppColors.textPrimary)))
          : ListView.builder(
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final question = _questions[index];
          return ListTile(
            title: Text(
              question.data['questionTitle'] ?? 'Wait...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.data['questionContent'] ?? 'No content available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  "Reply: ${question.data['questionReply'] ?? 'No reply yet'}",
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                Divider(color: AppColors.dividerColor),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReplyQuestionPage(questionId: question.$id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
