import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:novelcity/constants/app_write_constants.dart';

Future<bool> checkUserLoggedIn() async {
  try {
    // Initialize Appwrite client
    Client client = Client();
    Account account = Account(client);

    client
        .setEndpoint(Constants.endpoint) // Set your Appwrite endpoint
        .setProject(Constants.projectId); // Set your Appwrite project ID

    // Try to get the account details of the currently logged-in user
    models.User user = await account.get();

    // If we successfully get user details, the user is logged in
    return user.$id.isNotEmpty;
  } catch (e) {
    // If there's an error (such as user not being authenticated), return false
    print('Error checking login status: $e');
    return false;
  }
}
