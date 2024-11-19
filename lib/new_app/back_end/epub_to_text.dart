import 'dart:io';
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
      'title': '',
      'authors': [],
      'tableOfContents': [],
      'body': '',
    };

    List<String> contentFilesOrder = [];

    // Process the archive to extract metadata and determine file order
    for (final archiveFile in archive) {
      if (archiveFile.isFile) {
        try {
          if (archiveFile.name.endsWith('content.opf')) {
            final content = utf8.decode(archiveFile.content);
            final document = html_parser.parse(content);

            // Extract title and authors
            bookInfo['title'] = document.querySelector('dc\\:title')?.text ?? 'Unknown Title';
            final authors = document.querySelectorAll('dc\\:creator');
            bookInfo['authors'] = authors.map((author) => author.text).toList();

            // Extract reading order
            final spineItems = document.querySelectorAll('spine > itemref');
            final manifestItems = document.querySelectorAll('manifest > item');
            final hrefMap = {
              for (var item in manifestItems)
                item.attributes['id']: item.attributes['href']
            };

            for (var spineItem in spineItems) {
              final idRef = spineItem.attributes['idref'];
              if (idRef != null && hrefMap.containsKey(idRef)) {
                contentFilesOrder.add(hrefMap[idRef]!);
              }
            }
          }
        } catch (e) {
          print('Error decoding metadata: $e');
        }
      }
    }

    // Process the files in the specified order
    for (String contentFileName in contentFilesOrder) {
      final matchingFile = archive.firstWhere(
            (archiveFile) =>
        archiveFile.isFile && archiveFile.name.contains(contentFileName),
        orElse: () => throw Exception('File not found: $contentFileName'),
      );

      if (matchingFile != null) {
        try {
          final content = utf8.decode(matchingFile.content);
          final document = html_parser.parse(content);
          final text = document.body?.text ?? '';
          if (text.isNotEmpty) {
            bookInfo['body'] += text + '\n\n';
          }
        } catch (e) {
          print('Error processing file $contentFileName: $e');
        }
      }
    }

    if (bookInfo['body'].isEmpty) {
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
