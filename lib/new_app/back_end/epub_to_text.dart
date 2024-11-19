import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:file_picker/file_picker.dart';

Future<Map<String, dynamic>> epubToTextFromFile(PlatformFile file) async {
  try {
    final epubBytes = file.bytes;

    if (epubBytes == null) {
      throw Exception('File bytes are null');
    }

    final archive = ZipDecoder().decodeBytes(epubBytes);
    Map<String, dynamic> bookInfo = {
      'title': 'Unknown Title',
      'authors': [],
      'tableOfContents': [],
      'body': '',
    };

    List<Map<String, String>> chapters = []; // To store chapter files and content

    print('Archive files: ${archive.map((file) => file.name).toList()}');

    // Pass 1: Extract metadata (title, authors)
    for (final archiveFile in archive) {
      if (archiveFile.isFile && archiveFile.name.endsWith('content.opf')) {
        final content = utf8.decode(archiveFile.content);
        final document = html_parser.parse(content);

        // Extract title
        bookInfo['title'] = document.querySelector('dc\\:title')?.text ?? 'Unknown Title';
        print('Title: ${bookInfo['title']}');

        // Extract authors
        final authors = document.querySelectorAll('dc\\:creator');
        bookInfo['authors'] = authors.map((author) => author.text).toList();
        print('Authors: ${bookInfo['authors']}');
      }
    }

    // Pass 2: Identify chapter files
    for (final archiveFile in archive) {
      if (archiveFile.isFile &&
          (archiveFile.name.endsWith('.xhtml') || archiveFile.name.endsWith('.html'))) {
        try {
          final content = utf8.decode(archiveFile.content);
          final document = html_parser.parse(content);

          // Check for meaningful content
          final text = document.body?.text?.trim() ?? '';
          if (text.isNotEmpty) {
            chapters.add({
              'fileName': archiveFile.name,
              'content': text,
            });
          }
        } catch (e) {
          print('Error processing file ${archiveFile.name}: $e');
        }
      }
    }

    // Natural sorting of chapters by filename
    chapters.sort((a, b) {
      // Extract numeric parts if filenames contain chapter numbers
      final regex = RegExp(r'\d+');
      final aMatch = regex.firstMatch(a['fileName']!);
      final bMatch = regex.firstMatch(b['fileName']!);

      if (aMatch != null && bMatch != null) {
        // Compare numbers if available
        return int.parse(aMatch.group(0)!).compareTo(int.parse(bMatch.group(0)!));
      } else {
        // Fallback to lexicographical comparison
        return a['fileName']!.compareTo(b['fileName']!);
      }
    });

    print('Sorted Chapters: ${chapters.map((c) => c['fileName']).toList()}');

    // Pass 3: Combine chapters into book body
    for (var chapter in chapters) {
      bookInfo['body'] += chapter['content']! + '\n\n';
      bookInfo['tableOfContents'].add(chapter['fileName']?.replaceAll('.xhtml', '')); // Add chapter names to TOC
    }

    // Final checks
    if (bookInfo['body']!.isEmpty) {
      bookInfo['body'] = 'No readable content found in the EPUB.';
    }
    print('Book Body Length: ${bookInfo['body']!.length}');
    return bookInfo;
  } catch (e) {
    print('Error reading EPUB file: $e');
    return {
      'title': 'Error',
      'authors': [],
      'tableOfContents': [],
      'body': 'Failed to read EPUB file.',
    };
  }
}
