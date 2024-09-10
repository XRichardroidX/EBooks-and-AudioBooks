import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_write_constants.dart';

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
        .setEndpoint(Constants.endpoint) // Your Appwrite Endpoint
        .setProject(Constants.projectId); // Your Appwrite project ID

    // Upload ePub file to the "EBooks" bucket
    final epubUploadResponse = await storage.createFile(
      bucketId: Constants.cloudStorageBookId,  // "EBooks" bucket ID
      fileId: 'unique()',   // Generate a unique ID for the file
      file: InputFile.fromBytes(bytes: epubFile.bytes!, filename: epubFile.name),
      permissions: [
        Permission.read(Role.any()), // Public read
        Permission.write(Role.any()), // Public write
      ],
    );

    // Upload image to the "BookCover" bucket
    final imageUploadResponse = await storage.createFile(
      bucketId: Constants.cloudStorageBookCoverId,  // "BookCover" bucket ID
      fileId: 'unique()',      // Generate a unique ID for the file
      file: InputFile.fromBytes(bytes: imageBytes, filename: 'imageName.jpg'),  // Change image name as needed
      permissions: [
        Permission.read(Role.any()), // Public read
        Permission.write(Role.any()), // Public write
      ],
    );

    // Calculate the total file size
    int totalFileSize = epubFile.size + imageBytes.lengthInBytes;

    // Extract number of pages from the ePub file
    EpubBook epubBook = await EpubReader.readBook(epubFile.bytes!);
    int numberOfPages = epubBook.Chapters?.length ?? 0;

    // Generate URLs for the uploaded files
    String epubUrl = '${Constants.endpoint}/storage/buckets/${Constants.cloudStorageBookId}/files/${epubUploadResponse.$id}/view?project=${Constants.projectId}';
    String imageUrl = '${Constants.endpoint}/storage/buckets/${Constants.cloudStorageBookCoverId}/files/${imageUploadResponse.$id}/view?project=${Constants.projectId}';
    Navigator.pop(context);
    // Return the required information as a map
    return {
      'bookCoverUrl': imageUrl,
      'bookUrl': epubUrl,
      'numberOfPages': '${numberOfPages}',
      'totalFileSize': '${totalFileSize}',
    };
  } catch (e) {
    print('Error: $e');
    throw Exception('Failed to upload book and cover: $e');
  }
}
