import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/provider_service/forgot_password_provider.dart';
import 'package:provider/provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import '../../resource/image_paths.dart';
import 'package:http/http.dart' as http;

import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreen();
}

class _ForgotPasswordScreen extends State<ForgotPasswordScreen> {
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  Future<void> _sendOtpMail() async {
    if (_formKey.currentState!.validate()) {
      if (phoneController.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter your email');
        return;
      }

      setState(() {
        isLoading = true;
      });

      http.Response response = await Provider.of<ForgotPasswordProvider>(
        context,
        listen: false,
      ).forgotPassword(phoneController.text);

      var responseData = json.decode(response.body);

      setState(() {
        isLoading = false;
      });

      if (responseData['success'] == true) {
        _navigateTo(OtpScreen(phoneController.text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      } else {
        String errorMessage =
            responseData['message'] ?? 'Forgot password failed. Try again.';
        Utils.showErrorMessage(context, errorMessage);
      }
    }
  }
  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(ImagePaths.background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center( // 👈 centers everything
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 👈 vertical centering
                  children: [
                    const SizedBox(height: 20),


                    const SizedBox(height: 10),

                    Text(
                      "Enter your email to receive OTP",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textBox,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TextField (Centered)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Enter Your Email",
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.primaryColor,
                          ),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: AppColors.primaryColor,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.textBox,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.secondarycolor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Button
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondarycolor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _sendOtpMail,
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}