import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<Map<String, dynamic>> pdfTextFromFile(PlatformFile file) async {
  try {
    if (file.path == null) {
      throw Exception('File path is null');
    }

    // Load the PDF document
    final bytes = await File(file.path!).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    // Extract metadata
    final String? title = document.documentInformation.title;
    final String? author = document.documentInformation.author;

    // Extract text
    final String fullText = PdfTextExtractor(document).extractText();

    return {
      'title': title ?? file.name.replaceAll('.pdf', ''), // Use metadata or fallback to file name
      'authors': author != null ? [author] : [], // Wrap in a list
      'tableOfContents': [], // TOC parsing not directly supported
      'body': fullText.trim(),
    };
  } catch (e) {
    print('Error reading PDF file: $e');
    return {
      'title': 'Error',
      'authors': [],
      'tableOfContents': [],
      'body': 'Failed to read PDF file.',
    };
  }
}
