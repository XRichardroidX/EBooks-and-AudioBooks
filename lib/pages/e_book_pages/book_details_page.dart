import 'dart:ui';
import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:flutter/material.dart';
import '../../constants/app_write_constants.dart';
import 'epub_reader_page.dart';

class BookDetailsPage extends StatefulWidget {
  final String bookTitle;
  final String bookAuthor;
  final String bookCover;
  final String bookBody;
  final String bookSummary;

  const BookDetailsPage({
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookCover,
    required this.bookBody,
    required this.bookSummary,
    Key? key,
  }) : super(key: key);

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool isExpanded = false;

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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.arrow_downward),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.share),
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundSecondary,
        width: MediaQuery.of(context).size.width,
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
                  // Foreground book cover image without blur
                  Image.network(
                    widget.bookCover,
                    height: MediaQuery.of(context).size.height * 0.32,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
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
                              color: AppColors.textPrimary,
                              fontSize: 16
                          ),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookReader(
                      bookTitle: widget.bookTitle,
                      bookAuthor: widget.bookAuthor,
                      bookBody: widget.bookBody,
                    ),
                  ),
                );
              },
              child: Container(
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
                'Annotation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
