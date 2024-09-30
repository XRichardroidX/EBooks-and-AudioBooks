import 'dart:ffi';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../constants/app_write_constants.dart';
import 'cloud_storage_upload_e_books.dart';
import 'epub_to_text.dart';

// Initialize Appwrite Client and Databases service
Client client = Client();
Databases databases = Databases(client);

Future<void> uploadBookToDatabase({
  required BuildContext context,
  required String bookTitle,
  required String authorName,
  required String bookSummary,
  required Uint8List bookCover,
  required PlatformFile bookFile,
  required String bookType,
  required String bookCategory,
}) async {
  try {
    client
        .setEndpoint(Constants.endpoint) // Your Appwrite endpoint
        .setProject(Constants.projectId); // Your project ID


    Map<String, dynamic> epubToText = await epubToTextFromFile(bookFile);
    String title = epubToText['title'];
    List authors = epubToText['authors'];
    List tableOfContents = epubToText['tableOfContents'];
    String body = epubToText['body'];

    print('-----------------------------title: $title--------------------------');
    print('-----------------------------authors: $authors--------------------------');
    print('-----------------------------tableOfContents: $tableOfContents--------------------------');
    print('-----------------------------body: $body--------------------------');

    Map<String, dynamic> bookStorageUrl = await uploadBookToCloudStorage(
      context: context,
      imageBytes: bookCover,
      epubFile: bookFile,
    );

    String bookCoverUrl = bookStorageUrl['bookCoverUrl'];
  //  String bookUrl = bookStorageUrl['bookUrl'];
    String numberOfPages = bookStorageUrl['numberOfPages'];
    String totalFileSize = bookStorageUrl['totalFileSize'];

    // Make sure the user is authenticated before calling this function

    // Create a new document with the given details
    Document response = await databases.createDocument(
      databaseId: Constants.databaseId, // Replace with your database ID
      collectionId: Constants.ebooksCollectionId, // Replace with your collection ID
      documentId: 'unique()', // 'unique()' generates a unique document ID
      data: {
        'bookTitle': title, // Replace with your schema field name
        'authorNames': authors, // Replace with your schema field name
        'bookSummary': bookSummary, // Replace with your schema field name
        'bookCoverUrl': bookCoverUrl, // Replace with your schema field name
        'bookBody': body, // Replace with your schema field name
        'bookCategory': bookCategory,
        'timeStamp': '${DateTime.now().millisecondsSinceEpoch}', // Replace with your schema field name
        'totalFileSize': totalFileSize,
        'bookType': bookType,
        'bookTableOfContent': tableOfContents
      },
      permissions: [
        Permission.read(Role.any()), // Allow any user to read the document
        Permission.write(Role.any()), // Allow any user to write to the document
      ],
    );

   Navigator.pop(context);

    print('Document created successfully: ${response.data}');
  } catch (e) {
    print('Error creating document: $e');
  }
}
