import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_write_constants.dart';
import '../../image_functions/compress_image.dart';

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


    int quality = 85;
    // Check if the image quality is already below a certain threshold
    if (shouldCompress(imageBytes)) {
      int compressedFileSize = estimateCompressedFileSize(imageBytes);
      while (imageBytes.lengthInBytes > compressedFileSize) {
        // Compress the image
        imageBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: quality, // Adjust the quality (0 to 100)
        );

        quality -= 5;

        if (quality < 5) {
          break;
        }
      }
    }


    // Upload image to the "BookCover" bucket
    final imageUploadResponse = await storage.createFile(
      bucketId: Constants.cloudStorageBookCoverId,  // "BookCover" bucket ID
      fileId: 'unique()',      // Generate a unique ID for the file
      file: InputFile.fromBytes(bytes: imageBytes, filename: 'coverImage.jpg'),  // Change image name as needed
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

    // Generate URL for the uploaded book cover
    String imageUrl = '${Constants.endpoint}/storage/buckets/${Constants.cloudStorageBookCoverId}/files/${imageUploadResponse.$id}/view?project=${Constants.projectId}';

    // Optionally pop the context
    // Navigator.pop(context);
    print('-----------------------------title-----------------------------');
    // Return the required information as a map
    return {
      'bookCoverUrl': imageUrl,
      'numberOfPages': '${numberOfPages}',
      'totalFileSize': '${totalFileSize}',
    };
  } catch (e) {
    print('Error: $e');
    throw Exception('Failed to upload book cover and calculate values: $e');
  }
}
