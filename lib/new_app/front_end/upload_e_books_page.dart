import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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
  final TextEditingController _bookTitleController = TextEditingController();
  final TextEditingController _authorNameController = TextEditingController();
  final TextEditingController _bookSummaryController = TextEditingController();
  final TextEditingController _bookTableOfContentController = TextEditingController();
  final TextEditingController _bookBodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedType;
  List<String> _selectedCategories = [];
  final List<String> _bookTypes = ['Novel', 'Spiritual', 'Self Development'];
  final List<String> _novel = [
    "Mystery", "Romance", "Thriller", "Science Fiction", "Fantasy",
    "Historical Fiction", "Adventure", "Horror", "Young Adult (YA)",
    "Masculinity", "Femininity", "Dystopian/Post-Apocalyptic",
    "Crime", "Comedy",
  ];
  final List<String> _spiritual = [
    'Christianity', 'Islam', 'Hinduism', 'Buddhism', 'Judaism', 'Laws of the Universe'
  ];
  final List<String> _self_development = [
    "Personal Development", "Mental Health", "Success Mindset",
    "Productivity", "Financial Intelligence", "Communication Skills",
    "Emotional Intelligence", "Creativity and Innovation", "Leadership",
    "Entrepreneurship", "Spirituality"
  ];

  Uint8List? bookCover;
  PlatformFile? epubBook;

  bool _isLoading = false;  // For showing the loading indicator


  List<String> _getCategoriesForSelectedType() {
    switch (_selectedType) {
      case 'Novel':
        return _novel;
      case 'Spiritual':
        return _spiritual;
      case 'Self Development':
        return _self_development;
      default:
        return [];
    }
  }

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
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        epubBook = result.files.single;
      });

      Map<String, dynamic> epubToText = await epubToTextFromFile(epubBook!);
      String title = epubToText['title'];
      List authors = epubToText['authors'];
      List tableOfContents = epubToText['tableOfContents'];
      String body = epubToText['body'];
      _bookTitleController.text = title;
      _authorNameController.text = authors.join(',');
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
        title: Text('Upload E-Books', style: TextStyle(color: AppColors.textHighlight)),
      ),
      body: Stack(
        children: [
          _buildForm(context),  // Form content
          if (_isLoading) _buildLoadingIndicator(),  // Progressive loading indicator
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: AppColors.backgroundPrimary,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_bookTitleController, 'Book Title'),
              const SizedBox(height: 16.0),
              _buildTextField(_authorNameController, 'Author Name'),
              const SizedBox(height: 16.0),
              _buildTextField(_bookSummaryController, 'Book Summary', maxLines: 4),
              const SizedBox(height: 16.0),
              _buildDropdownButtonFormField('Book Type', _bookTypes, (newValue) {
                setState(() {
                  _selectedType = newValue;
                  _selectedCategories.clear();
                });
              }),
              const SizedBox(height: 16.0),
              if (_selectedType != null) _buildCategoryDropdown(),
              const SizedBox(height: 16.0),
              _buildBookCoverSelection(context),
              const SizedBox(height: 16.0),
              _buildEpubSelection(),
              const SizedBox(height: 16.0),
              _buildUploadButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: AppColors.textPrimary),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.buttonPrimary)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textPrimary)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $labelText';
        return null;
      },
    );
  }

  Widget _buildDropdownButtonFormField(String labelText, List<String> items, void Function(String?)? onChanged) {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: AppColors.backgroundPrimary,
        border: OutlineInputBorder(),
      ),
      dropdownColor: AppColors.backgroundPrimary,
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item, style: TextStyle(color: AppColors.textPrimary)));
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please select $labelText';
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Categories', style: TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Add Category',
            filled: true,
            fillColor: AppColors.backgroundPrimary,
            border: OutlineInputBorder(),
          ),
          dropdownColor: AppColors.backgroundPrimary,
          items: _getCategoriesForSelectedType().map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category, style: TextStyle(color: AppColors.textPrimary)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              if (newValue != null && !_selectedCategories.contains(newValue)) {
                _selectedCategories.add(newValue);
              }
            });
          },
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _selectedCategories.map((category) {
            return Chip(
              label: Text(category, style: TextStyle(color: AppColors.textPrimary)),
              backgroundColor: AppColors.buttonPrimary,
              deleteIcon: const Icon(Icons.close),
              deleteIconColor: AppColors.backgroundPrimary,
              onDeleted: () {
                setState(() {
                  _selectedCategories.remove(category);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBookCoverSelection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Book Cover', style: TextStyle(color: AppColors.textPrimary)),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(AppColors.buttonPrimary),
              ),
              onPressed: () {
                _selectBookCover(context, true);
              },
              child: const Text(
                  'Select Cover',
                style: TextStyle(
                  color: AppColors.textPrimary
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        if (bookCover != null)
          Container(
            height: 150.0,
            width: 150.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              image: DecorationImage(image: MemoryImage(bookCover!), fit: BoxFit.cover),
            ),
          ),
      ],
    );
  }

  Widget _buildEpubSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('EPUB File', style: TextStyle(color: AppColors.textPrimary)),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(AppColors.buttonPrimary),
              ),
              onPressed: _selectEpub,
              child: const Text(
                  'Select EPUB',
                style: TextStyle(
                    color: AppColors.textPrimary
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        if (epubBook != null)
          Text(
            epubBook!.name,
            style: TextStyle(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return Center(
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(AppColors.buttonPrimary),
        ),
        onPressed: _uploadEBook,
        child: const Text(
            'Upload E-Book',
          style: TextStyle(
              color: AppColors.textPrimary
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withOpacity(0.8),
          dismissible: false,
        ),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Future<void> _uploadEBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Call your upload function here (make sure this is asynchronous)
      await uploadBookToDatabase(
        context: context,
        bookTitle: _bookTitleController.text,
        authorName: _authorNameController.text,
        bookSummary: _bookSummaryController.text,
        bookCover: bookCover!,
        bookFile: epubBook!,
        bookType: _selectedType!,
        bookCategories: _selectedCategories,
      );

      setState(() {
        _isLoading = false;
      });

      // // After the upload, pop the screen
      // if (mounted) {
      //   Navigator.pop(context);
      // }
    }
  }
}
