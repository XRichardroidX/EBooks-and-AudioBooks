import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../../constants/app_write_constants.dart';

// Initialize Appwrite Client and Databases service
Client client = Client();
Databases databases = Databases(client);

Future<void> uploadBookToDatabase(String bookTitle, String authorName, String bookSummary, String bookCover, String bookPdf) async {
  try {
    client
        .setEndpoint(Constants.endpoint) // Your Appwrite endpoint
        .setProject(Constants.projectId); // Your project ID

    // Make sure the user is authenticated before calling this function

    // Create a new document with the given details
    Document response = await databases.createDocument(
      databaseId: Constants.databaseId, // Replace with your database ID
      collectionId: '66d7210e001271490533', // Replace with your collection ID
      documentId: 'unique()', // 'unique()' generates a unique document ID
      data: {
        'bookTitle': bookTitle, // Replace with your schema field name
        'authorName': authorName, // Replace with your schema field name
        'bookSummary': bookSummary, // Replace with your schema field name
        'bookCover': bookCover, // Replace with your schema field name
        'bookPdf': bookPdf, // Replace with your schema field name
      },
      permissions: [
        Permission.read(Role.any()), // Allow any user to read the document
        Permission.write(Role.any()), // Allow any user to write to the document
      ],
    );

    print('Document created successfully: ${response.data}');
  } catch (e) {
    print('Error creating document: $e');
  }
}
