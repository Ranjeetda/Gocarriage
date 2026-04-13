import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:gocarriage_universal/ui/auth/selection_screen.dart';
import 'package:gocarriage_universal/ui/auth/sign_up_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../provider_service/signIn_service.dart';
import '../../resource/CurvedHeaderClipper.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import '../../resource/image_paths.dart';
import 'package:http/http.dart' as http;

import '../../resource/shared_preferences.dart';
import '../commanScreen/common_screen.dart';
import '../dashboardScreen/customer_bottom_navigation_bar.dart';
import '../driver/home_screen/driver_bottom_navigationBar.dart';
import '../operatorScreen/operator_bottom_navigationbar.dart';
import '../vehicleOwner/home_screen/dashboard_vehicle_owner_screen.dart';
import 'forgot_password_screen.dart';

class LoginPage extends StatefulWidget {
  LoginPage();

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isChecked = false;
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    if(PrefUtils.getFcmToken().isEmpty){
      getToken();
    }
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> getToken() async {
    if (Prefs.prefs == null) await Prefs.init();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    /// iOS Permission
    if (Platform.isIOS) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      /// Wait for APNS token
      await Future.delayed(const Duration(seconds: 1));

      String? apnsToken = await messaging.getAPNSToken();
      print("APNS TOKEN: $apnsToken");
     // PrefUtils.setFcmToken(apnsToken!);

    }

    /// Get FCM token (Android + iOS)
    String? mToken = await messaging.getToken();

    if (mToken != null) {
      PrefUtils.setFcmToken(mToken);
    }

    print("FCM Token: $mToken");

    /// Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      PrefUtils.setFcmToken(newToken);
      print("Refreshed FCM Token: $newToken");
    });
  }

  void _sendOTP() {
    if (PrefUtils.getRole() == "customer") {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: CustomerBottomNavigationBar(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    } else if (PrefUtils.getRole() == "driver") {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: DriverBottomNavigationbar(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    }else if (PrefUtils.getRole() == "owner") {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: DashboardVehicleOwnerScreen(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    }else if (PrefUtils.getRole() == "operator") {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: OperatorBottomNavigationbar(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 900),
          reverseDuration: const Duration(milliseconds: 900),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (phoneController.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter your mobile or email');
        return;
      } else if (passwordController.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter your password');
        return;
      }
      setState(() {
        isLoading = true;
      });

      http.Response response = await Provider.of<SignInProvider>(
        context,
        listen: false,
      ).signIn(phoneController.text.trim(), passwordController.text.trim(), PrefUtils.getFcmToken(), PrefUtils.getDeviceType());
      var responseData = json.decode(response.body);
      setState(() {
        isLoading = false;
      });

      if (responseData['success'] == true) {
        PrefUtils.setToken(responseData['data']['token']);
        //PrefUtils.setUserId(responseData["user"]["id"].toString());
        PrefUtils.setName(responseData['data']["user"]["name"]);
        PrefUtils.setRole(responseData['data']["user"]["role"]);
        PrefUtils.setEmail(responseData['data']["user"]["email"]);
        PrefUtils.setMobile(responseData['data']["user"]["mobile"]);
        if (responseData['data']['user']['role'] == 'driver') {
          PrefUtils.setUserId(
            responseData['data']["user"]["driver_id"].toString(),
          );
        } else if (responseData['data']['user']['role'] == 'operator') {
          PrefUtils.setUserId(
            responseData['data']["user"]["operator_id"].toString(),
          );
        } else if (responseData['data']['user']['role'] == 'customer') {
          PrefUtils.setUserId(
            responseData['data']["user"]["customer_id"].toString(),
          );
        }else if (responseData['data']['user']['role'] == 'owner') {
          PrefUtils.setUserId(
            responseData['data']["user"]["ownerId"].toString(),
          );
        }
        PrefUtils.setLoggedIn(true);
        PrefUtils.setFirstTime(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData['message'])));
        _sendOTP();
      } else {
        String errorMessage =
            responseData['message'] ?? 'Sign in failed. Please try again.';
        Utils.showErrorMessage(context, errorMessage);
      }
    }
  }

  Widget header() {
    return ClipPath(
      clipper: CurvedHeaderClipper(),
      child: Container(
        width: double.infinity,
        height: 300,
        color: AppColors.primaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Join Gocarriage Partner!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "community",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 27),
            Image.asset(ImagePaths.appLogoVertical, height: 80, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(300),
        child: header(),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ACCOUNT TITLE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Account",
                    style: TextStyle(
                      color: AppColors.secondarycolor,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 25,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Login account to GoCarriage",
                    style: TextStyle(
                      color: AppColors.secondarycolor,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // FORM FIELDS
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // EMAIL
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Enter Your Mobile / Email",
                            hintStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primaryColor,
                            ),
                            prefixIcon: const Icon(
                              Icons.email,
                              color: AppColors.primaryColor,
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
                      const SizedBox(height: 12),

                      // PASSWORD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            hintStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primaryColor,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: AppColors.primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
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
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: InkWell(
                      onTap: () {
                        _navigateTo(ForgotPasswordScreen());
                      },
                      child: Text(
                        "Forgot Password",
                        style: TextStyle(
                          color: AppColors.secondarycolor,
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                // TERMS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (v) {
                          setState(() {
                            isChecked = v ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: "By clicking, I accept the ",
                            style: TextStyle(
                              color: AppColors.textBox,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: "Terms & Conditions",
                                style: TextStyle(
                                  color: AppColors.secondarycolor,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _navigateTo(CommonScreen('https://gocarriage.com/terms-condition','Terms & Conditions'));
                                    print("Terms & Conditions clicked");
                                  },
                              ),
                              TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy",
                                style: TextStyle(
                                  color: AppColors.secondarycolor,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _navigateTo(CommonScreen('https://gocarriage.com/privacy-policy','Privacy Policy'));
                                    print("Privacy clicked");
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // REGISTER TEXT
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textBox,
                      ),
                      children: [
                        TextSpan(
                          text: "Register Here",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.secondarycolor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  if (PrefUtils.getRole() == "customer") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => SignUpScreen(
                                            PrefUtils.getRole(),"Individual"
                                        ),
                                      ),
                                    );
                                  } else if (PrefUtils.getRole() == "driver") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => SignUpScreen(
                                          PrefUtils.getRole(),"Individual"
                                        ),
                                      ),
                                    );
                                  }else{
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => SelectionScreen(
                                          PrefUtils.getRole(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // SIGN-IN BUTTON
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondarycolor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _registerUser();
            },
            child:
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
