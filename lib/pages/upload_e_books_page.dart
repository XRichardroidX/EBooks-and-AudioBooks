import 'package:flutter/material.dart';
import '../new_app/back_end/app_write_functions.dart'; // Import your backend functions
import '../style/colors.dart'; // Import your color styles

class UploadEBooksPage extends StatefulWidget {
  const UploadEBooksPage({super.key});

  @override
  State<UploadEBooksPage> createState() => _UploadEBooksPageState();
}

class _UploadEBooksPageState extends State<UploadEBooksPage> {
  // Create controllers for the text fields
  final TextEditingController _bookTitleController = TextEditingController();
  final TextEditingController _authorNameController = TextEditingController();
  final TextEditingController _bookSummaryController = TextEditingController();

  // Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Text(
          'Upload E-Books',
          style: TextStyle(
            color: AppColors.textHighlight,
          ),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: AppColors.backgroundPrimary,
        padding: const EdgeInsets.all(16.0), // Add padding for better UI
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _bookTitleController,
                decoration: InputDecoration(
                  labelText: 'Book Title',
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textHighlight),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a book title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0), // Spacing between fields
              TextFormField(
                controller: _authorNameController,
                decoration: InputDecoration(
                  labelText: 'Author Name',
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textHighlight),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the author name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0), // Spacing between fields
              TextFormField(
                controller: _bookSummaryController,
                decoration: InputDecoration(
                  labelText: 'Book Summary',
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textHighlight),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                maxLines: 5, // Allow multiline input for summary
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a book summary';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPrimary,
        onPressed: () {
          // Validate the form
          if (_formKey.currentState!.validate()) {
            // If the form is valid, proceed with uploading the data
            uploadBookToDatabase(
              _bookTitleController.text,
              _authorNameController.text,
              _bookSummaryController.text,
            );
            Navigator.pop(context);
          }
        },
        child: const Icon(
          Icons.upload,
          color: AppColors.textHighlight,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _bookTitleController.dispose();
    _authorNameController.dispose();
    _bookSummaryController.dispose();
    super.dispose();
  }
}
