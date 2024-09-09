import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:epubx/epubx.dart';  // For extracting the number of pages in the epub
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';  // Import PlatformFile

Future<Map<String, dynamic>> uploadBookToCloudStorage({
  required BuildContext context,
  required Uint8List imageBytes,
  required PlatformFile epubFile,
}) async {
  try {
    // Initialize Appwrite storage client
    Client client = Client();
    Storage storage = Storage(client);

    client
        .setEndpoint('YOUR_APPWRITE_ENDPOINT') // Your Appwrite Endpoint
        .setProject('YOUR_PROJECT_ID'); // Your Appwrite project ID

    // Upload ePub file to the "EBooks" bucket
    final epubUploadResponse = await storage.createFile(
      bucketId: 'ebooks',  // Use the existing "EBooks" bucket ID
      fileId: 'unique()',   // Generate a unique ID for the file
      file: InputFile.fromBytes(bytes: epubFile.bytes!, filename: epubFile.name),
    );

    // Upload image to the "BookCover" bucket
    final imageUploadResponse = await storage.createFile(
      bucketId: 'bookcovers',  // Use the existing "BookCover" bucket ID
      fileId: 'unique()',      // Generate a unique ID for the file
      file: InputFile.fromBytes(bytes: imageBytes, filename: 'imageName.jpg'),  // Change image name as needed
    );

    // Calculate the total file size
    int totalFileSize = epubFile.size + imageBytes.lengthInBytes;

    // Extract number of pages from the ePub file
    EpubBook epubBook = await EpubReader.readBook(epubFile.bytes!);
    int numberOfPages = epubBook.Chapters?.length ?? 0;

    // Generate URLs for the uploaded files
    String epubUrl = 'YOUR_APPWRITE_URL/storage/buckets/ebooks/files/${epubUploadResponse.$id}/view';
    String imageUrl = 'YOUR_APPWRITE_URL/storage/buckets/bookcovers/files/${imageUploadResponse.$id}/view';

    // Return the required information as a map
    return {
      'bookCoverUrl': imageUrl,
      'bookUrl': epubUrl,
      'numberOfPages': numberOfPages,
      'totalFileSize': totalFileSize,
    };
  } catch (e) {
    throw Exception('Failed to upload book and cover: $e');
  }
}
