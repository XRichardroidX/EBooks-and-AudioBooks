import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class EpubReaderPage extends StatefulWidget {
  final String epubUrl;

  const EpubReaderPage({Key? key, required this.epubUrl}) : super(key: key);

  @override
  _EpubReaderPageState createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late EpubController _epubController;
  late String _lastReadPageKey;
  int _lastReadPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _lastReadPageKey = widget.epubUrl;
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      // Fetch the EPUB file from the URL
      final response = await http.get(Uri.parse(widget.epubUrl));

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        // Get the last read page from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        _lastReadPage = prefs.getInt(_lastReadPageKey) ?? 0;

        // Initialize the EpubController with the downloaded bytes
        _epubController = EpubController(
          document: EpubDocument.openData(bytes),
        );

        // Listen for document loaded
        _epubController.document.then((_) {
          setState(() {
            _isLoading = false;
          });

          // Wait for 5 seconds before jumping to the last read page
          Future.delayed(Duration(seconds: 2), () {
            if (_lastReadPage > 0) {
              // Ensure that the document is loaded and that _lastReadPage is within bounds
              _epubController.jumpTo(index: _lastReadPage);
            }
          });
        }).catchError((error) {
          setState(() {
            _isLoading = false;
          });
          print('Error loading EPUB document: $error');
        });
      } else {
        // Handle error when fetching EPUB file
        setState(() {
          _isLoading = false;
        });
        print('Failed to load EPUB: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching EPUB file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('E-Book Reader'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : EpubView(
        controller: _epubController,
        onChapterChanged: (chapterViewValue) {
          if (chapterViewValue != null) {
            final currentPage = chapterViewValue.position;
            // Save the current page index
            _saveLastReadPage(currentPage.index);
          }
        },
      ),
    );
  }

  void _saveLastReadPage(int currentPage) async {
    // Save the current page to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadPageKey, currentPage);
  }
}
