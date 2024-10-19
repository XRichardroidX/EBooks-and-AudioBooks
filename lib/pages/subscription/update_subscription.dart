import 'package:firebase_auth/firebase_auth.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_write_constants.dart';

/// Function to check user and update subscription data
Future<void> updateSubscription(String userId, String type, String feedback) async {
  // Get the current signed-in Firebase user
  final currentUser = FirebaseAuth.instance.currentUser;

  // Check if current user is logged in and matches the passed userId
  if (currentUser == null) {
    print('No user is currently signed in.');
    return;
  }

  if (currentUser.uid != userId) {
    print('The current Firebase user does not match the provided userId.');
    print('Provided userId: $userId');
    print('Firebase userId: ${currentUser.uid}');
    return;
  }

  // Check if the feedback is 'success'
  if (feedback != 'success') {
    print('Feedback is not success. Received feedback: $feedback');
    return;
  }

  try {
    // Initialize the Appwrite client
    Client client = Client()
        .setEndpoint(Constants.endpoint) // Your Appwrite endpoint
        .setProject(Constants.projectId); // Your Appwrite project ID

    // Initialize the Appwrite database service
    Databases databases = Databases(client);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Define your database ID and collection ID
    const String databaseId = Constants.databaseId; // Correctly using databaseId
    const String collectionId = Constants.usersCollectionId;

    // Search for the user document by the userId
    DocumentList userDocumentList = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [Query.equal('userId', userId)], // Search query by userId
    );

    if (userDocumentList.documents.isEmpty) {
      print('No document found for the userId: $userId');
      return;
    }

    // Assuming there is only one document per userId
    String documentId = userDocumentList.documents.first.$id;
    print('Found user document with documentId: $documentId');

    // Get the current date in ISO8601 string format
    String currentDateString = DateTime.now().toIso8601String();
    print('Current date (ISO8601): $currentDateString');

    // Calculate the end date (current date + 30 days) in ISO8601 string format
    String endDateForAMonth = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    print('End date (ISO8601): $endDateForAMonth');

    // Calculate the end date (current date + 30 days) in ISO8601 string format
    String endDateForAYear = DateTime.now().add(const Duration(days: 365)).toIso8601String();
    print('End date (ISO8601): $endDateForAYear');

    // Update the subscription details (startSub and endSub) as strings
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: {
        'startSub': currentDateString,
        'subscriptionPlan': type,
        'endSub': type == 'monthly' ? endDateForAMonth : endDateForAYear,
      },
    );
    prefs.setString('$userId+startSub', '$currentDateString');
    prefs.setString('$userId+subscriptionPlan', '$type');
    type == 'monthly' ? prefs.setString('$userId+endSub', '$endDateForAMonth') : prefs.setString('$userId+endSub', '$endDateForAYear');

    print('Subscription updated successfully for userId: $userId');
  } catch (e) {
    print('Error updating subscription: $e');
    throw e; // Re-throw the exception to handle it in the calling function
  }
}
