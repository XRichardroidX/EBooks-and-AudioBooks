import 'package:flutter/material.dart';

class UploadEBooksPage extends StatefulWidget {
  const UploadEBooksPage({super.key});

  @override
  State<UploadEBooksPage> createState() => _UploadEBooksPageState();
}

class _UploadEBooksPageState extends State<UploadEBooksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Text("Upload E-Books Page"),
        ),
      ),
    );
  }
}
