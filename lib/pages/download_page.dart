import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../firebase_functions/logout.dart';
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
        ),
        floatingActionButton: FloatingActionButton(
        onPressed: (){
            showDialog<void>(
              context: context,
              barrierDismissible:
              false, // User must tap button!
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Log out'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text('Do you want to proceed with this action?'),
                      ],
                    ),
                  ),
                  actions: <Widget>[
// "Yes" button
                    TextButton(
                      child: Text('Yes'),
                      onPressed: () {
                        signOutUser();
                        Navigator.of(context).pop(
                            false); // Close dialog and return false
                        context.go('/');

                      },
                    ),
// "No" button
                    TextButton(
                      child: Text('No'),
                      onPressed: () {
// Perform action when user selects "No"
                        Navigator.of(context).pop(
                            false); // Close dialog and return false
                      },
                    ),
                  ],
                );
              },
            );
        },
        child: Icon(
            Icons.logout,
            color: AppColors.textHighlight,
          )
        ),
    );
  }
}
