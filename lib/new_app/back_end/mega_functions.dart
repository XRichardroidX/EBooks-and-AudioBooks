import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

Future<Map<String, String>> uploadEBookToMegaStorage(
    BuildContext context, Uint8List imageBytes, File pdfFile) async {
  // Replace with your Mega API credentials
  const baseUrl = 'https://api.mega.co.nz';
  const email = 'premium4oxide@gmail.com';
  const password = 'F7-QM-4Myz3xx.u';

  // Login to Mega
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/2'),
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (loginResponse.statusCode != 200) {
    // Handle login error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login error: ${loginResponse.body}'),
      ),
    );
    return {};
  }

  // Extract the authentication token
  final authToken = jsonDecode(loginResponse.body)['token'];

  // Create a folder named "EBooks"
  final createFolderResponse = await http.post(
    Uri.parse('$baseUrl'),
    headers: {'Authorization': 'Bearer $authToken'},
    body: jsonEncode({'type': 'folder', 'name': 'EBooks'}),
  );

  if (createFolderResponse.statusCode != 200) {
    // Handle folder creation error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Folder creation error: ${createFolderResponse.body}'),
      ),
    );
    return {};
  }

  final folderId = jsonDecode(createFolderResponse.body)['id'];

  // Upload image to the folder
  final imageUploadResponse = await http.post(
    Uri.parse('$baseUrl'),
    headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/octet-stream',
    },
    body: imageBytes,
  );

  if (imageUploadResponse.statusCode != 200) {
    // Handle image upload error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image upload error: ${imageUploadResponse.body}'),
      ),
    );
    return {};
  }

  final imageId = jsonDecode(imageUploadResponse.body)['id'];
  final imageDownloadUrl = '$baseUrl/f/$imageId';

  // Upload PDF to the folder
  final pdfUploadResponse = await http.post(
    Uri.parse('$baseUrl'),
    headers: {'Authorization': 'Bearer $authToken'},
    body: jsonEncode({'type': 'file', 'name': pdfFile.path, 'parent': folderId}),
  );

  if (pdfUploadResponse.statusCode != 200) {
    // Handle PDF upload error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF upload error: ${pdfUploadResponse.body}'),
      ),
    );
    return {};
  }

  final pdfId = jsonDecode(pdfUploadResponse.body)['id'];
  final pdfDownloadUrl = '$baseUrl/f/$pdfId';

  return {
    'imageUrl': imageDownloadUrl,
    'pdfUrl': pdfDownloadUrl,
  };
}
