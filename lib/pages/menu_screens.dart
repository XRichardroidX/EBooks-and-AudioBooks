import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:ebooks_and_audiobooks/pages/audio_books_page.dart';
import 'package:ebooks_and_audiobooks/pages/download_page.dart';
import 'package:ebooks_and_audiobooks/pages/payment_plan_page.dart';
import 'package:ebooks_and_audiobooks/style/colors.dart';
import 'package:flutter/material.dart';

import 'e_books_page.dart';

class MenuScreens extends StatefulWidget {
  int? currentPage;
   MenuScreens({super.key});

  @override
  State<MenuScreens> createState() => _MenuScreensState();
}

class _MenuScreensState extends State<MenuScreens> {


  int? _currentPage;

  @override
  void initState() {
    // implement initState
    _currentPage = (widget.currentPage ?? 0);
    super.initState();
  }

  // This List is for Icons that are active
  final List<IconData> _activeIcons = [
    Icons.menu_book_sharp,
    Icons.spatial_audio_off,
    Icons.cloud_download,
    Icons.payment,
  ];

  // This List is for Icons that are inactive
  final List<IconData> _inactiveIcons = [
    Icons.menu_book_sharp,
    Icons.spatial_audio_off,
    Icons.cloud_download,
    Icons.payment,
  ];



  // This is widget switches pages on a selected tap
  Widget PageTransition(int currentPage) {
    switch (currentPage) {
      case 0:
        return const EBooksPage();
      case 1:
        return const AudioBooksPage();
      case 2:
        return const DownloadPage();
      case 3:
        return const PaymentPlanPage();
      default:
        return const EBooksPage();
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      // This is the Bottom Navigation bar
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: AppColors.backgroundSecondary,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {});
          _currentPage = index;
        },
        items: List.generate(
          _activeIcons.length,
              (index) {
            return _currentPage == index
                ? Icon((_activeIcons[index]), color: AppColors.textPrimary)
                : (Icon((_inactiveIcons[index]), color: AppColors.buttonSecondary,));
          },
        ),
      ),
      // This is the App Body
      body: PageTransition(_currentPage!),
    );
  }
}
