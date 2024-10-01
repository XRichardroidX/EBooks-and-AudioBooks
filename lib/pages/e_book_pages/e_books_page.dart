import 'package:appwrite/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../constants/app_write_constants.dart';
import '../../new_app/front_end/upload_e_books_page.dart';
import '../../widget/book.dart';
import '../../widget/cached_images.dart';
import 'book_details_page.dart';
import 'epub_reader_page.dart';

class EBooksPage extends StatefulWidget {
  const EBooksPage({super.key});

  @override
  State<EBooksPage> createState() => _EBooksPageState();
}

class _EBooksPageState extends State<EBooksPage> {
  final Client client = Client();
  late Databases databases;

  Map<String, List<Map<String, dynamic>>> categorizedBooks = {
    'Mystery': [],
    'Thriller': [],
    'Science Fiction': [],
    'Fantasy': [],
    'Romance': [],
    'Historical Fiction': [],
    'Horror': [],
    'Young Adult (YA)': [],
    'Masculinity': [],
    'Femininity': [],
    'Dystopian/Post-Apocalyptic': [],
    'Crime': [],
    'Adventure': [], // Newly added category
  };

  List<Map<String, dynamic>> filteredBooks = [];
  bool isLoading = true;
  bool isLoadingFilteredBooks = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    //Load Recently Read Books
    loadBooks();
    client
        .setEndpoint(Constants.endpoint)
        .setProject(Constants.projectId);
    databases = Databases(client);
    loadBooksFromPreferences().then((_) {
      shuffleBooks(); // Shuffle when books are loaded
    });
    checkForNewBooks();
  }

  Future<void> checkForNewBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt('lastFetchTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime - lastFetchTime > Duration(days: 1).inMilliseconds) {
      await fetchBooks();
      await prefs.setInt('lastFetchTime', currentTime);
    }
  }

  Future<void> fetchBooks() async {
    setState(() {
      isLoading = true; // Start loading indicator
    });

    try {
      int limit = 1000; // Set to a reasonable number
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
          var bookCategory = doc.data['bookCategory']?.trim() ?? 'Unknown';
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

        filteredBooks = categorizedBooks.values.expand((x) => x).toList();
        shuffleBooks(); // Shuffle the list after fetching

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

  void shuffleBooks() {
    setState(() {
      categorizedBooks.forEach((key, value) {
        value.shuffle(); // Shuffle each category of books
      });
      filteredBooks = categorizedBooks.values.expand((x) => x).toList();
      filteredBooks.shuffle(); // Shuffle filtered books
    });
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

        filteredBooks = categorizedBooks.values.expand((x) => x).toList();
        shuffleBooks(); // Shuffle after loading
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
      isLoadingFilteredBooks = true; // Show loading state for filtered books
    });

    // Introduce a 2-second delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        filteredBooks = categorizedBooks.values
            .expand((x) => x)
            .where((book) {
          final title = book['bookTitle']?.toLowerCase() ?? '';
          final authors = (book['authorNames'] as List<dynamic>)
              .map((e) => e.toLowerCase())
              .join(',');

          return title.contains(searchQuery) || authors.contains(searchQuery);
        }).toList();

        // Shuffle filteredBooks after filtering
        filteredBooks.shuffle(); // Shuffle the list after filtering
        isLoadingFilteredBooks = false; // Hide loading state
      });
    });
  }








  List<Book> recentBooks = [];

  // Load both recentBooks and savedBooks from SharedPreferences
  Future<void> loadBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentBooksJson = prefs.getStringList('recentBooks') ?? [];

    List<Book> loadedRecentBooks =
    recentBooksJson.map((bookJson) => Book.fromJson(bookJson)).toList();

    setState(() {
      recentBooks = loadedRecentBooks;
    });
  }



  // Navigate to BookDetailsPage
  void navigateToBookDetails(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailsPage(
          bookTitle: book.bookTitle,
          bookAuthor: book.bookAuthor,
          bookCover: book.bookCover,
          bookBody: book.bookBody,
          bookSummary: book.bookSummary,
        ),
      ),
    ).then((_) {
      // Reload books when returning to refresh the list
      loadBooks();
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
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const UploadEBooksPage()));
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary))
          : RefreshIndicator(
        onRefresh: () async {
          await fetchBooks();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  height: 180, // Adjust the height of the horizontal list
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, // Horizontal scrolling
                    itemCount: recentBooks.length > 10 ? 10 : recentBooks.length, // Limit to a maximum of 10 books
                    itemBuilder: (context, index) {
                      final book = recentBooks[index];
                      return GestureDetector(
                        onTap: () => navigateToBookDetails(book),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CachedNetworkImage(
                                imageUrl: book.bookCover,
                                cacheManager: CustomCacheManager(),
                                width: 100,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Container(
                                  width: 100,
                                  height: 120,
                                  color: Colors.grey,
                                  child: const Icon(Icons.error),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                truncateText(book.bookTitle),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                truncateText(book.bookAuthor),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
              // Loading indicator for filtered books
              if (isLoadingFilteredBooks)
                const Center(child: CircularProgressIndicator(color: AppColors.buttonPrimary)),
              // Display categorized books
              ...categorizedBooks.entries.map((entry) {
                final booksToDisplay = entry.value.where((book) {
                  final title = book['bookTitle']?.toLowerCase() ?? '';
                  final authors = (book['authorNames'] as List<dynamic>).map((e) => e.toLowerCase()).join(',');
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (book['bookCoverUrl'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: book['bookCoverUrl'],
                                        cacheManager: CustomCacheManager(), // Use custom cache manager
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => Container(
                                          height: 180,
                                          width: double.infinity,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${truncateText(book['bookTitle'])} \n Book Cover \n No Internet',
                                            style: const TextStyle(color: Colors.black54, fontSize: 16),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
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
                          );
                        },
                      ),
                    ),
                  ],
                )
                    : const SizedBox(); // Return empty box if no books to display
              }),
            ],
          ),
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
