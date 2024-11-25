import 'dart:ui';
import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String bookSummary;
  final String bookId;

  const BookDetailsPage({
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookCover,
    required this.bookSummary,
    required this.bookId,
    Key? key,
  }) : super(key: key);

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool isExpanded = false;
  bool isBookInList = false; // To track if the book is already in the list
  String userId = '';
  String? ebookBody;
  final Client client = Client();
  late Databases databases;
  bool loading = true;


  List<Book> recentBooks = [];

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


  // Future<String?> loadBookBodyFromPreferences(String bookId) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   bookBody = prefs.getString('bookBody+$bookId');
  //   return prefs.getString('bookBody+$bookId');
  // }


  Future<String?> getBookBody(String documentId) async {
    try {
      // Initialize the Appwrite client
      final client = Client()
          .setEndpoint(Constants.endpoint) // Replace with your Appwrite endpoint
          .setProject(Constants.projectId);
      // Initialize the Appwrite Databases instance
      final databases = Databases(client);

      // Replace with your database ID and collection ID
      const databaseId = Constants.databaseId;     // Replace with your database ID
      const collectionId = Constants.ebooksCollectionId; // Replace with your collection ID

      // Fetch the document
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );


      ebookBody = document.data['bookBody'] as String?;
      // Return the 'bookBody' attribute
      if(ebookBody.toString().isNotEmpty){
        setState(() {
          loading = false;
        });
      }
      return document.data['bookBody'] as String?;
    } catch (e) {
      // Handle errors, e.g., document not found or network issues
      print('Error fetching document: $e');
      showCustomSnackbar(context, '$e', '$e', Colors.red);
      return null;
    }
  }





  // Navigate to BookDetailsPage
  void navigateToBookDetails(Book book) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailsPage(
          bookTitle: book.bookTitle,
          bookAuthor: book.bookAuthor,
          bookCover: book.bookCover,
          bookSummary: book.bookSummary,
          bookId: book.bookId,
        ),
      ),
    ).then((_) {
      // Reload books when returning to refresh the list
      loadBooks();
    });
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
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    loadBooks();
    getBookBody(widget.bookId);
    databases = Databases(client);
    checkIfBookInList();
  }




  // Check if the current book is already in the booklist
  Future<void> checkIfBookInList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> bookList = prefs.getStringList('$userId+bookList') ?? [];

    // Decode each book and check for a match
    bool exists = bookList.any((bookJson) {
      Book book = Book.fromJson(bookJson);
      return book.bookTitle == widget.bookTitle &&
          book.bookAuthor == widget.bookAuthor;
    });

    setState(() {
      isBookInList = exists;
    });
  }

  // Add the current book to the booklist
  Future<void> addToBookList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> bookList = prefs.getStringList('$userId+bookList') ?? [];

    // Create a Book instance
    Book newBook = Book(
      bookTitle: widget.bookTitle,
      bookAuthor: widget.bookAuthor,
      bookCover: widget.bookCover,
      bookSummary: widget.bookSummary,
      bookId: widget.bookId,
    );

    // Check for duplicates
    bool exists = bookList.any((bookJson) {
      Book book = Book.fromJson(bookJson);
      return book.bookTitle == newBook.bookTitle &&
          book.bookAuthor == newBook.bookAuthor;
    });

    if (!exists) {
      bookList.add(newBook.toJson());
      await prefs.setStringList('$userId+bookList', bookList);
      setState(() {
        isBookInList = true;
      });
      showCustomSnackbar(context, 'Read List', 'Book added to your list', AppColors.success);
    } else {
      showCustomSnackbar(context, 'Read List', 'Book is already in your list', AppColors.info);
    }
  }



  // Optional: Remove the book from the list
  Future<void> removeFromBookList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> bookList = prefs.getStringList('$userId+bookList') ?? [];

    bookList.removeWhere((bookJson) {
      Book book = Book.fromJson(bookJson);
      return book.bookTitle == widget.bookTitle &&
          book.bookAuthor == widget.bookAuthor;
    });

    await prefs.setStringList('$userId+bookList', bookList);
    setState(() {
      isBookInList = false;
    });
    showCustomSnackbar(context, 'Read List', 'Book removed from your list', AppColors.info);
  }

  // Save the book to recent reads
  Future<void> addToRecentReads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentBooks = prefs.getStringList('$userId+recentBooks') ?? [];

    // Create a Book instance
    Book currentBook = Book(
      bookTitle: widget.bookTitle,
      bookAuthor: widget.bookAuthor,
      bookCover: widget.bookCover,
      bookSummary: widget.bookSummary,
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

  @override
  Widget build(BuildContext context) {
    // Split the bookSummary into words
    final words = widget.bookSummary.split(' ');

    // Check if the summary exceeds 80 words
    final hasMoreThan80Words = words.length > 80;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        title: Text(
          widget.bookTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Booklist Icon
          InkWell(
            onTap: () {
              if (isBookInList) {
                // If already in the list, remove it
                removeFromBookList();
              } else {
                // Else, add it
                addToBookList();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                isBookInList ? Icons.check : Icons.arrow_downward,
                color: isBookInList ? Colors.green : Colors.white,
              ),
            ),
          ),
          // Navigate to BookListPage
          InkWell(
            onTap: () {
              // Navigate to the BookListPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookListPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.list),
            ),
          ),
          // Share Icon (Existing)
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Icon(Icons.share),
          // ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundSecondary,
        width: MediaQuery.of(context).size.width,
        height: double.infinity,
        child: loading ?
        Center(child: CircularProgressIndicator(color: AppColors.textHighlight))
            :
        SingleChildScrollView(
          child: Column(
            children: [
              if (widget.bookCover.isNotEmpty)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background image with blur and black overlay
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.4,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: CachedNetworkImageProvider(
                            widget.bookCover,
                            cacheManager: CustomCacheManager(), // Use your custom cache manager
                          ),
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ),
                    // Foreground book cover image without blur
                    CachedNetworkImage(
                      imageUrl: widget.bookCover,
                      cacheManager: CustomCacheManager(),
                      height: MediaQuery.of(context).size.height * 0.32,
                      fit: BoxFit.fill,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: AppColors.buttonPrimary,),
                      ),
                      errorWidget: (context, url, error) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.32,
                          width: MediaQuery.of(context).size.width,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey), // Optional border
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.bookTitle} Book Cover \n No Internet',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              Divider(color: AppColors.dividerColor),
              Text(
                'by: ${widget.bookAuthor}',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              Divider(color: AppColors.dividerColor),
              const SizedBox(height: 16),
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
                  child: loading ?
                  CircularProgressIndicator(color: AppColors.iconColor,)
                  :
                  Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  padding: const EdgeInsets.all(4),
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
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
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
                child: Column(
                  children: [
                    Text(
                      isExpanded || !hasMoreThan80Words
                          ? widget.bookSummary
                          : words.take(80).join(' ') + '...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hasMoreThan80Words) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Text(
                          isExpanded ? 'See Less' : 'See More',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
                                Center(child: const CircularProgressIndicator(color: AppColors.buttonPrimary,)),
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
            ],
          ),
        ),
      ),
    );
  }
}
