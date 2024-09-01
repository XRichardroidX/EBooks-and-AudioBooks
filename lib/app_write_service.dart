import 'package:appwrite/appwrite.dart';

Client client = Client();
Account? account;

Future<void> appWriteId() async {
  client
      .setEndpoint('https://cloud.appwrite.io/v1') // Your Appwrite endpoint
      .setProject('66d3512e003a47f8b5d9') // Your project ID
      .setSelfSigned(status: true); // For self-signed certificates

  account = Account(client);
}

// Function to check if user is logged in
Future<bool> checkUserLoggedIn() async {
  try {
    await account!.get(); // Try to get the current user session
    return true; // If successful, the user is logged in
  } catch (e) {
    return false; // If an error occurs, the user is not logged in
  }
}
