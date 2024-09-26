import 'package:appwrite/models.dart';
import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_write_constants.dart';
import '../../new_app/front_end/upload_e_books_page.dart';
import 'epub_reader_page.dart';
import 'dart:convert';

class EBooksPage extends StatefulWidget {
  const EBooksPage({super.key});

  @override
  State<EBooksPage> createState() => _EBooksPageState();
}

class _EBooksPageState extends State<EBooksPage> {
  final Client client = Client();
  late Databases databases;

  Map<String, List<Map<String, dynamic>>> categorizedBooks = {
    'Romance': [],
    'Adventure': [],
    'Mystery': [],
    'Thriller': [],
    'Science Fiction': [],
    'Fantasy': [],
  };

  List<Map<String, dynamic>> filteredBooks = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    client
        .setEndpoint(Constants.endpoint)
        .setProject(Constants.projectId);

    databases = Databases(client);

    loadBooksFromPreferences(); // Load books from preferences first
    checkForNewBooks(); // Then check for new books
  }

  Future<void> checkForNewBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt('lastFetchTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Fetch books if 24 hours have passed since last fetch
    if (currentTime - lastFetchTime > Duration.secondsPerMinute) {
      await fetchBooks();
      await prefs.setInt('lastFetchTime', currentTime);
    }
  }

  Future<void> fetchBooks() async {
    try {
      int limit = 100; // Adjust the limit as needed
      int offset = 0;
      List<Document> allDocuments = [];

      while (true) {
        final response = await databases.listDocuments(
          databaseId: Constants.databaseId,
          collectionId: Constants.ebooksCollectionId,
          queries: [
            Query.limit(limit),
            Query.offset(offset),
          ],
        );

        allDocuments.addAll(response.documents);

        if (response.documents.length < limit) {
          break; // Exit loop if the last batch is smaller than the limit
        }

        offset += limit;
      }

      if (!mounted) return;

      setState(() {
        categorizedBooks.forEach((key, value) {
          value.clear(); // Clear old data
        });

        for (var doc in allDocuments) {
          var bookCategory = doc.data['bookCategory'] ?? 'Unknown';
          var bookData = {
            'authorNames': doc.data['authorNames'],
            'bookTitle': doc.data['bookTitle'],
            'bookCoverUrl': doc.data['bookCoverUrl'],
            'bookBody': doc.data['bookBody'],
            'bookSummary': doc.data['bookSummary'],
          };
          if (categorizedBooks.containsKey(bookCategory)) {
            categorizedBooks[bookCategory]?.add(bookData);
          }
        }
        filteredBooks = categorizedBooks.values.expand((x) => x).toList(); // Initialize filteredBooks
        saveBooksToPreferences(); // Save fetched books to preferences
        isLoading = false; // Finished loading
      });
    } catch (e) {
      print('Error fetching books: $e');
      if (!mounted) return;

      setState(() {
        isLoading = false; // Finished loading even if there was an error
      });
    }
  }


  Future<void> saveBooksToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonBooks = json.encode(categorizedBooks);
    await prefs.setString('categorizedBooks', jsonBooks);
  }

  Future<void> loadBooksFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonBooks = prefs.getString('categorizedBooks');

    if (jsonBooks != null) {
      final decoded = json.decode(jsonBooks) as Map<String, dynamic>;
      setState(() {
        categorizedBooks = decoded.map((key, value) {
          return MapEntry(key, List<Map<String, dynamic>>.from(value));
        });
        filteredBooks = categorizedBooks.values.expand((x) => x).toList(); // Initialize filteredBooks
        isLoading = false; // Set loading to false as books are loaded
      });
    } else {
      setState(() {
        isLoading = false; // Set loading to false if no books found
      });
    }
  }

  // Helper function to truncate text
  String truncateText(String text) {
    if (text.length <= 20) {
      return text;
    } else {
      return text.substring(0, 17) + '...'; // Add ellipses
    }
  }

  // Function to filter books based on search query
  void filterBooks(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredBooks = categorizedBooks.values
          .expand((x) => x)
          .where((book) {
        final title = book['bookTitle']?.toLowerCase() ?? '';
        final authors = (book['authorNames'] as List<dynamic>)
            .map((e) => e.toLowerCase())
            .join(',');

        return title.contains(searchQuery) || authors.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Text(
          'E-Books',
          style: TextStyle(color: AppColors.textHighlight),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: filterBooks,
                decoration: InputDecoration(
                  hintText: 'Search by title or author',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            // Check if filteredBooks is empty
            if (searchQuery.isNotEmpty && filteredBooks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "This book is not available right now, you can request for it now.",
                  style: TextStyle(fontSize: 18, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            // Display categorized books
            ...categorizedBooks.entries.map((entry) {
              final booksToDisplay = entry.value.where((book) {
                final title = book['bookTitle']?.toLowerCase() ?? '';
                final authors = (book['authorNames'] as List<dynamic>)
                    .map((e) => e.toLowerCase())
                    .join(',');

                return title.contains(searchQuery) || authors.contains(searchQuery);
              }).toList();

              return booksToDisplay.isNotEmpty
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 260, // Adjust height as needed
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 1,
                        childAspectRatio: 1.8, // Adjust ratio for card size
                      ),
                      itemCount: booksToDisplay.length,
                      itemBuilder: (context, index) {
                        final book = booksToDisplay[index];
                        return InkWell(
                          onTap: () {
                            final bookContent = book['bookBody'];
                            if (bookContent != null) {
                              context.push(
                                '/ebookdetails/${Uri.encodeComponent(book['bookTitle'] ?? 'Unknown Title')}/${Uri.encodeComponent((book['authorNames'] as List<dynamic>).join(', ') ?? 'Unknown Author')}/${Uri.encodeComponent(book['bookCoverUrl'] ?? '')}/${Uri.encodeComponent(book['bookSummary'] ?? '')}',
                                extra: bookContent,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Not available')),
                              );
                            }
                          },
                          child: Card(
                            color: Colors.white,
                            margin: const EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (book['bookCoverUrl'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        book['bookCoverUrl'],
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 180,
                                            width: double.infinity,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${truncateText(book['bookTitle'])} \n Book Cover \n No Internet',
                                              style: TextStyle(color: Colors.black54, fontSize: 16),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Text(
                                    truncateText(book['bookTitle'] ?? 'Unknown Title'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'By: ${truncateText((book['authorNames'] as List<dynamic>).join(', ') ?? 'Unknown Author')}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
                  : Container(); // If no books in this category match the search, display nothing
            }).toList(),
          ],
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
          color: AppColors.buttonPrimary,
        ),
      ),
    );
  }
}
