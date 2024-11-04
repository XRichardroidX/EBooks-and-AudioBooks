import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_write_constants.dart';
import '../../style/colors.dart';

class QuestionSubmissionPage extends StatefulWidget {
  @override
  _QuestionSubmissionPageState createState() => _QuestionSubmissionPageState();
}

class _QuestionSubmissionPageState extends State<QuestionSubmissionPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;

  // Initialize Appwrite client and database
  final Client _client = Client()
    ..setEndpoint(Constants.endpoint) // Your Appwrite endpoint
    ..setProject(Constants.projectId); // Your Appwrite project ID

  late final Databases _databases;

  @override
  void initState() {
    super.initState();
    _databases = Databases(_client);
  }

  Future<void> uploadQuestion() async {
    setState(() => _isLoading = true);

    try {
      await _databases.createDocument(
        databaseId: Constants.databaseId,
        collectionId: Constants.questionCollectionId,
        documentId: 'unique()', // Generates a unique ID for each document
        data: {
          'questionTitle': _titleController.text,
          'questionContent': _questionController.text,
          'questionReply': null, // Placeholder for admin response
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      _titleController.clear();
      _questionController.clear();
      Navigator.pop(context); // Pop the page

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit question. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: AppColors.textPrimary
        ),
        leading: IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_back_ios)),
        title: Text('Submit Question', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.backgroundSecondary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              enabled: !_isLoading,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Question Title',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.dividerColor),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _questionController,
              enabled: !_isLoading,
              maxLines: 8,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Write your question here',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.dividerColor),
                ),
              ),
            ),
            SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : uploadQuestion,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary, backgroundColor: AppColors.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: AppColors.textPrimary)
                      : Text('Submit Question'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
