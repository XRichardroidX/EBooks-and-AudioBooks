import 'dart:io';
import 'package:novelcity/style/colors.dart';
import 'package:novelcity/widget/snack_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class UploadAudiobooksPage extends StatefulWidget {
  const UploadAudiobooksPage({super.key});

  @override
  State<UploadAudiobooksPage> createState() => _UploadAudiobooksPageState();
}

class _UploadAudiobooksPageState extends State<UploadAudiobooksPage> {


  Uint8List? bookCover;
  TextEditingController writeUp = TextEditingController();
  bool pickedImage = false;
  File? selectedPdf;

  Future<void> _selectBookCover(BuildContext context, bool imageFrom) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (imageFrom) {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        bookCover = await image!.readAsBytes();
        pickedImage = true;
      } else {
        final XFile? photo = await picker.pickImage(source: ImageSource.camera);
            bookCover = await photo!.readAsBytes();
        pickedImage = true;
      }

      if (bookCover!.isNotEmpty){
        pickedImage = true;
        setState(() {});
      }
    } on PlatformException catch (e) {
      showCustomSnackbar(context, 'Select Image', '$e', AppColors.error);
    }
  }
    Future<void> _selectPdf() async {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedPdf = File(result.files.single.path!);
        });
      }
    }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('File Selection'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: (){
                  _selectBookCover(context, true);
                },
                child: const Text('Select Image from Gallery'),
              ),
              ElevatedButton(
                onPressed: (){
                  _selectBookCover(context, false);
                },
                child: const Text('Take a picture'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (){
                  _selectPdf();
                },
                child: const Text('Select PDF'),
              ),
              const SizedBox(height: 16),
              if (bookCover != null)
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width *
                          0.3, // Image width
                      height: MediaQuery.of(context).size.width *
                          0.3, // Image height
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: MemoryImage(bookCover!),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              if (selectedPdf != null)
                Text('Selected PDF: ${selectedPdf!.path}'),
              ElevatedButton(
                onPressed: (){

                },
                child: const Text('Upload Book'),
              ),
            ],
          ),
        ),
      );
    }
}