import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../new_app/back_end/app_write_functions.dart'; // Import your backend functions
import '../new_app/back_end/mega_functions.dart';
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





  Uint8List? bookCover;
  TextEditingController writeUp = TextEditingController();
  bool pickedImage = false;
  File? selectedPdf;

  Future<void> _selectBookCover(BuildContext context, bool imageFrom) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (imageFrom) {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        bookCover = await image!.readAsBytes();
        pickedImage = true;
      } else {
        final XFile? photo = await picker.pickImage(source: ImageSource.camera);
        bookCover = await photo!.readAsBytes();
        pickedImage = true;
      }

      if (bookCover!.isNotEmpty){
        pickedImage = true;
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
                //Todo Newly added feature
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: (){
                          _selectBookCover(context, true);
                        },
                        child: const Text('Select Image from Gallery'),
                      ),
                      ElevatedButton(
                        onPressed: (){
                          _selectBookCover(context, false);
                        },
                        child: const Text('Take a picture'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: (){
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
                        Text('Selected PDF: ${selectedPdf!.path}'),
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
          Map<String, String> megaResult = await uploadEBookToMegaStorage(context, bookCover!, selectedPdf!);
          // Validate the form
          if (_formKey.currentState!.validate()) {
            // If the form is valid, proceed with uploading the data
            await uploadBookToDatabase(
              _bookTitleController.text,
              _authorNameController.text,
              _bookSummaryController.text,
                megaResult['imageUrl']!,
                megaResult['pdfUrl']!
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
