import 'package:flutter/material.dart';
import '../style/colors.dart';

class PaymentPlanPage extends StatefulWidget {
  const PaymentPlanPage({super.key});

  @override
  State<PaymentPlanPage> createState() => _PaymentPlanPageState();
}

class _PaymentPlanPageState extends State<PaymentPlanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          title: const Text(
            'Subscribe',
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
