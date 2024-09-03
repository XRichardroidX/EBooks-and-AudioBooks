// pages/profile_page.dart
import 'package:ebooks_and_audiobooks/pages/upload_e_books_page.dart';
import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../../constants/app_write_constants.dart';

class EBooksPage extends StatefulWidget {
  const EBooksPage({super.key});

  @override
  State<EBooksPage> createState() => _EBooksPageState();
}

class _EBooksPageState extends State<EBooksPage> {
  // Initialize Appwrite Client and Databases service
  final Client client = Client();
  late Databases databases;

  List<Map<String, dynamic>> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    client
        .setEndpoint(AppWriteConstants.endpoint) // Your Appwrite endpoint
        .setProject(AppWriteConstants.projectId); // Your project ID

    databases = Databases(client);

    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      // Fetch documents from Appwrite
      final response = await databases.listDocuments(
        databaseId: AppWriteConstants.databaseId,
        collectionId: '66d7210e001271490533', // Replace with your collection ID
      );

      setState(() {
        books = response.documents
            .map((doc) => {
          'authorName': doc.data['authorName'], // Match with your schema field name
          'bookTitle': doc.data['bookTitle'], // Match with your schema field name
        })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching books: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Text(
          'E-Books',
          style: TextStyle(color: AppColors.textHighlight),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: AppColors.backgroundPrimary,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : books.isEmpty
            ? Center(child: Text("No books found."))
            : ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                books[index]['bookTitle'] ?? '',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                books[index]['authorName'] ?? '',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPrimary,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UploadEBooksPage()));
        },
        child: Icon(
          Icons.upload,
          color: AppColors.textHighlight,
        ),
      ),
    );
  }
}
