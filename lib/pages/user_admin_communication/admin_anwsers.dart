import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_write_constants.dart';
import '../../style/colors.dart';

class ReplyQuestionPage extends StatefulWidget {
  final String questionId;

  ReplyQuestionPage({required this.questionId});

  @override
  _ReplyQuestionPageState createState() => _ReplyQuestionPageState();
}

class _ReplyQuestionPageState extends State<ReplyQuestionPage> {
  final TextEditingController _replyController = TextEditingController();
  final Client _client = Client()
    ..setEndpoint(Constants.endpoint)
    ..setProject(Constants.projectId);

  late final Databases _databases;
  bool _isSubmitting = false;
  late Future<Document> _questionFuture;

  @override
  void initState() {
    super.initState();
    _databases = Databases(_client);
    _questionFuture = fetchQuestionData();
  }

  Future<Document> fetchQuestionData() async {
    try {
      return await _databases.getDocument(
        databaseId: Constants.databaseId,
        collectionId: Constants.questionCollectionId,
        documentId: widget.questionId,
      );
    } catch (e) {
      throw Exception("Failed to load question data");
    }
  }

  Future<void> submitReply() async {
    setState(() => _isSubmitting = true);

    try {
      await _databases.updateDocument(
        databaseId: Constants.databaseId,
        collectionId: Constants.questionCollectionId,
        documentId: widget.questionId,
        data: {'questionReply': _replyController.text},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reply submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context); // Go back after submitting

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit reply. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_back_ios)),
        title: Text('Reply to Question', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.backgroundSecondary,
      ),
      body: FutureBuilder<Document>(
        future: _questionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.red, // Red loading indicator
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load question data',
                style: TextStyle(color: AppColors.error),
              ),
            );
          } else if (snapshot.hasData) {
            final question = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.data['questionTitle'] ?? 'No Title',
                    style: TextStyle(color: AppColors.textHighlight, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    question.data['questionContent'] ?? 'No Content',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _replyController,
                    enabled: !_isSubmitting,
                    maxLines: 6,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Write your reply here',
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
                        onPressed: _isSubmitting ? null : submitReply,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: AppColors.buttonPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(
                          color: Colors.red, // Red indicator for loading
                        )
                            : Text('Submit Reply'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Text(
                'No question data found.',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            );
          }
        },
      ),
    );
  }
}
