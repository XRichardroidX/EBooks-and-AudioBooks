import 'package:flutter/material.dart';
import '../style/colors.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          title: const Text(
            'Downloads',
            style: TextStyle(
                color: AppColors.textHighlight
            ),),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: AppColors.backgroundPrimary,
          child: Text(""),
        )
    );
  }
}
