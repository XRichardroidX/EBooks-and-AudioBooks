import 'package:appwrite/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:novel_world/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../constants/app_write_constants.dart';
import '../../new_app/front_end/upload_e_books_page.dart';
import '../../widget/book.dart';
import '../../widget/cached_images.dart';
import '../unable_to_upload_books_page.dart';
import 'book_details_page.dart';
import 'epub_reader_page.dart';

class EBooksPage extends StatefulWidget {
  const EBooksPage({Key? key}) : super(key: key);

  @override
  State<EBooksPage> createState() => _EBooksPageState();
}

class _EBooksPageState extends State<EBooksPage> {
  final Client client = Client();
  late Databases databases;

  Map<String, List<Map<String, dynamic>>> categorizedBooks = {
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

  List<Map<String, dynamic>> filteredBooks = [];
  bool isInitialLoading = true;
  bool isFetching = false;
  String userId = '';

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '123456789';
    loadBooks();
    client.setEndpoint(Constants.endpoint).setProject(Constants.projectId);
    databases = Databases(client);
    loadBooksFromPreferences().then((_) {
      shuffleBooks();
      checkForNewBooks();
    });
  }

  Future<void> checkForNewBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt('$userId+lastFetchTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime - lastFetchTime > Duration(seconds: 1).inMilliseconds) {
      await fetchBooks();
      await prefs.setInt('$userId+lastFetchTime', currentTime);
    }
  }

  Future<void> fetchBooks() async {
    bool hasCache = categorizedBooks.values.any((list) => list.isNotEmpty);

    if (hasCache) {
      setState(() {
        isFetching = true;
      });
    } else {
      setState(() {
        isInitialLoading = true;
      });
    }

    try {
      int limit = 100;
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
          break;
        }

        offset += limit;
      }

      if (!mounted) return;

      setState(() {
        categorizedBooks.forEach((key, value) {
          value.clear();
        });

        for (var doc in allDocuments) {
          var bookCategories = doc.data['bookCategories'];

          // Ensure bookCategories is a List of strings
          if (bookCategories is String) {
            bookCategories = [bookCategories]; // Convert string to list
          } else if (bookCategories is! List) {
            bookCategories = []; // Ensure it's an array if not
          }

          var bookData = {
            'authorNames': doc.data['authorNames'],
            'bookTitle': doc.data['bookTitle'],
            'bookCoverUrl': doc.data['bookCoverUrl'],
            'bookBody': doc.data['bookBody'],
            'bookSummary': doc.data['bookSummary'],
          };

          // Add the book to all categories it belongs to
          for (var category in bookCategories) {
            category = category.trim();
            if (categorizedBooks.containsKey(category)) {
              categorizedBooks[category]?.add(bookData);
            }
          }
        }

        filteredBooks = categorizedBooks.values.expand((x) => x).toList();
        shuffleBooks();
        saveBooksToPreferences();

        if (hasCache) {
          isFetching = false;
        } else {
          isInitialLoading = false;
        }
      });
    } catch (e) {
      print('Error fetching books: $e');
      if (!mounted) return;

      setState(() {
        if (categorizedBooks.values.any((list) => list.isNotEmpty)) {
          isFetching = false;
        } else {
          isInitialLoading = false;
        }
      });
    }
  }

  void shuffleBooks() {
    setState(() {
      categorizedBooks.forEach((key, value) {
        value.shuffle();
      });
      filteredBooks = categorizedBooks.values.expand((x) => x).toList();
      filteredBooks.shuffle();
    });
  }

  Future<void> saveBooksToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonBooks = json.encode(categorizedBooks);
    await prefs.setString('$userId+categorizedBooks', jsonBooks);
  }

  Future<void> loadBooksFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonBooks = prefs.getString('$userId+categorizedBooks');

    if (jsonBooks != null) {
      final decoded = json.decode(jsonBooks) as Map<String, dynamic>;
      setState(() {
        categorizedBooks = decoded.map((key, value) {
          return MapEntry(key, List<Map<String, dynamic>>.from(value));
        });
        filteredBooks = categorizedBooks.values.expand((x) => x).toList();
        shuffleBooks();
        isInitialLoading = false;
      });
    } else {
      setState(() {
        isInitialLoading = false;
      });
    }
  }

  String truncateText(String text) {
    if (text.length <= 20) {
      return text;
    } else {
      return text.substring(0, 17) + '...';
    }
  }

  List<Book> recentBooks = [];

  Future<void> loadBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentBooksJson = prefs.getStringList('$userId+recentBooks') ?? [];

    List<Book> loadedRecentBooks =
    recentBooksJson.map((bookJson) => Book.fromJson(bookJson)).toList();

    setState(() {
      recentBooks = loadedRecentBooks;
    });
  }

  void navigateToBookDetails(Book book) {
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
                bookTitle: book.bookTitle,
                bookAuthor: book.bookAuthor,
                bookCover: book.bookCover,
                bookBody: book.bookBody,
                bookSummary: book.bookSummary,
              ),
        ),
      ).then((_) {
        loadBooks();
      });
    }
  }


  Future<String> _fetchAppVersionFromAppwrite() async {
    try {
      var document = await databases.getDocument(
        databaseId: Constants.databaseId, // Replace with your database ID
        collectionId: Constants.configurationCollectionId, // Replace with your collection ID
        documentId: Constants.configurationDocumentId, // Replace with your document ID
      );
      return document.data['UPLOAD_ACCESS'];
    } catch (e) {
      print('Error fetching version: $e');
      return 'false'; // Default version if fetch fails
    }
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
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Fetch version from Appwrite
                  String latestVersion = await _fetchAppVersionFromAppwrite();

                  // Check if the app version matches 'v1'
                  if (latestVersion == 'true') {
                    // If version matches, navigate to UploadEBooksPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UploadEBooksPage(),
                      ),
                    );
                  } else {
                    // If version doesn't match, navigate to SorryUploadBlockedPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SorryUploadBlockedPage(),
                      ),
                    );
                  }
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  side: MaterialStateProperty.all(
                    BorderSide(color: AppColors.buttonPrimary, width: 2),
                  ),
                ),
                icon: const Icon(
                  Icons.add,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
                label: const Text(
                  'Upload E-Books',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

        body: categorizedBooks.values.any((list) => list.isNotEmpty) ? RefreshIndicator(
        onRefresh: () async {
          await fetchBooks();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Recent Books Section
              if (recentBooks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Continue Reading',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              // Recent Books Horizontal List
              if (recentBooks.isNotEmpty)
                SizedBox(
                  height: 300, // Adjust the height of the horizontal list
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, // Horizontal scrolling
                    itemCount:
                    recentBooks.length > 10 ? 10 : recentBooks.length, // Limit to a maximum of 10 books
                    itemBuilder: (context, index) {
                      final book = recentBooks[index];
                      return GestureDetector(
                        onTap: () => navigateToBookDetails(book),
                        child: Container(
                          width: 160, // Width of each book item
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.cardBackground,
                            border: Border.all(color: AppColors.textPrimary),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: book.bookCover,
                                  imageBuilder: (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  placeholder: (context, url) =>
                                  const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary,)),
                                  errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      truncateText(book.bookTitle),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      truncateText(book.bookAuthor),
                                      style: const TextStyle(
                                        fontSize: 15,
                                          color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Display each category of books
              ...categorizedBooks.entries.map((entry) {
                String category = entry.key;
                List<Map<String, dynamic>> books = entry.value;

                if (books.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 210, // Adjust the height of the horizontal list
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal, // Horizontal scrolling
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            var book = books[index];
                            return GestureDetector(
                              onTap: () async {
                                // Check if the user is authenticated
                                final user = FirebaseAuth.instance.currentUser;

                                if (user == null) {
                                  // If not logged in, navigate to the login page
                                  context.push('/login');
                                } else {
                                  // If logged in, navigate to the book details page
                                  navigateToBookDetails(Book(
                                    bookTitle: book['bookTitle'],
                                    bookAuthor: book['authorNames'],
                                    bookCover: book['bookCoverUrl'],
                                    bookBody: book['bookBody'],
                                    bookSummary: book['bookSummary'],
                                  ));
                                }
                              },
                              child: Container(
                                width: 120, // Width of each book item
                                margin: const EdgeInsets.only(right: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.cardBackground,
                                  border: Border.all(color: AppColors.textPrimary),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: CachedNetworkImage(
                                        imageUrl: book['bookCoverUrl'],
                                        imageBuilder: (context, imageProvider) => Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        placeholder: (context, url) =>
                                        const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary,)),
                                        errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            truncateText(book['bookTitle']),
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            truncateText(book['authorNames']),
                                            style: const TextStyle(color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      )
          :
          Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary,))
    );
  }
}
