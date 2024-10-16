// lib/pages/book_list_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:novel_world/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/book.dart';
import '../widget/cached_images.dart';
import 'e_book_pages/book_details_page.dart'; // Assuming this contains your custom cache manager

class BookListPage extends StatefulWidget {
  const BookListPage({Key? key}) : super(key: key);

  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  List<Book> recentBooks = [];
  List<Book> savedBooks = [];

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  // Load both recentBooks and savedBooks from SharedPreferences
  Future<void> loadBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentBooksJson = prefs.getStringList('recentBooks') ?? [];
    List<String> savedBooksJson = prefs.getStringList('bookList') ?? [];

    List<Book> loadedRecentBooks =
    recentBooksJson.map((bookJson) => Book.fromJson(bookJson)).toList();

    List<Book> loadedSavedBooks =
    savedBooksJson.map((bookJson) => Book.fromJson(bookJson)).toList();

    setState(() {
      recentBooks = loadedRecentBooks;
      savedBooks = loadedSavedBooks;
    });
  }

  // Remove a book from the savedBooks list
  Future<void> removeFromSavedBooks(Book book) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedBooksJson = prefs.getStringList('bookList') ?? [];

    savedBooksJson.removeWhere((bookJson) {
      Book existingBook = Book.fromJson(bookJson);
      return existingBook.bookTitle == book.bookTitle &&
          existingBook.bookAuthor == book.bookAuthor;
    });

    await prefs.setStringList('bookList', savedBooksJson);

    setState(() {
      savedBooks.removeWhere((b) =>
      b.bookTitle == book.bookTitle && b.bookAuthor == book.bookAuthor);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Book removed from your saved list')),
    );
  }

  // Navigate to BookDetailsPage
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
        // Reload books when returning to refresh the list
        loadBooks();
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Booklist',
          style: TextStyle(
            color: AppColors.textHighlight,
          ),
        ),
        backgroundColor: AppColors.backgroundPrimary,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Container(
        color: AppColors.backgroundSecondary,
        child: ListView(
          children: [
            // Recent Books Section
            if (recentBooks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Recently Read',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            if (recentBooks.isNotEmpty)
              SizedBox(
                height: 180, // Adjust the height of the horizontal list
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, // Horizontal scrolling
                  itemCount: recentBooks.length > 10
                      ? 10
                      : recentBooks.length, // Limit to a maximum of 10 books
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
                              placeholder: (context, url) =>
                              const CircularProgressIndicator(),
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

            // Saved Books Section
            if (savedBooks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Saved Books',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            if (savedBooks.isNotEmpty)
              ListView.builder(
                reverse: true,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: savedBooks.length,
                itemBuilder: (context, index) {
                  final book = savedBooks[index];
                  return ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: book.bookCover,
                      cacheManager: CustomCacheManager(),
                      width: 50,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Container(
                        width: 50,
                        height: 80,
                        color: Colors.grey,
                        child: const Icon(Icons.error),
                      ),
                    ),
                    title: Text(
                      truncateText(book.bookTitle),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      truncateText(book.bookAuthor),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => removeFromSavedBooks(book),
                    ),
                    onTap: () => navigateToBookDetails(book),
                  );
                },
              ),

            // If no books are present
            if (recentBooks.isEmpty && savedBooks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No books in your list. Start reading some!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
