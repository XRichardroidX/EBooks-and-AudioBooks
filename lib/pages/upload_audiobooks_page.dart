import 'package:flutter/material.dart';

class UploadAudiobooksPage extends StatefulWidget {
  const UploadAudiobooksPage({super.key});

  @override
  State<UploadAudiobooksPage> createState() => _UploadAudiobooksPageState();
}

class _UploadAudiobooksPageState extends State<UploadAudiobooksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Text("Upload Audio-Books Page"),
        ),
      ),
    );
  }
}
