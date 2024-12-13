import 'dart:async'; // For Timer
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/appwrite.dart'; // Appwrite SDK
import 'package:idb_shim/idb_browser.dart';
import '../../constants/app_write_constants.dart';
import '../../style/colors.dart';
import 'book_details_page.dart';

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
  late Database db;
  int offset = 0;
  bool hasMoreBooks = true;
  bool isFetchingMore = false;

  // Timer for periodic fetch
  Timer? fetchTimer;

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

  final int bookFetchLimit = 9999;
  final int booksPerFetch = 5;
  final int categoryDisplayLimit = 5000;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '123456789';
    initializeAppwrite();
    openDatabase();
    fetchBooks();
    fetchTimer = Timer.periodic(const Duration(seconds: 3), (_) => fetchBooks());
  }

  @override
  void dispose() {
    fetchTimer?.cancel();
    super.dispose();
  }

  Future<void> openDatabase() async {
    db = await idbFactoryBrowser.open('ebooks_db', version: 1, onUpgradeNeeded: (event) {
      final db = event.database;
      db.createObjectStore('books', keyPath: 'bookId');
    });
    await loadCachedBooks();
  }

  Future<void> loadCachedBooks() async {
    final txn = db.transaction('books', 'readonly');
    final store = txn.objectStore('books');
    final cachedBooks = await store.getAll();

    setState(() {
      originalBooks.clear();
      originalBooks.addAll(List<Map<String, dynamic>>.from(cachedBooks));
      filteredBooks = applyFilter(searchQuery);
      categorizeBooks();
      isInitialLoading = false;
    });
  }

  Future<void> cacheBooks(List<Map<String, dynamic>> books) async {
    final txn = db.transaction('books', 'readwrite');
    final store = txn.objectStore('books');

    for (var book in books) {
      await store.put(book);
    }
  }

  void initializeAppwrite() {
    client
        .setEndpoint(Constants.endpoint)
        .setProject(Constants.projectId);
    databases = Databases(client);
    print('Appwrite Client Initialized');
  }

  Future<void> fetchBooks() async {
    if (!hasMoreBooks || isFetchingMore) return;

    setState(() {
      isFetchingMore = true;
    });

    try {
      final result = await databases.listDocuments(
        databaseId: Constants.databaseId,
        collectionId: Constants.ebooksCollectionId,
        queries: [
          Query.limit(booksPerFetch),
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
        cacheBooks(originalBooks);
        filteredBooks = applyFilter(searchQuery);
        categorizeBooks();
        offset += fetchedBooks.length;
        hasMoreBooks = fetchedBooks.length == booksPerFetch;
      });
    } catch (e) {
      print('Error fetching books: \$e');
    } finally {
      setState(() {
        isFetchingMore = false;
      });
    }
  }

  void categorizeBooks() {
    for (var category in categorizedBooks.keys) {
      categorizedBooks[category]?.clear();
    }

    for (var book in originalBooks) {
      for (var category in book['bookCategories']) {
        if (categorizedBooks.containsKey(category)) {
          if (!categorizedBooks[category]!.any((existingBook) => existingBook['bookId'] == book['bookId'])) {
            categorizedBooks[category]?.add(book);
          }
        }
      }
    }

    categorizedBooks.forEach((key, value) {
      value.shuffle(Random());
      if (value.length > categoryDisplayLimit) {
        categorizedBooks[key] = value.sublist(0, categoryDisplayLimit);
      }
    });
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
      backgroundColor: AppColors.backgroundPrimary,
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
                      "Loading Books...",
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
                                            errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.error, color: Colors.red),
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
