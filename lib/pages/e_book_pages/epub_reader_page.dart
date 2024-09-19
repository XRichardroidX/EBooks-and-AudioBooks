import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

import '../../style/colors.dart';

class EpubReaderPage extends StatefulWidget {
  final String epubUrl;

  const EpubReaderPage({Key? key, required this.epubUrl}) : super(key: key);

  @override
  _EpubReaderPageState createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late String _lastReadPageKey;
  int _lastReadChapterIndex = 0;
  double _lastScrollPosition = 0.0;
  bool _isLoading = true;
  bool _isDarkMode = true;
  String _bookTitle = 'Loading...';
  String _currentChapterTitle = '';
  String _extractedText = '';
  List<String> _chapters = [];
  Map<String, String> _chapterLinks = {};
  int _totalChapters = 0;
  int _currentChapterIndex = 0;
  double _progress = 0.0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _lastReadPageKey = widget.epubUrl;
    _loadThemePreference();
    _loadEpub();
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

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<void> _loadEpub() async {
    try {
      final response = await http.get(Uri.parse(widget.epubUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final prefs = await SharedPreferences.getInstance();
        _lastReadChapterIndex = prefs.getInt('${_lastReadPageKey}_chapterIndex') ?? 0;
        _lastScrollPosition = prefs.getDouble('${_lastReadPageKey}_scrollPosition') ?? 0.0;

        final archive = ZipDecoder().decodeBytes(bytes);
        final contentBuffer = StringBuffer();
        bool contentFound = false;

        for (final file in archive) {
          if (file.isFile) {
            try {
              final content = utf8.decode(file.content);
              if (file.name.endsWith('.xhtml') || file.name.endsWith('.html')) {
                final document = html_parser.parse(content);
                final text = document.body?.text ?? '';
                if (text.isNotEmpty) {
                  contentFound = true;
                  final formattedText = text.replaceAll('\n', '\n\n');
                  contentBuffer.writeln(formattedText);
                }
              } else if (file.name.endsWith('toc.ncx') || file.name.endsWith('content.opf')) {
                _extractTOC(content);
              }
            } catch (e) {
              print('Error decoding file ${file.name}: $e');
            }
          }
        }

        setState(() {
          _bookTitle = contentFound ? 'Loaded EPUB' : 'No Content Found';
          _extractedText = contentBuffer.toString();
          _isLoading = false;

          if (_totalChapters > 0) {
            _currentChapterIndex = _lastReadChapterIndex;
            _currentChapterTitle = _chapters[_currentChapterIndex];
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await Future.delayed(Duration(milliseconds: 500));
              _onChapterSelected(_currentChapterTitle, initialLoad: true);
            });
          }
        });
      } else {
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

  void _extractTOC(String content) {
    final document = html_parser.parse(content);
    final navMap = document.querySelector('navMap');
    if (navMap != null) {
      final navPoints = navMap.querySelectorAll('navPoint');
      _totalChapters = navPoints.length;
      for (var i = 0; i < navPoints.length; i++) {
        final navPoint = navPoints[i];
        final text = navPoint.querySelector('navLabel')?.text ?? 'No Title';
        final contentFile = navPoint.querySelector('content')?.attributes['src'] ?? '';
        _chapters.add(text);
        _chapterLinks[text] = contentFile;
      }
      setState(() {});
    }
  }

  Future<void> _onChapterSelected(String chapterTitle, {bool initialLoad = false}) async {
    final link = _chapterLinks[chapterTitle];
    if (link != null) {
      setState(() {
        _isLoading = true;
        _currentChapterTitle = chapterTitle;
      });

      try {
        final response = await http.get(Uri.parse(widget.epubUrl));
        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;
          final archive = ZipDecoder().decodeBytes(bytes);

          for (var i = 0; i < archive.length; i++) {
            final file = archive[i];
            if (file.isFile && file.name.endsWith(link)) {
              final content = utf8.decode(file.content);
              final document = html_parser.parse(content);
              final text = document.body?.text ?? 'No content';
              setState(() {
                _extractedText = text.replaceAll('\n', '\n\n');
                _isLoading = false;
                _currentChapterIndex = _chapters.indexOf(chapterTitle);
                _updateProgress();
              });

              if (!initialLoad) {
                _saveLastReadPosition();
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(Duration(milliseconds: 500), () {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_lastScrollPosition);
                  }
                });
              });

              break;
            }
          }
        } else {
          print('Failed to load EPUB: ${response.statusCode}');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching chapter content: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateProgress() {
    if (_extractedText.isNotEmpty) {
      final totalHeight = _contentKey.currentContext?.size?.height ?? 1.0;
      final scrollPosition = _scrollController.position.pixels;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;

      if (maxScrollExtent > 0) {
        setState(() {
          _progress = (scrollPosition / maxScrollExtent).clamp(0.0, 1.0);
        });
      }
    }
  }

  void _saveLastReadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_lastReadPageKey}_chapterIndex', _currentChapterIndex);
    await prefs.setDouble('${_lastReadPageKey}_scrollPosition', _scrollController.position.pixels);
  }

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      _currentChapterIndex--;
      _onChapterSelected(_chapters[_currentChapterIndex]);
    }
  }

  void _nextChapter() {
    if (_currentChapterIndex < _totalChapters - 1) {
      _currentChapterIndex++;
      _onChapterSelected(_chapters[_currentChapterIndex]);
    }
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
        appBar: AppBar(
          backgroundColor: _isDarkMode ? AppColors.backgroundPrimary : AppColors.textPrimary,
          title: Container(
            child: Text(
              _totalChapters > 0
                  ? _currentChapterTitle.length > 40
                  ? '${_currentChapterTitle.substring(0, 40)}...'
                  : _currentChapterTitle
                  : _bookTitle.length > 40
                  ? '${_bookTitle.substring(0, 40)}...'
                  : _bookTitle,
              style: TextStyle(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              ),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
                _saveThemePreference(_isDarkMode);
              },
            ),
          ],
        ),
        drawer: Drawer(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.black : AppColors.buttonPrimary,
                ),
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        child: Text(
                          '$_bookTitle',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 50,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        color: _isDarkMode ? Colors.black.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                      ),
                      Center(
                        child: Text(
                          'Table of Contents',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_chapters[index]),
                      onTap: () {
                        _onChapterSelected(_chapters[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.textHighlight,))
            : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                        children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText(
                    _extractedText,
                    key: _contentKey,
                    style: TextStyle(
                      fontSize: 17,
                      color: _isDarkMode ? Colors.white : Colors.black, // Text color based on dark mode
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  'Progress: ${(_progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _previousChapter,
                      child: Text(
                          'Previous',
                        style: TextStyle(color: _isDarkMode ? AppColors.buttonPrimary : AppColors.buttonPrimary, fontSize: 16),

                      ),
                    ),
                    Text(
                      '${_currentChapterIndex + 1}/$_totalChapters chapters',
                      style: TextStyle(fontSize: 15),
                    ),
                    ElevatedButton(
                      onPressed: _nextChapter,
                      child: Text(
                          'Next',
                        style: TextStyle(color: _isDarkMode ? AppColors.buttonPrimary : AppColors.buttonPrimary, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
                        ],
                      ),
            ),
      ),
    );
  }
}