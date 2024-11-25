import 'dart:async'; // For Timer
import 'dart:convert';
import 'package:appwrite/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:appwrite/appwrite.dart'; // Appwrite SDK
import '../constants/app_write_constants.dart';
import '../new_app/front_end/upload_e_books_page.dart';
import '../style/colors.dart';
import '../widget/book.dart';
import 'e_book_pages/book_details_page.dart';
import 'dart:math';

class FilterBooksPage extends StatefulWidget {
  const FilterBooksPage({Key? key}) : super(key: key);

  @override
  State<FilterBooksPage> createState() => _FilterBooksPageState();
}

class _FilterBooksPageState extends State<FilterBooksPage> {
  List<Map<String, dynamic>> originalBooks = [];
  List<Map<String, dynamic>> filteredBooks = [];
  bool isInitialLoading = true;
  String searchQuery = '';
  String userId = '';
  final Client client = Client();
  late Databases databases;
  // Timer for periodic updates
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '123456789';
    initializeAppwrite();
    loadBooksFromPreferences().then((_) {
      shuffleBooks();
      fetchBooks(); // Initial fetch
    });
    // Start periodic updates after initial load
    _updateTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      fetchBooks();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks
    _updateTimer?.cancel();
    super.dispose();
  }

  void initializeAppwrite() {
    // Initialize the Appwrite client with endpoint and project ID from constants
    client
        .setEndpoint(Constants.endpoint) // e.g., 'https://cloud.appwrite.io/v1'
        .setProject(Constants.projectId); // Your project ID

    databases = Databases(client);
    print('Appwrite Client Initialized');
  }

  Future<void> loadBooksFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonBooks = prefs.getString('originalBooks');

    if (jsonBooks != null) {
      final decoded = json.decode(jsonBooks) as List<dynamic>;
      setState(() {
        originalBooks = List<Map<String, dynamic>>.from(decoded);
        filteredBooks = List.from(originalBooks);
        shuffleBooks();
        isInitialLoading = false; // Set loading state to false
      });
      print('Loaded ${originalBooks.length} books from SharedPreferences');
    } else {
      setState(() {
        isInitialLoading = false; // No cached books
      });
      print('No books found in SharedPreferences');
    }
  }

  Future<void> fetchBooks() async {
    try {
      print('Fetching books from database...');
      // Fetch documents from the Appwrite database
      final result = await databases.listDocuments(
        databaseId: Constants.databaseId,
        collectionId: Constants.ebooksCollectionId,
        queries: [
          Query.limit(1000), // Adjust the limit as needed
          // Add more queries if necessary
        ],
      );

      List<Map<String, dynamic>> booksFromDatabase = result.documents.map((doc) {
        return {
          'bookTitle': doc.data['bookTitle'] ?? '',
          'authorNames': doc.data['authorNames'] ?? '',
          'bookCoverUrl': doc.data['bookCoverUrl'] ?? '',
          'bookId': doc.$id,
          'bookSummary': doc.data['bookSummary'] ?? '',
          'bookCategories': doc.data['bookCategories'] ?? '',
        };
      }).toList();

      print('Fetched ${booksFromDatabase.length} books from database');

      // Compare with existing books to see if there are changes
      bool isDataDifferent = false;

      if (booksFromDatabase.length != originalBooks.length) {
        isDataDifferent = true;
        print('Book count changed: ${originalBooks.length} -> ${booksFromDatabase.length}');
      } else {
        for (int i = 0; i < booksFromDatabase.length; i++) {
          if (booksFromDatabase[i] != originalBooks[i]) {
            isDataDifferent = true;
            print('Book data changed at index $i');
            break;
          }
        }
      }

      if (isDataDifferent) {
        print('New data detected, updating books');

        // Shuffle the fetched books
        booksFromDatabase.shuffle(Random());

        // Save to SharedPreferences
        await saveBooksToPreferences(booksFromDatabase);

        // Update local state
        setState(() {
          originalBooks = booksFromDatabase;
          filteredBooks = applyFilter(searchQuery);
        });
      } else {
        print('No new data to update');
      }
    } catch (e) {
      // Handle any error that may occur
      print("Error fetching books from database: $e");
    }
  }

  Future<void> saveBooksToPreferences(List<Map<String, dynamic>> books) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String updatedJsonBooks = json.encode(books);
    await prefs.setString('originalBooks', updatedJsonBooks);
    print('Saved ${books.length} books to SharedPreferences');
  }

  List<Map<String, dynamic>> applyFilter(String query) {
    query = query.trim();
    if (query.isEmpty) {
      return List.from(originalBooks);
    } else {
      final lowerQuery = query.toLowerCase();
      return originalBooks.where((book) {
        final title = book['bookTitle']?.toLowerCase() ?? '';
        final authors = (book['authorNames'] as String?)?.toLowerCase() ?? '';
        return title.contains(lowerQuery) || authors.contains(lowerQuery);
      }).toList();
    }
  }

  void shuffleBooks() {
    setState(() {
      originalBooks.shuffle(Random());
      filteredBooks = applyFilter(searchQuery);
    });
    print('Books shuffled');
  }

  void filterBooks(String query) {
    setState(() {
      searchQuery = query;
      filteredBooks = applyFilter(searchQuery);
    });
    print('Filtered books with query: "$query"');
  }




  void navigateToBookDetails(Map<String, dynamic> book) async {
    // Check if the user is authenticated
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If not logged in, navigate to the login page
      context.push('/login');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BookDetailsPage(
                bookTitle: book['bookTitle'],
                bookAuthor: book['authorNames'],
                bookCover: book['bookCoverUrl'],
                bookSummary: book['bookSummary'],
                bookId: book['bookId'],
              ),
        ),
      );
    }
  }


  // Helper function to truncate text
  String truncateText(String text, int size1, int size2) {
    if (text.length <= size1) {
      return text;
    } else {
      return text.substring(0, size2) + '...'; // Add ellipses
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Search',
          style: TextStyle(color: AppColors.textHighlight),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchBooks, // Allow manual refresh
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (query) => filterBooks(query),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by Title or Author',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ),
              // Loading Indicator or List of Books
              isInitialLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary,))
                  : filteredBooks.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    "",
                    style: TextStyle(
                      fontSize: 16,
                        color: AppColors.textSecondary
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = filteredBooks[index];
                  return GestureDetector(
                    onTap: () => navigateToBookDetails(book),
                    child: Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          children: [
                            CachedNetworkImage(
                              imageUrl: book['bookCoverUrl'],
                              placeholder: (context, url) =>
                              const SizedBox(
                                width: 80,
                                height: 120,
                                child: Center(
                                    child:
                                    CircularProgressIndicator(color: AppColors.buttonPrimary,)),
                              ),
                              errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                              width: 80,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    truncateText(book['bookTitle'], 23, 23),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Author: ${truncateText("${book['authorNames']}", 18, 18)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    "${truncateText("${book['bookCategories'].join(" | ")}", 70, 70)}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
