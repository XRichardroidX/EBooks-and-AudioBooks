import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:file_picker/file_picker.dart';

Future<Map<String, dynamic>> epubToTextFromFile(PlatformFile file) async {
  try {
    // Use the bytes from the PlatformFile
    final epubBytes = file.bytes;

    if (epubBytes == null) {
      throw Exception('File bytes are null');
    }

    final archive = ZipDecoder().decodeBytes(epubBytes);
    Map<String, dynamic> bookInfo = {
      'title': '',
      'authors': [],
      'tableOfContents': [],
      'body': '',
    };

    bool contentFound = false;
    List<String> contentFilesOrder = [];

    for (final archiveFile in archive) {
      if (archiveFile.isFile) {
        try {
          // Check if the file is a text-based file before decoding
          String content;
          if (archiveFile.name.endsWith('content.opf') ||
              archiveFile.name.endsWith('.xhtml') ||
              archiveFile.name.endsWith('.html') ||
              archiveFile.name.endsWith('toc.ncx')) {
            content = utf8.decode(archiveFile.content);
          } else {
            // Skip non-text files
            continue;
          }

          if (archiveFile.name.endsWith('content.opf')) {
            // Extract metadata including title, authors, and manifest order
            final document = html_parser.parse(content);
            bookInfo['title'] = document.querySelector('dc\\:title')?.text ?? 'Unknown Title';
            final authors = document.querySelectorAll('dc\\:creator');
            bookInfo['authors'] = authors.map((author) => author.text).toList();

            // Extract the manifest to get the reading order of the files
            final manifestItems = document.querySelectorAll('item');
            for (var item in manifestItems) {
              final href = item.attributes['href'];
              if (href != null && (href.endsWith('.xhtml') || href.endsWith('.html'))) {
                contentFilesOrder.add(href);
              }
            }
          } else if (archiveFile.name.endsWith('toc.ncx')) {
            // Extract the Table of Contents
            final document = html_parser.parse(content);
            final navMap = document.querySelector('navMap');
            if (navMap != null) {
              final navPoints = navMap.querySelectorAll('navPoint');
              for (var navPoint in navPoints) {
                final label = navPoint.querySelector('navLabel')?.text ?? 'No Title';
                bookInfo['tableOfContents'].add(label);
              }
            }
          }
        } catch (e) {
          print('Error decoding file ${archiveFile.name}: $e');
        }
      }
    }

    // Now that we have the order of the files, process them in that order
    for (String contentFileName in contentFilesOrder) {
      for (final archiveFile in archive) {
        if (archiveFile.isFile && archiveFile.name.endsWith(contentFileName)) {
          try {
            final content = utf8.decode(archiveFile.content);
            final document = html_parser.parse(content);
            final text = document.body?.text ?? '';
            if (text.isNotEmpty) {
              contentFound = true;
              // Append the text without modifying the spacing or tabs
              bookInfo['body'] += text + '\n\n';
            }
          } catch (e) {
            print('Error processing file ${archiveFile.name}: $e');
          }
        }
      }
    }

    if (!contentFound) {
      bookInfo['body'] = 'No content found in the EPUB.';
    }

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