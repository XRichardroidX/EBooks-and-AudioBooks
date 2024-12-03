import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> initializePayment(String email, double amount, Map<String, String> cardDetails) async {
  // final uri = Uri.parse('http://<YOUR_BACKEND_URL>/initialize-payment'); // Replace with your backend URL
  final uri = Uri.parse('http://localhost:30700');
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'amount': amount,
      'cardDetails': cardDetails,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Payment initialized: $data');
    // Handle successful response (e.g., redirect user to payment page)
  } else {
    final error = jsonDecode(response.body);
    print('Error: $error');
    // Handle error response
  }
}
