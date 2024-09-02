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
