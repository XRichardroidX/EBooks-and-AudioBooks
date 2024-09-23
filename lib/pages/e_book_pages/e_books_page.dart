import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../../../constants/app_write_constants.dart';
import '../../new_app/front_end/upload_e_books_page.dart';
import 'epub_reader_page.dart';

class EBooksPage extends StatefulWidget {
  const EBooksPage({super.key});

  @override
  State<EBooksPage> createState() => _EBooksPageState();
}

class _EBooksPageState extends State<EBooksPage> {
  final Client client = Client();
  late Databases databases;

  List<Map<String, dynamic>> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    client
        .setEndpoint(Constants.endpoint) // Your Appwrite endpoint
        .setProject(Constants.projectId); // Your project ID

    databases = Databases(client);

    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final response = await databases.listDocuments(
        databaseId: Constants.databaseId,
        collectionId: Constants.ebooksCollectionId,
      );

      if (!mounted) return;

      setState(() {
        books = response.documents.map((doc) {
          return {
            'authorNames': doc.data['authorNames'],
            'bookTitle': doc.data['bookTitle'],
            'bookCoverUrl': doc.data['bookCoverUrl'],
            'bookBody': doc.data['bookBody'], // Assuming 'bookBody' holds the text content
            'bookContent': doc.data['bookContent'],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching books: $e');
      if (!mounted) return;

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
            ? const Center(child: CircularProgressIndicator())
            : books.isEmpty
            ? const Center(child: Text("No books found."))
            : ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            return Card(
              color: AppColors.cardBackground,
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (books[index]['bookCoverUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          books[index]['bookCoverUrl'],
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      books[index]['bookTitle'] ?? 'Unknown Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'By: ${(books[index]['authorNames'] as List<dynamic>).join(', ') ?? 'Unknown Author'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () {
                        final bookContent = books[index]['bookBody']; // Use text content directly
                        if (bookContent != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookReader(
                                bookTitle: books[index]['bookTitle'] ?? 'Unknown Title',
                                bookAuthor: (books[index]['authorNames'] as List<dynamic>).join(', ') ?? 'Unknown Author',
                                bookBody: bookContent ?? 'Empty',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Not available')),
                          );
                        }
                      },
                      child: const Text('Read Book'),
                    ),
                  ],
                ),
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
              builder: (context) => const UploadEBooksPage(),
            ),
          );
        },
        child: const Icon(
          Icons.upload,
          color: AppColors.textHighlight,
        ),
      ),
    );
  }
}
