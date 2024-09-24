import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:flutter/material.dart';

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
        iconTheme: IconThemeData(
          color: AppColors.textPrimary
        ),
        title: Text(
          widget.bookTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          color: AppColors.backgroundSecondary,
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.bookCover.isNotEmpty)
                Image.network(
                  widget.bookCover,
                  height: 350,
                ),
              const SizedBox(height: 16),
              Text(
                'by: ${widget.bookAuthor}',
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookReader(
                        bookTitle: widget.bookTitle ?? 'Unknown Title',
                        bookAuthor: widget.bookAuthor ?? 'Unknown Author',
                        bookBody: widget.bookBody ?? 'Empty',
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
                      )
                    ],
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
      ),
    );
  }
}
