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
  bool isBookInList = false; // To track if the book is already in the list
  String userId = '';
  String? ebookBody;
  String? bookSummary;
  String? bookCategories;
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


  Future<String?> loadBookBodyFromPreferences(String bookId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bookCategories = prefs.getString('$userId+bookCategories+${widget.bookId}');
    bookSummary = prefs.getString('$userId+bookSummary+${widget.bookId}');
    return prefs.getString('$userId+bookBody+${widget.bookId}');
  }



  Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    try {
      // Initialize the Appwrite client
      client
        ..setEndpoint(Constants.endpoint) // Your Appwrite Endpoint
        ..setProject(Constants.projectId); // Your Project ID

      databases = Databases(client);
      print("Fetching user details from Appwrite...");
      final response = await databases.listDocuments(
        databaseId: Constants.databaseId, // Replace with your actual database ID
        collectionId: Constants.usersCollectionId, // Replace with your actual collection ID
        queries: [
          Query.equal('userId', userId), // Assuming 'userId' is the attribute name in Appwrite
        ],
      );

      print("Response from Appwrite: ${response.documents.length} documents found.");

      if (response.documents.isNotEmpty) {
        // Assuming the first document is the correct one
        return response.documents[0].data;
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    return null;
  }



  Future<String?> getBookBody(String documentId) async {
    try {

      String? savedBookBody = await loadBookBodyFromPreferences(documentId);
      if (savedBookBody != null) {
        setState(() {
          ebookBody = savedBookBody;
          loading = false;
        });
        return savedBookBody;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();

      final userDetails = await fetchUserDetails(userId);
      await prefs.setString('$userId+startSub', userDetails!['startSub'] ?? '');
      await prefs.setString('$userId+endSub', userDetails['endSub'] ?? '');

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


      bookCategories = document.data['bookCategories'].join(" | ");
      bookSummary = document.data['bookSummary'] as String?;
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
      showCustomSnackbar(context, 'Poor Connection', 'Unable to fetch book', AppColors.error);
      context.pop();
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
  Future<void> addToBookList(String bookBody, String summary, String categories) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> bookList = prefs.getStringList('$userId+bookList') ?? [];

    // Create a Book instance with additional attributes
    Book newBook = Book(
      bookTitle: widget.bookTitle,
      bookAuthor: widget.bookAuthor,
      bookCover: widget.bookCover,
      bookId: widget.bookId,
    );

    // Check if the book already exists in the list
    bool exists = bookList.any((bookJson) {
      Book book = Book.fromJson(bookJson);
      return book.bookTitle == newBook.bookTitle &&
          book.bookAuthor == newBook.bookAuthor;
    });

    // If not a duplicate and under limit, add the book
    if (!exists) {
      if (bookList.length < 10) {
        bookList.add(newBook.toJson());  // Convert Map to String
        await prefs.setStringList('$userId+bookList', bookList);
        await prefs.setString('$userId+bookCategories+${widget.bookId}', categories);
        await prefs.setString('$userId+bookSummary+${widget.bookId}', summary);
        await prefs.setString('$userId+bookBody+${widget.bookId}', ebookBody!);
        setState(() {
          isBookInList = true;
        });
        showCustomSnackbar(
            context, 'Read List', 'Book added to your list', AppColors.success);
      } else {
        showCustomSnackbar(
            context, 'Read List', 'You have reached the limit of 10 books', AppColors.error);
      }
    } else {
      showCustomSnackbar(
          context, 'Read List', 'Book is already in your list', AppColors.info);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_back_ios)),
        actions: [
          // Booklist Icon
          InkWell(
            onTap: () {
              if (isBookInList) {
                // If already in the list, remove it
                removeFromBookList();
              } else {
                // Else, add it
                addToBookList(ebookBody!, bookSummary!, bookCategories!);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                isBookInList ? Icons.restore_from_trash_outlined : Icons.arrow_downward,
                color: isBookInList ? Colors.white : Colors.white,
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
        child: (loading || ebookBody == null || bookSummary== null || bookCategories == null) ?
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
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Text(
                  '${bookCategories}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
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
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textSecondary,
                      ),
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
                child: Text(bookSummary!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textSecondary,
                      ),
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
