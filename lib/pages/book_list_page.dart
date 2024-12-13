import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:novel_world/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/book.dart';
import '../widget/snack_bar_message.dart';
import 'e_book_pages/book_details_page.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({Key? key}) : super(key: key);

  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  List<Book> recentBooks = [];
  List<Book> savedBooks = [];
  String userId = '';

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '123456789';
    loadBooks();
  }

  // Load both recentBooks and savedBooks from SharedPreferences
  Future<void> loadBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentBooksJson = prefs.getStringList('$userId+recentBooks') ?? [];
    List<String> savedBooksJson = prefs.getStringList('$userId+bookList') ?? [];

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
    List<String> savedBooksJson = prefs.getStringList('$userId+bookList') ?? [];

    savedBooksJson.removeWhere((bookJson) {
      Book existingBook = Book.fromJson(bookJson);
      return existingBook.bookTitle == book.bookTitle &&
          existingBook.bookAuthor == book.bookAuthor;
    });

    await prefs.setStringList('$userId+bookList', savedBooksJson);

    setState(() {
      savedBooks.removeWhere((b) =>
      b.bookTitle == book.bookTitle && b.bookAuthor == book.bookAuthor);
    });
    showCustomSnackbar(context, 'Read List', 'Book removed from your list', AppColors.info);
  }

  void navigateToBookDetails(Book book) async {
    if (FirebaseAuth.instance.currentUser == null) {
      context.push('/login');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailsPage(
            bookTitle: book.bookTitle,
            bookAuthor: book.bookAuthor,
            bookCover: book.bookCover,
            bookId: book.bookId,
          ),
        ),
      ).then((_) {
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
      body: Container(
        color: AppColors.backgroundSecondary,
        child: ListView(
          children: [
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
            if (recentBooks.isNotEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5, // Adjust the height of the horizontal list
                child: ListView.builder(
                  scrollDirection: Axis.vertical, // Horizontal scrolling
                  itemCount: 1, // Limit to a maximum of 10 books
                  itemBuilder: (context, index) {
                    final book = recentBooks[index];
                    return InkWell(
                      onTap: () => navigateToBookDetails(book),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundOverlay,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height * 0.40,
                                  constraints: BoxConstraints(
                                    maxHeight: 1000,
                                    maxWidth: 1000,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(20),
                                    image: DecorationImage(
                                      fit: BoxFit.fill,
                                      image: NetworkImage(book.bookCover),
                                    ),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 5),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: MediaQuery.of(context).size.height * 0.32,
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.contain,
                                      image: NetworkImage(book.bookCover),
                                    ),
                                  ),
                                  child: book.bookCover.isEmpty
                                      ? Text(
                                    '${book.bookTitle} Book Cover \n No Image Available',
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  )
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              truncateText(book.bookTitle),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              truncateText(book.bookAuthor),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
            if (recentBooks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Book History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            if (recentBooks.isNotEmpty)
              ListView.builder(
                reverse: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentBooks.length,
                itemBuilder: (context, index) {
                  final book = recentBooks[index];
                  return ListTile(
                    leading: Container(
                      height: 50,
                      width: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          fit: BoxFit.contain,
                          image: NetworkImage(book.bookCover),
                        ),
                      ),
                      child: book.bookCover.isEmpty
                          ? Text(
                        '${book.bookTitle} Book Cover \n No Image Available',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                        textAlign: TextAlign.center,
                      )
                          : null,
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
