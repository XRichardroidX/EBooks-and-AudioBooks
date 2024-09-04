import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

Future<Map<String, String>> uploadEBookToPCloud(
    BuildContext context, Uint8List imageBytes, File pdfFile) async {

  const baseUrl = 'https://api.pcloud.com';
  const username = 'premium4oxide@gmail.com';
  const password = '@GwuCRhEY7a87RB';

  // Step 1: Login to pCloud
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/login'),
    body: {
      'getauth': '1', // This tells the API to return an auth token
      'username': username,
      'password': password,
    },
  );

  if (loginResponse.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login error: ${loginResponse.body}'),
      ),
    );
    print('Login error: ${loginResponse.body}');
    return {};
  }

  final loginJson = jsonDecode(loginResponse.body);
  if (loginJson['result'] != 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Authentication failed: ${loginResponse.body}'),
      ),
    );
    print('Authentication failed: ${loginResponse.body}');
    return {};
  }

  final authToken = loginJson['auth'];

  // Step 2: Create a folder named "EBooks"
  final createFolderResponse = await http.get(
    Uri.parse('$baseUrl/createfolderifnotexists?auth=$authToken&name=EBooks&folderid=0'),
  );

  if (createFolderResponse.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Folder creation error: ${createFolderResponse.body}'),
      ),
    );
    print('Folder creation error: ${createFolderResponse.body}');
    return {};
  }

  final createFolderJson = jsonDecode(createFolderResponse.body);
  if (createFolderJson['result'] != 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Folder creation failed: ${createFolderResponse.body}'),
      ),
    );
    print('Folder creation failed: ${createFolderResponse.body}');
    return {};
  }

  final folderId = createFolderJson['metadata']['folderid'];

  // Step 3: Upload image to the folder
  final imageUploadRequest = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/uploadfile?auth=$authToken&folderid=$folderId'),
  );
  imageUploadRequest.files.add(http.MultipartFile.fromBytes(
    'file',
    imageBytes,
    filename: 'image.jpg',
  ));

  final imageUploadResponse = await http.Response.fromStream(await imageUploadRequest.send());

  if (imageUploadResponse.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image upload error: ${imageUploadResponse.body}'),
      ),
    );
    print('Image upload error: ${imageUploadResponse.body}');
    return {};
  }

  final imageJson = jsonDecode(imageUploadResponse.body);
  if (imageJson['result'] != 0 || imageJson['metadata'] == null || imageJson['metadata'].isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image upload failed: ${imageUploadResponse.body}'),
      ),
    );
    print('Image upload failed: ${imageUploadResponse.body}');
    return {};
  }

  final imageDownloadUrl = '$baseUrl/getfilelink?auth=$authToken&fileid=${imageJson['metadata'][0]['fileid']}';

  // Step 4: Upload PDF to the folder
  final pdfUploadRequest = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/uploadfile?auth=$authToken&folderid=$folderId'),
  );
  pdfUploadRequest.files.add(await http.MultipartFile.fromPath(
    'file',
    pdfFile.path,
    filename: pdfFile.path.split('/').last,
  ));

  final pdfUploadResponse = await http.Response.fromStream(await pdfUploadRequest.send());

  if (pdfUploadResponse.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF upload error: ${pdfUploadResponse.body}'),
      ),
    );
    print('PDF upload error: ${pdfUploadResponse.body}');
    return {};
  }

  final pdfJson = jsonDecode(pdfUploadResponse.body);
  if (pdfJson['result'] != 0 || pdfJson['metadata'] == null || pdfJson['metadata'].isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF upload failed: ${pdfUploadResponse.body}'),
      ),
    );
    print('PDF upload failed: ${pdfUploadResponse.body}');
    return {};
  }

  final pdfDownloadUrl = '$baseUrl/getfilelink?auth=$authToken&fileid=${pdfJson['metadata'][0]['fileid']}';

  return {
    'imageUrl': imageDownloadUrl,
    'pdfUrl': pdfDownloadUrl,
  };
}
