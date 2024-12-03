import 'dart:async'; // For Timer
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/appwrite.dart'; // Appwrite SDK
import '../../constants/app_write_constants.dart';
import '../../style/colors.dart';
import 'book_details_page.dart';
import 'dart:math';

class EBooksPage extends StatefulWidget {
  const EBooksPage({Key? key}) : super(key: key);

  @override
  State<EBooksPage> createState() => _EBooksPageState();
}

class _EBooksPageState extends State<EBooksPage> {
  final List<Map<String, dynamic>> originalBooks = [];
  List<Map<String, dynamic>> filteredBooks = [];
  bool isInitialLoading = true;
  String searchQuery = '';
  String userId = '';
  final Client client = Client();
  late Databases databases;

  Timer? _updateTimer;
  int offset = 0;
  bool hasMoreBooks = true;
  bool isFetchingMore = false;

  // Categorized books map
  Map<String, List<Map<String, dynamic>>> categorizedBooks = {
    "Nigerian Stories": [],
    "African Tales": [],
    "Nigerian Romance": [],
    'Mystery': [],
    'Romance': [],
    'Thriller': [],
    'Adventure': [],
    'Science Fiction': [],
    'Fantasy': [],
    'Historical Fiction': [],
    'Horror': [],
    'Young Adult (YA)': [],
    'Comedy': [],
    'Masculinity': [],
    'Femininity': [],
    'Dystopian/Post-Apocalyptic': [],
    'Crime': [],
  };

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '123456789';
    initializeAppwrite();
    fetchBooks();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchBooks(isLoadMore: true);
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void initializeAppwrite() {
    client
        .setEndpoint(Constants.endpoint)
        .setProject(Constants.projectId);
    databases = Databases(client);
    print('Appwrite Client Initialized');
  }

  Future<void> fetchBooks({bool isLoadMore = false}) async {
    if (isLoadMore && !hasMoreBooks) return;
    if (isFetchingMore) return;

    setState(() {
      if (isLoadMore) {
        isFetchingMore = true;
      } else {
        isInitialLoading = true;
      }
    });

    try {
      final result = await databases.listDocuments(
        databaseId: Constants.databaseId,
        collectionId: Constants.ebooksCollectionId,
        queries: [
          Query.limit(5),
          Query.offset(offset),
        ],
      );

      final fetchedBooks = result.documents.map((doc) {
        return {
          'bookTitle': doc.data['bookTitle'] ?? '',
          'authorNames': doc.data['authorNames'] ?? '',
          'bookCoverUrl': doc.data['bookCoverUrl'] ?? '',
          'bookId': doc.$id,
          'bookCategories': doc.data['bookCategories'] ?? [],
        };
      }).toList();

      setState(() {
        for (var book in fetchedBooks) {
          if (!originalBooks.any((existing) => existing['bookId'] == book['bookId'])) {
            originalBooks.add(book);
          }
        }
        filteredBooks = applyFilter(searchQuery);
        categorizeBooks();
        offset += fetchedBooks.length;
        hasMoreBooks = fetchedBooks.isNotEmpty;
      });
    } catch (e) {
      print('Error fetching books: $e');
    } finally {
      setState(() {
        isFetchingMore = false;
        isInitialLoading = false;
      });
    }
  }

  void categorizeBooks() {
    // Clear the existing categories
    for (var category in categorizedBooks.keys) {
      categorizedBooks[category]?.clear();
    }

    // Set to keep track of added books
    Set<String> addedBooks = {};

    for (var book in originalBooks) {
      for (var category in book['bookCategories']) {
        if (categorizedBooks.containsKey(category)) {
          // Check if the book has already been added to this category
          if (!addedBooks.contains(book['bookId'])) {
            categorizedBooks[category]?.add(book);
            addedBooks.add(book['bookId']);
          }
        }
      }
    }
  }

  List<Map<String, dynamic>> applyFilter(String query) {
    final lowerQuery = query.toLowerCase();
    return query.isEmpty
        ? List.from(originalBooks)
        : originalBooks.where((book) {
      final title = book['bookTitle']?.toLowerCase() ?? '';
      final authors = (book['authorNames'] as String?)?.toLowerCase() ?? '';
      return title.contains(lowerQuery) || authors.contains(lowerQuery);
    }).toList();
  }

  void shuffleBooks() {
    setState(() {
      originalBooks.shuffle(Random());
      filteredBooks = applyFilter(searchQuery);
      categorizeBooks();
    });
    print('Books shuffled');
  }

  void filterBooks(String query) {
    setState(() {
      searchQuery = query;
      filteredBooks = applyFilter(searchQuery);
      categorizeBooks();
    });
  }

  void navigateToBookDetails(Map<String, dynamic> book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.push('/login');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailsPage(
            bookTitle: book['bookTitle'],
            bookAuthor: book['authorNames'],
            bookCover: book['bookCoverUrl'],
            bookId: book['bookId'],
          ),
        ),
      );
    }
  }

  String truncateText(String text, int size) {
    return text.length <= size ? text : '${text.substring(0, size)}...';
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
        onRefresh: fetchBooks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isInitialLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
              else if (filteredBooks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "No books found.",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
              // Display categorized books in a scrollable format
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categorizedBooks.keys.length,
                  itemBuilder: (context, index) {
                    final category = categorizedBooks.keys.elementAt(index);
                    final booksInCategory = categorizedBooks[category]!;
                    return booksInCategory.isEmpty
                        ? Container()
                        : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: booksInCategory.length,
                              itemBuilder: (context, bookIndex) {
                                final book = booksInCategory[bookIndex];
                                return GestureDetector(
                                  onTap: () => navigateToBookDetails(book),
                                  child: Card(
                                    color: Colors.grey[900],
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Column(
                                        children: [
                                          Image.network(
                                            book['bookCoverUrl'],
                                            width: 100,
                                            height: 150,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            truncateText(book['bookTitle'], 15),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            truncateText(book['authorNames'], 15),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),

                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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
