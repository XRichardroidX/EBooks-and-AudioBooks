import 'package:ebooks_and_audiobooks/new_app/front_end/upload_audiobooks_page.dart';
import 'package:flutter/material.dart';

import '../style/colors.dart';

class AudioBooksPage extends StatefulWidget {
  const AudioBooksPage({super.key});

  @override
  State<AudioBooksPage> createState() => _AudioBooksPageState();
}

class _AudioBooksPageState extends State<AudioBooksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          title: const Text(
            'AudioBooks',
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => UploadAudiobooksPage()));
          },
          child: Icon(
            Icons.upload,
            color: AppColors.textHighlight,
          ),
        )
    );
  }
}
