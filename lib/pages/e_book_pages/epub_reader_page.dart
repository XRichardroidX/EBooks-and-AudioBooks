import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/services.dart';
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
  final String _lastReadPageKey = 'lastReadPage';
  int _lastReadPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    // Load EPUB file from the assets
    final ByteData bytes = await rootBundle.load(widget.epubUrl);
    final Uint8List list = bytes.buffer.asUint8List();

    // Get the last read page from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _lastReadPage = prefs.getInt(_lastReadPageKey) ?? 0;

    // Initialize the EpubController
    _epubController = EpubController(
      document: EpubDocument.openData(list),
    );

    // Wait until the document is fully loaded
    _epubController.document.then((_) {
      setState(() {
        _isLoading = false;
      });

      // Wait for 5 seconds before jumping to the last read page
      Future.delayed(Duration(seconds: 2), () {
        if (_lastReadPage > 0) {
          _epubController.jumpTo(index: _lastReadPage);
        }
      });
    });
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
