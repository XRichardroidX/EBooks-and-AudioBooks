import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../back_end/database_upload_e_books.dart';
import '../../style/colors.dart';
import '../back_end/epub_to_text.dart';

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
  final TextEditingController _bookTableOfContentController = TextEditingController();
  final TextEditingController _bookBodyController = TextEditingController();

  // Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  // Define dropdown items for book type and category
  String? _selectedType;
  String? _selectedCategory;

  final List<String> _bookTypes = ['Novel', 'Spiritual', 'Self Development'];

  final List<String> _novel = [
    "Mystery",
    "Thriller",
    "Romance",
    "Fantasy",
    "Science Fiction",
    "Historical Fiction",
    "Adventure",
    "Horror",
    "Young Adult (YA)",
    "Dystopian",
    "Magical Realism",
    "Psychological Thriller",
    "Contemporary Fiction",
    "Literary Fiction",
    "Paranormal",
    "Action",
    "Gothic Fiction",
    "Mythology & Retellings",
    "Post-Apocalyptic",
    "Cyberpunk"
  ];

  final List<String> _spiritual = [
    'Christianity',
    'Islam',
    'Hinduism',
    'Buddhism',
    'Judaism',
    'Laws of the Universe'
  ];

  final List<String> _self_development = [
    "Personal Development",
    "Mental Health",
    "Success Mindset",
    "Productivity",
    "Financial Intelligence",
    "Communication Skills",
    "Emotional Intelligence",
    "Creativity and Innovation",
    "Leadership",
    "Entrepreneurship",
    "Spirituality"
  ];

  Uint8List? bookCover;
  PlatformFile? epubBook;

  Future<void> _selectBookCover(BuildContext context, bool fromGallery) async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: fromGallery ? ImageSource.gallery : ImageSource.camera);
    if (image != null) {
      bookCover = await image.readAsBytes();
      setState(() {});
    }
  }



  Future<void> _selectEpub() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      withData: true,  // Fetch the file data (bytes)
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        epubBook = result.files.single;  // Store the file with its bytes
      });

      Map<String, dynamic> epubToText = await epubToTextFromFile(epubBook!);
      String title = epubToText['title'];
      List authors = epubToText['authors'];
      List tableOfContents = epubToText['tableOfContents'];
      String body = epubToText['body'];
      _bookTitleController.text =  title;
      _authorNameController.text = authors.toString();
      _bookTableOfContentController.text = tableOfContents.toString();
      _bookBodyController.text = body;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dividerColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        iconTheme: IconThemeData(color: AppColors.textHighlight),
        title: Text('Upload E-Books',
          style: TextStyle(
              color: AppColors.textHighlight
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.backgroundPrimary,
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Title
                TextFormField(
                  controller: _bookTitleController,
                  style: TextStyle(color: AppColors.textPrimary), // Text color
                  decoration: InputDecoration(
                    labelText: 'Book Title',
                    labelStyle: TextStyle(color: AppColors.textPrimary), // Label text color
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Default border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.buttonPrimary), // Border color when focused
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Border color when enabled
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when there is an error
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when focused and there is an error
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the book title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16.0),

                // Author Name
                TextFormField(
                  controller: _authorNameController,
                  style: TextStyle(color: AppColors.textPrimary), // Text color
                  decoration: InputDecoration(
                    labelText: 'Author Name',
                    labelStyle: TextStyle(color: AppColors.textPrimary), // Label text color
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Default border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.buttonPrimary), // Border color when focused
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Border color when enabled
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when there is an error
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when focused and there is an error
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the author name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Book Summary
                TextFormField(
                  controller: _bookSummaryController,
                  style: TextStyle(color: AppColors.textPrimary), // Text color
                  decoration: InputDecoration(
                    labelText: 'Book Summary',
                    labelStyle: TextStyle(color: AppColors.textPrimary), // Label text color
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Default border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.buttonPrimary), // Border color when focused
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Border color when enabled
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when there is an error
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when focused and there is an error
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a book summary';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                // Book Summary
                TextFormField(
                  controller: _bookTableOfContentController,
                  style: TextStyle(color: AppColors.textPrimary), // Text color
                  decoration: InputDecoration(
                    labelText: 'Book Table ofcontent',
                    labelStyle: TextStyle(color: AppColors.textPrimary), // Label text color
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Default border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.buttonPrimary), // Border color when focused
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Border color when enabled
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when there is an error
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when focused and there is an error
                    ),
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a book summary';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                // Book Summary
                TextFormField(
                  controller: _bookBodyController,
                  style: TextStyle(color: AppColors.textPrimary), // Text color
                  decoration: InputDecoration(
                    labelText: 'Book Body',
                    labelStyle: TextStyle(color: AppColors.textPrimary), // Label text color
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Default border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.buttonPrimary), // Border color when focused
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textPrimary), // Border color when enabled
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when there is an error
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error), // Border color when focused and there is an error
                    ),
                  ),
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a book summary';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Inside your _UploadEBooksPageState class, where the _selectedType is being set
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Book Type',
                    filled: true, // Ensure the background color is applied
                    fillColor: AppColors.backgroundPrimary, // Background color of the input field
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textHighlight),
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary), // Text color inside the field
                  dropdownColor: AppColors.backgroundPrimary, // Background color of the dropdown menu
                  items: _bookTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: TextStyle(color: AppColors.textPrimary), // Text color in the dropdown items
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedType = newValue;
                      _selectedCategory = null; // Reset the category when the type changes
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a book type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                if (_selectedType == 'Novel')
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: '$_selectedType Category',
                      filled: true,
                      fillColor: AppColors.backgroundPrimary,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.textHighlight),
                      ),
                    ),
                    style: TextStyle(color: AppColors.textPrimary),
                    dropdownColor: AppColors.backgroundPrimary,
                    items: _novel.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a book category';
                      }
                      return null;
                    },
                  )
                else if (_selectedType == 'Spiritual')
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: '$_selectedType Category',
                      filled: true,
                      fillColor: AppColors.backgroundPrimary,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.textHighlight),
                      ),
                    ),
                    style: TextStyle(color: AppColors.textPrimary),
                    dropdownColor: AppColors.backgroundPrimary,
                    items: _spiritual.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a book category';
                      }
                      return null;
                    },
                  )
                else if (_selectedType == 'Self Development')
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: '$_selectedType Category',
                        filled: true,
                        fillColor: AppColors.backgroundPrimary,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textHighlight),
                        ),
                      ),
                      style: TextStyle(color: AppColors.textPrimary),
                      dropdownColor: AppColors.backgroundPrimary,
                      items: _self_development.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a book category';
                        }
                        return null;
                      },
                    ),
                const SizedBox(height: 16.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Column(
                        children: [

                          // Image Picker for Book Cover
                          ElevatedButton(
                            onPressed: () {
                              _selectBookCover(context, true);
                            },
                            child: const Text(
                                'Select Book Cover',
                              style: TextStyle(
                                color: AppColors.textHighlight,
                              ),
                            ),
                          ),
                          if (bookCover != null)
                            Image.memory(bookCover!, width: 100, height: 150),
                        ],
                      ),
                    const SizedBox(width: 16.0),
                    Column(
                      children: [
                        // ePub Picker for Book File
                        ElevatedButton(
                          onPressed: _selectEpub,
                          child: const Text(
                              'Select ePub File',
                            style: TextStyle(
                              color: AppColors.textHighlight,
                            ),
                          ),
                        ),
                        if (epubBook != null)
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: Text(
                              '${epubBook!.name} file selected', // Display the extracted file name
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16.0),
                      ],
                    )

                  ],
                ),
                const SizedBox(height: 16.0),
                Center(
                  child:                     // Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Perform the upload action
                        uploadBookToDatabase(
                          context: context,
                          bookTitle: _bookTitleController.text,
                          authorName: _authorNameController.text,
                          bookSummary: _bookSummaryController.text,
                          bookCover: bookCover!,
                          bookFile: epubBook!,
                          bookType: _selectedType!,
                          bookCategory: _selectedCategory!,
                        );
                        // Call your backend function here
                      }
                    },
                    child: const Text(
                        'Upload',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.backgroundPrimary,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
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
