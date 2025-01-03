import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:novelcity/pages/authentication/login_page.dart';
import 'package:novelcity/style/colors.dart';
import 'package:novelcity/widget/snack_bar_message.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

TextEditingController emailController = TextEditingController();

class _ForgotPassState extends State<ForgotPass> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pushReplacement('/login'),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 27,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
            child: Column(
              children: [
                const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Please enter the email address associated with your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 45,
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.textHighlight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (emailController.text.isNotEmpty) {
                      resetPassword(
                        context: context,
                        email: emailController.text,
                      );
                      emailController.clear();
                    } else {
                      showCustomSnackbar(context, 'Warning!!', "Email field is empty", AppColors.warning);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.buttonPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    "RESET PASSWORD",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> resetPassword({required BuildContext context, required String email}) async {
  try {
    // Firebase password reset method
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    showCustomSnackbar(context, 'Success', 'Password reset email sent to $email', AppColors.success);
    context.pushReplacement('/login');
  } catch (e) {
    // Show an error message if something goes wrong
    showCustomSnackbar(context, 'Error', e.toString(), AppColors.error);
  }
}
