import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../new_app/back_end/app_write_upload_e_books.dart'; // Import your backend functions
import '../new_app/back_end/p_cloud_upload.dart';
import '../style/colors.dart';
import '../widget/snack_bar_message.dart'; // Import your color styles

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

// Define categories
  final List<String> _categories = [
    'Fiction',
    'Non-fiction',
    'Science',
    'History',
    'Fantasy',
    'Biography',
    'Mystery',        // New category
    'Romance',        // New category
    'Thriller',       // New category
    'Self-help',      // New category
    'Health',         // New category
    'Children',       // New category
    'Young Adult',    // New category
    'Travel',         // New category
    'Cookbooks',      // New category
    'Poetry',         // New category
    'Religion',       // New category
    'Philosophy',     // New category
    'Classic',        // New category
  ];

  String? _selectedCategory;

  Uint8List? bookCover;
  File? selectedPdf;

  Future<void> _selectBookCover(BuildContext context, bool imageFrom) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (imageFrom) {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        bookCover = await image!.readAsBytes();
      } else {
        final XFile? photo = await picker.pickImage(source: ImageSource.camera);
        bookCover = await photo!.readAsBytes();
      }

      if (bookCover!.isNotEmpty) {
        setState(() {});
      }
    } on PlatformException catch (e) {
      showCustomSnackbar(context, 'Select Image', '$e', AppColors.error);
    }
  }

  Future<void> _selectPdf() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedPdf = File(result.files.single.path!);
      });
    }
  }

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
      body: SingleChildScrollView(
        child: Container(
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
                const SizedBox(height: 16.0), // Spacing between fields
                // Dropdown for book category
                DropdownButtonFormField<String>(
                  dropdownColor: AppColors.backgroundPrimary,
                  decoration: InputDecoration(
                    labelText: 'Book Category',
                    labelStyle: TextStyle(color: AppColors.textPrimary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textHighlight),
                    ),
                  ),
                  value: _selectedCategory,
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: TextStyle(color: AppColors.textPrimary), // Text color set to white
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  style: TextStyle(color: AppColors.textPrimary), // Selected text color set to white
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a book category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0), // Spacing between fields
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _selectBookCover(context, true);
                        },
                        child: const Text('Select Image from Gallery'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _selectBookCover(context, false);
                        },
                        child: const Text('Take a picture'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _selectPdf();
                        },
                        child: const Text('Select PDF'),
                      ),
                      const SizedBox(height: 16),
                      if (bookCover != null)
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width *
                                0.3, // Image width
                            height: MediaQuery.of(context).size.width *
                                0.3, // Image height
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: MemoryImage(bookCover!),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (selectedPdf != null)
                        Text(
                          'Selected PDF: ${selectedPdf!.path}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPrimary,
        onPressed: () async {
          if (bookCover == null || selectedPdf == null) {
            showCustomSnackbar(
                context, 'Error', 'Please select an image and a PDF file.', AppColors.error);
            return;
          }

          Map<String, String>? pCloudResult;
          try {
            pCloudResult = await uploadEBookToPCloud(context, bookCover!, selectedPdf!);
          } catch (e) {
            showCustomSnackbar(context, 'Upload Error', 'Failed to upload eBook: $e', AppColors.error);
            return;
          }

          if (pCloudResult == null || pCloudResult.isEmpty || pCloudResult['imageUrl'] == null || pCloudResult['pdfUrl'] == null) {
            showCustomSnackbar(context, 'Upload Error', 'Failed to upload eBook. Please try again.', AppColors.error);
            return;
          }

          if (_formKey.currentState!.validate()) {
            await uploadBookToDatabase(
                _bookTitleController.text,
                _authorNameController.text,
                _bookSummaryController.text,
                pCloudResult['imageUrl']!,
                pCloudResult['pdfUrl']!,
                _selectedCategory ?? 'Uncategorized');
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
    _bookTitleController.dispose();
    _authorNameController.dispose();
    _bookSummaryController.dispose();
    super.dispose();
  }
}
