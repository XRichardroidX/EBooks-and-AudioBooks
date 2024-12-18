import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_write_constants.dart';
import '../../style/colors.dart';

class BookReader extends StatefulWidget {
  final String bookBody; // This will be the text content of the book
  final String bookTitle;
  final String bookAuthor;

  const BookReader({
    Key? key,
    required this.bookBody,
    required this.bookTitle,
    required this.bookAuthor,
  }) : super(key: key);

  @override
  _BookReaderState createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  bool _isLoading = true;
  bool _isDarkMode = true;
  String _extractedText = '';
  List<String> _words = [];
  int _currentPageIndex = 0;
  double _progress = 0.0;
  String userId = '';
  int numberOfWords = 0;

  bool readMode = false;
  double _fontSize = 18; // Default font size
  int get _wordsPerPage => (numberOfWords / _fontSize).round(); // Adjust words per page based on font size

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _loadPreferences();
    _splitContentIntoWords();

    // Add the delay here before loading the current page
    Future.delayed(Duration(milliseconds: 100), () {
      _loadCurrentPage();
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        readMode = true;
      });
    });

    _scrollController.addListener(() {
      _updateProgress();
    });
  }

  @override
  void dispose() {
    _saveLastReadPosition();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('$userId+isDarkMode') ?? false;
      _fontSize = prefs.getDouble('$userId+fontSize') ?? 18;
      _currentPageIndex = prefs.getInt('$userId+${widget.bookTitle}+pageIndex') ?? 0;
      numberOfWords = prefs.getInt('$userId+${widget.bookTitle}+numberOfWords') ?? 2000;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$userId+isDarkMode', _isDarkMode);
    await prefs.setDouble('$userId+fontSize', _fontSize);
    await prefs.setInt('$userId+${widget.bookTitle}+pageIndex', _currentPageIndex);
    await prefs.setInt('$userId+${widget.bookTitle}+numberOfWords', numberOfWords);
  }

  void _splitContentIntoWords() {
    _words = widget.bookBody.split(RegExp(r'\s+')).map((word) => word.trim()).toList();
    _words.removeWhere((word) => word.isEmpty); // Remove empty words
    setState(() {
      _isLoading = false;
      _loadCurrentPage();
    });
  }

  void _loadCurrentPage() {
    if (_words.isNotEmpty) {
      int start = _currentPageIndex * _wordsPerPage;
      int end = start + _wordsPerPage;
      if (start < _words.length) {
        setState(() {
          _extractedText = _words.sublist(start, end.clamp(start, _words.length)).join(' ');
        });
      }
    }
  }

  void _updateProgress() {
    if (_extractedText.isNotEmpty) {
      final totalWords = _words.length;
      final maxPages = (totalWords / _wordsPerPage).ceil();
      setState(() {
        _progress = (_currentPageIndex + 1) / maxPages;
      });
    }
  }

  void _saveLastReadPosition() async {
    await _savePreferences();
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
        _loadCurrentPage();
        _updateProgress();
      });
    }
  }

  void _nextPage() {
    int maxPages = (_words.length / _wordsPerPage).ceil();
    if (_currentPageIndex < maxPages - 1) {
      setState(() {
        _currentPageIndex++;
        _loadCurrentPage();
        _updateProgress();
      });
    }
  }

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < 20) _fontSize += 1; // Increase font size by 2
      _loadCurrentPage(); // Reload current page after changing font size
      _updateProgress(); // Update progress to reflect new state
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 15) _fontSize -= 1; // Decrease font size but not below 10
      _loadCurrentPage(); // Reload current page after changing font size
      _updateProgress(); // Update progress to reflect new state
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      )
          : ThemeData.light().copyWith(
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: readMode ? AppBar(
          backgroundColor: _isDarkMode ? Color(0xFF171615) : Color(0xFFFAF5EF),
          actions: [
            InkWell(
              onTap: (){
                setState(() {
                  readMode = false;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 18.0),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Color(0xFF494848) : Color(0xFFFAF5EF),
                  borderRadius: BorderRadius.circular(20), // Circular shape
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // Shadow position
                    ),
                  ],
                ),
                padding: EdgeInsets.only(right: 8.0), // Adjust padding to center content
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Make the button size based on content
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Icon(
                          Icons.lock_open,
                          color: _isDarkMode ? AppColors.iconColor : Color(0xFF494848),
                        ),
                    ),
                    Text(
                      'unlock',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDarkMode ? AppColors.iconColor : Color(0xFF494848),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            )
          ],
          toolbarHeight: 38,
        ) : AppBar(
          toolbarHeight: 40,
          backgroundColor: _isDarkMode ? AppColors.backgroundPrimary : AppColors.textPrimary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context); // This will take the user back to the previous screen
            },
          ),
          title: Text(
            widget.bookTitle,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            InkWell(
              onTap: (){
                setState(() {
                  readMode = true;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 18.0),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Color(0xFF494848) : Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20), // Circular shape
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // Shadow position
                    ),
                  ],
                ),
                padding: EdgeInsets.only(right: 10.0), // Adjust padding to center content
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Make the button size based on content
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.remove_red_eye_outlined,
                        color: _isDarkMode ? AppColors.iconColor : AppColors.textHighlight,
                      ),
                    ),
                    Text(
                      'Read Mode',
                      style: TextStyle(
                        fontSize: 15,
                        color: _isDarkMode ? AppColors.iconColor : AppColors.textHighlight,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            ),
            IconButton(
              icon: Icon(_isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
                _savePreferences(); // Save theme preference
              },
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _increaseFontSize,
            ),
            Container(
              child: Text('${_fontSize.ceil()}'),
            ),
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: _decreaseFontSize,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.textHighlight))
            : Container(
              color: _isDarkMode ? Color(0xFF171615) : Color(0xFFFAF5EF),
              padding: _fontSize >= 19 ? EdgeInsets.symmetric(horizontal: 15.0, vertical: 0) : (readMode ? EdgeInsets.fromLTRB(20, 0, 20, 0) : EdgeInsets.fromLTRB(20, 0, 20, 0)),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Center(
                        child: SelectableText(
                          _extractedText,
                          key: _contentKey,
                          style: TextStyle(
                            fontSize: _fontSize,
                            wordSpacing: 2,
                            color: _isDarkMode ? Color(0xFFFFFFFF) : Color(0xFF494848),
                          ),
                          textAlign: TextAlign.center, // Aligns the text to the center
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      !readMode ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          'Progress: ${((_currentPageIndex/(_words.length / _wordsPerPage)) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: 14),
                        ),
                      )
                          :
                      Container(),
                      !readMode ? Text(
                        'Page ${_currentPageIndex + 1} / ${(_words.length / _wordsPerPage).ceil()}',
                        style: TextStyle(fontSize: 14),
                      )
                          :
                      Container(),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        readMode ? Container(
                          decoration: BoxDecoration(
                            color: _isDarkMode ? AppColors.buttonPrimary : Color(0xFF494848), // Button background color
                            borderRadius: BorderRadius.circular(20), // Circular shape
                          ),
                          child: ElevatedButton(
                            onPressed: _previousPage,
                            child: Text('Previous', style: TextStyle(fontSize: 16, color: _isDarkMode ? AppColors.buttonPrimary : Color(0xFF494848),)),
                          ),
                        )
                            :
                        Container(),
                        readMode ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            'Progress: ${((_currentPageIndex/(_words.length / _wordsPerPage)) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: 14),
                          ),
                        )
                            :
                        Container(),
                        readMode ? Container(
                          decoration: BoxDecoration(
                            color: _isDarkMode ? AppColors.buttonPrimary : Color(0xFF494848),
                            borderRadius: BorderRadius.circular(20), // Circular shape
                          ),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            child: Text('Next', style: TextStyle(fontSize: 16, color: _isDarkMode ? AppColors.buttonPrimary : Color(0xFF494848),)),
                          ),
                        )
                            :
                        Container(),
                      ],
                    ),
                  ),
                  !readMode ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Slider(
                      activeColor: AppColors.buttonPrimary,
                      value: _currentPageIndex.toDouble(),
                      min: 0,
                      max: (_words.length / _wordsPerPage).ceil() - 1.0,
                      onChanged: (double newValue) {
                        setState(() {
                          _currentPageIndex = newValue.toInt();
                          _loadCurrentPage();
                          _updateProgress();
                        });
                      },
                    ),
                  )
                      :
                  Container(),
                ],
              ),
            ),
      ),
    );
  }
}