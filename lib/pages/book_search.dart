import 'dart:async';
import 'dart:convert';
import 'package:appwrite/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_write_constants.dart';
import '../style/colors.dart';
import 'e_book_pages/book_details_page.dart';
import 'dart:math';

class FilterBooksPage extends StatefulWidget {
  const FilterBooksPage({Key? key}) : super(key: key);

  @override
  State<FilterBooksPage> createState() => _FilterBooksPageState();
}

class _FilterBooksPageState extends State<FilterBooksPage> {
  final List<Map<String, dynamic>> originalBooks = [];
  List<Map<String, dynamic>> filteredBooks = [];
  String searchQuery = '';
  String userId = '';
  final Client client = Client();
  late Databases databases;

  Timer? _updateTimer;
  int offset = 0;
  bool hasMoreBooks = true;
  bool isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '123456789';
    initializeAppwrite();
    loadBooksFromLocalStorage();
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchBooks(isLoadMore: true);
      shuffleBooks();
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

  Future<void> loadBooksFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedBooks = prefs.getString('cachedBooks');
    if (storedBooks != null) {
      final List<dynamic> bookList = jsonDecode(storedBooks);
      setState(() {
        originalBooks.addAll(bookList.cast<Map<String, dynamic>>());
        filteredBooks = applyFilter(searchQuery);
      });
      print('Books loaded from local storage');
    }
  }

  Future<void> saveBooksToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedBooks', jsonEncode(originalBooks));
    print('Books saved to local storage');
  }

  Future<void> fetchBooks({bool isLoadMore = false}) async {
    if (isLoadMore && !hasMoreBooks) return;
    if (isFetchingMore) return;

    setState(() {
      isFetchingMore = isLoadMore;
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
        offset += fetchedBooks.length;
        hasMoreBooks = fetchedBooks.isNotEmpty;
      });

      await saveBooksToLocalStorage();
    } catch (e) {
      print('Error fetching books: $e');
    } finally {
      setState(() {
        isFetchingMore = false;
      });
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
    });
    print('Books shuffled');
  }

  void filterBooks(String query) {
    setState(() {
      searchQuery = query;
      filteredBooks = applyFilter(searchQuery);
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
      body: RefreshIndicator(
        onRefresh: () => fetchBooks(isLoadMore: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 500
                  ),
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
              ),
              if (filteredBooks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return GestureDetector(
                      onTap: () => navigateToBookDetails(book),
                      child: Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Image.network(
                                book['bookCoverUrl'],
                                width: 80,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error, color: Colors.red),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      truncateText(book['bookTitle'], 23),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Author: ${truncateText(book['authorNames'], 40)}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Category: ${(book['bookCategories'] as List<dynamic>).join(' | ')}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
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
