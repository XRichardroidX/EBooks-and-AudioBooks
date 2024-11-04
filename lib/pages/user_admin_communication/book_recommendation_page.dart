import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_write_constants.dart';
import '../../style/colors.dart';

class BookRecommendationPage extends StatefulWidget {
  @override
  _BookRecommendationPageState createState() => _BookRecommendationPageState();
}

class _BookRecommendationPageState extends State<BookRecommendationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
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

  Future<void> uploadBook() async {
    setState(() => _isLoading = true);

    try {
      await _databases.createDocument(
        databaseId: Constants.databaseId,
        collectionId: Constants.recommendCollectionId,
        documentId: 'unique()', // Generates a unique ID for each document
        data: {
          'bookTitle': _titleController.text,
          'authorNames': _authorController.text.isNotEmpty ? _authorController.text : null,
        },
      );

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book uploaded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Clear text fields
      _titleController.clear();
      _authorController.clear();
      Navigator.pop(context); // Pop the page

    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload book. Please try again.'),
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
        title: Text('Book Request', style: TextStyle(color: AppColors.textPrimary)),
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
                labelText: 'Book Title',
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
              controller: _authorController,
              enabled: !_isLoading,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Author Names (Optional)',
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
                  onPressed: _isLoading ? null : uploadBook,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary, backgroundColor: AppColors.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: AppColors.textPrimary)
                      : Text('Upload Book'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
