import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/ui/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../provider_service/forgot_verify_otp_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import '../../resource/image_paths.dart';

class OtpScreen extends StatefulWidget {
  String mEmailId;

  OtpScreen(this.mEmailId);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();
  final newPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> _verifyUser() async {
    if (otpController.text.isEmpty) {
      setState(() {
        isLoading = false;
      });
      Utils.showErrorMessage(context, 'Please enter OTP.');
      return;
    } else if (newPassController.text.isEmpty) {
      setState(() {
        isLoading = false;
      });
      Utils.showErrorMessage(context, 'Please enter new password.');
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      http.Response response = await Provider.of<ForgotVerifyOtpProvider>(
        context,
        listen: false,
      ).verifyOtp(otpController.text, widget.mEmailId, newPassController.text);

      var responseData = json.decode(response.body);

      setState(() {
        isLoading = false;
      });

      if (responseData['success'] == true) {
        _navigateTo(LoginPage());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${responseData['message']}')));
      } else {
        String errorMessage =
            responseData['message'] ?? 'Verify otp failed. Please try again.';
        Utils.showErrorMessage(context, errorMessage);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Exception =========> ${e.toString()}");
      Utils.showErrorMessage(
        context,
        'Something went wrong. Please try again.',
      );
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
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
          child: Center(
            // 👈 centers everything
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 👈 vertical centering
                  children: [
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondarycolor,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TextField (Centered)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Enter your 6 digit otp",
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
                    SizedBox(height: 10),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: TextField(
                        controller: newPassController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Enter Your password",
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
                        onPressed: _verifyUser,
                        child:
                            isLoading
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
