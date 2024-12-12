import 'dart:convert';
import 'dart:ui';
import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:novel_world/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:novel_world/widget/snack_bar_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_write_constants.dart';
import '../../widget/book.dart';
import '../../widget/cached_images.dart'; // Assuming this contains your custom cache manager
import '../book_list_page.dart';
import '../subscription/payment_plan_page.dart';
import 'epub_reader_page.dart';

class BookDetailsPage extends StatefulWidget {
  final String bookTitle;
  final String bookAuthor;
  final String bookCover;
  final String bookId;

  const BookDetailsPage({
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookCover,
    required this.bookId,
    Key? key,
  }) : super(key: key);

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool isExpanded = false;
  bool isBookInList = false;
  String userId = '';
  String? ebookBody;
  String? bookSummary;
  String? bookCategories;
  final Client client = Client();
  late Databases databases;
  bool loading = true;

  Future<String?> getBookBody(String documentId) async {
    try {
      // Initialize the Appwrite client and Databases instance
      final client = Client()
          .setEndpoint(Constants.endpoint)
          .setProject(Constants.projectId);
      final databases = Databases(client);

      const databaseId = Constants.databaseId;
      const collectionId = Constants.ebooksCollectionId;

      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );

      bookCategories = document.data['bookCategories'].join(" | ");
      bookSummary = document.data['bookSummary'] as String?;
      ebookBody = document.data['bookBody'] as String?;
      if (ebookBody != null && ebookBody!.isNotEmpty) {
        setState(() {
          loading = false;
        });
      }
      return ebookBody;
    } catch (e) {
      print('Error fetching document: $e');
      showCustomSnackbar(context, 'Poor Connection', 'Unable to fetch book', AppColors.error);
      context.pop();
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    getBookBody(widget.bookId);
    databases = Databases(client);
    loadBooks();
  }

  List<Book> recentBooks = [];


  // Save the book to recent reads
  Future<void> addToRecentReads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentBooks = prefs.getStringList('$userId+recentBooks') ?? [];

    // Create a Book instance
    Book currentBook = Book(
      bookTitle: widget.bookTitle,
      bookAuthor: widget.bookAuthor,
      bookCover: widget.bookCover,
      bookId: widget.bookId,
    );

    // Remove the book if it already exists to avoid duplicates
    recentBooks.removeWhere((bookJson) {
      Book book = Book.fromJson(bookJson);
      return book.bookTitle == currentBook.bookTitle &&
          book.bookAuthor == currentBook.bookAuthor;
    });

    // Insert the book at the beginning of the list
    recentBooks.insert(0, currentBook.toJson());

    // Optionally, limit the recent books to, say, 20
    if (recentBooks.length > 20) {
      recentBooks = recentBooks.sublist(0, 20);
    }

    await prefs.setStringList('$userId+recentBooks', recentBooks);
  }

  // Load both recentBooks and savedBooks from SharedPreferences
  Future<void> loadBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentBooksJson = prefs.getStringList('$userId+recentBooks') ?? [];

    List<Book> loadedRecentBooks =
    recentBooksJson.map((bookJson) => Book.fromJson(bookJson)).toList();

    setState(() {
      recentBooks = loadedRecentBooks;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 50),
          color: AppColors.backgroundSecondary,
          width: MediaQuery.of(context).size.width,
          height: double.infinity,
          constraints: BoxConstraints(
            maxHeight: 1000,
            maxWidth: 1000,
          ),
          child: (loading || ebookBody == null || bookSummary == null || bookCategories == null)
              ? Center(child: CircularProgressIndicator(color: AppColors.textHighlight))
              : SingleChildScrollView(
            child: Column(
              children: [
                if (widget.bookCover.isNotEmpty)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.4,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fill,
                            image: NetworkImage(widget.bookCover),
                          ),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                            image: NetworkImage(widget.bookCover),
                          ),
                           borderRadius: BorderRadius.circular(10),
                        ),
                        child: widget.bookCover.isEmpty
                            ? Text(
                          '${widget.bookTitle} Book Cover \n No Image Available',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                          textAlign: TextAlign.center,
                        )
                            : null,
                      ),
                    ],
                  ),
                Divider(color: AppColors.dividerColor),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Text(
                    '${bookCategories}',
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ),
                ),
                Divider(color: AppColors.dividerColor),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(left: 10.0, right: 5.0),
                      child: Text(
                        '${widget.bookTitle}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 5.0),
                      child: Text(
                        'by: ${widget.bookAuthor}',
                        style: const TextStyle(fontSize: 17, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    // Retrieve the subscription end timestamp from SharedPreferences
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String? endSubString = prefs.getString('$userId+endSub');

                    try {

                      if (endSubString != null) {
                        // Convert the endSub string back to a DateTime object
                        DateTime endSubDate = DateTime.parse(endSubString);
                        DateTime currentTime = DateTime.now();

                        // Check if the current time exceeds the subscription end time
                        if (currentTime.isAfter(endSubDate)) {
                          // Subscription has expired, navigate to the subscription page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubscriptionPage(), // Navigate to your subscription page
                            ),
                          );
                        } else {
                          // Subscription is active, open the book reader

                          // Navigate to the BookReader and wait for it to complete
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookReader(
                                bookTitle: widget.bookTitle,
                                bookAuthor: widget.bookAuthor,
                                bookBody: ebookBody ?? 'No Book Content Found'!,
                              ),
                            ),
                          );
                          await addToRecentReads();

                        }
                      } else {
                        // Handle case where endSub is not found in SharedPreferences (e.g., prompt subscription)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubscriptionPage(), // Navigate to your subscription page
                          ),
                        );
                      }
                    } catch (error) {
                      showCustomSnackbar(context, '$error', '$error', Colors.black);
                      print(error);
                    }
                  },
                  child: loading
                      ? CircularProgressIndicator(color: AppColors.iconColor)
                      : Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    padding: const EdgeInsets.all(4),
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 200,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: AppColors.buttonPrimary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.menu_book,
                          color: AppColors.textPrimary,
                        ),
                        Text(
                          'Start',
                          style: TextStyle(fontSize: 20, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    bookSummary!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}