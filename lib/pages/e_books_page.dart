// pages/profile_page.dart
import 'package:ebooks_and_audiobooks/pages/upload_e_books_page.dart';
import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EBooksPage extends StatelessWidget {
  const EBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Text(
            'E-Books',
        style: TextStyle(
          color: AppColors.textHighlight
        ),),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: AppColors.backgroundPrimary,
        child: Text(""),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPrimary,
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => UploadEBooksPage()));
      },
        child: Icon(
          Icons.upload,
          color: AppColors.textHighlight,
        ),
      ),
    );
  }
}
