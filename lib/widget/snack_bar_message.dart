import 'package:flutter/material.dart';

void showCustomSnackbar(BuildContext context, String title, String message, Color color) {
  // Creating the snackbar content with title and message
  final snackBar = SnackBar(
    content: Row(
      children: [
        Icon(Icons.info, color: Colors.white), // You can customize the icon as needed
        const SizedBox(width: 8), // Spacing between icon and text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Ensures the column only takes as much space as needed
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
    backgroundColor: color, // Set the background color to the color parameter
    behavior: SnackBarBehavior.floating, // Allows snackbar to float above the bottom bar
    duration: const Duration(seconds: 3), // Snackbar duration
    shape: RoundedRectangleBorder( // Shape customization for rounded corners
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // Showing the snackbar using ScaffoldMessenger
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
