// lib/models/book.dart

import 'dart:convert';

class Book {
  final String bookTitle;
  final String bookAuthor;
  final String bookCover;
  final String bookBody;
  final String bookSummary;

  Book({
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookCover,
    required this.bookBody,
    required this.bookSummary,
  });

  // Convert a Book into a Map. The keys must correspond to the names of the JSON keys.
  Map<String, dynamic> toMap() {
    return {
      'bookTitle': bookTitle,
      'bookAuthor': bookAuthor,
      'bookCover': bookCover,
      'bookBody': bookBody,
      'bookSummary': bookSummary,
    };
  }

  // Create a Book from a Map.
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      bookTitle: map['bookTitle'] ?? '',
      bookAuthor: map['bookAuthor'] ?? '',
      bookCover: map['bookCover'] ?? '',
      bookBody: map['bookBody'] ?? '',
      bookSummary: map['bookSummary'] ?? '',
    );
  }

  // Encode a Book to JSON.
  String toJson() => json.encode(toMap());

  // Decode a Book from JSON.
  factory Book.fromJson(String source) => Book.fromMap(json.decode(source));
}
