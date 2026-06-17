import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gocarriage_universal/provider_service/verify_otp_provider..dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../provider_service/email_verify_otp_provider.dart';
import '../../provider_service/send_otp_email_provider.dart';
import '../../provider_service/send_otp_provider.dart';
import '../../provider_service/signup_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import 'package:http/http.dart' as http;

import '../../resource/shared_preferences.dart';
import '../dashboardScreen/customer_bottom_navigation_bar.dart';
import '../driver/home_screen/driver_bottom_navigationBar.dart';
import '../operatorScreen/operator_bottom_navigationbar.dart';
import '../vehicleOwner/home_screen/dashboard_vehicle_owner_screen.dart';

class SignUpScreen extends StatefulWidget {
  final String? mAccountType;
  final String? mMode;

  SignUpScreen(this.mAccountType, this.mMode);

  @override
  State<SignUpScreen> createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _locationController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ifcCodeController = TextEditingController();

  bool isLoading = false;
  bool isLoadingEmail = false;
  bool isLoadingEmailOtp = false;
  bool isLoadingMobile = false;
  bool isLoadingMobileOtp = false;

  bool isGettingLocation = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  // OTP state
  bool isEmailOtpSent = false;
  bool isEmailVerified = false;
  bool isMobileOtpSent = false;
  bool isMobileVerified = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  String? selectedLicense;

  String? phoneVerificationToken;
  String? registered_time_lat;
  String? registered_time_long;
  String? location_accuracy;

  final List<String> licenseTypes = [
    'LMV - Light Motor Vehicle (Car)',
    'MCWG - Motorcycle with Gear',
    'MCWOG - Motorcycle without Gear',
    'HMV - Heavy Motor Vehicle (Truck/Bus)',
    'LMV + MCWG',
    'Transport Vehicle',
    'PSV - Public Service Vehicle',
    'Hazardous Goods',
    'Other',
  ];

  // 6-digit OTP controllers
  final List<TextEditingController> emailOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> mobileOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  String? city;
  String? state;

  @override
  void initState() {
    super.initState();
    print("RanjeetTest ============>${PrefUtils.getRole()}");
    print("RanjeetTest ============>${widget.mMode}");
    if(PrefUtils.getFcmToken().isEmpty){
      getToken();
    }
    Future.microtask(() => _setCurrentLocation());
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

  // ---------------- LOCATION ----------------

  Future<void> _setCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
      _locationController.text = "Fetching location...";
    });

    if (!await Geolocator.isLocationServiceEnabled()) {
      _resetLocation();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _resetLocation();
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    setState(() {
       registered_time_lat = position.latitude.toString();
       registered_time_long = position.longitude.toString();
       location_accuracy = position.accuracy.toString();

      _locationController.text = "${placemarks.first.name}, ${placemarks.first.locality}";
      city = placemarks.first.locality ?? "";
      state = placemarks.first.administrativeArea ?? "";
      isGettingLocation = false;
    });
  }

  void _resetLocation() {
    setState(() {
      _locationController.clear();
      isGettingLocation = false;
    });
  }

  // ---------------- OTP LOGIC ----------------

  Future<void> _verifyEmailOtp() async {
    final otp = emailOtpControllers.map((e) => e.text).join();
    if (otp.length != 6) {
      Utils.showErrorMessage(context, "Enter valid 6 digit Email OTP");
      return;
    }
    setState(() {
      isLoadingEmailOtp = true;
    });
    http.Response response = await Provider.of<EmailVerifyOtpProvider>(
      context,
      listen: false,
    ).verifyOtpEmail(_emailController.text, otp);
    var responseData = json.decode(response.body);
    setState(() {
      isLoadingEmailOtp = false;
    });

    if (responseData['success'] == true) {
      setState(() {
        isEmailVerified = true;
        isEmailOtpSent = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
    } else {
      setState(() {
        isLoadingEmailOtp = false;
      });
      String errorMessage =
          responseData['message'] ?? 'Email OTP failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }

  Future<void> _sendMobileOtp() async {
    if (_mobileController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your mobile or email');
      return;
    }
    setState(() {
      isLoadingMobile = true;
    });

    http.Response response = await Provider.of<SendOtpProvider>(
      context,
      listen: false,
    ).sendOtp(_mobileController.text.trim());
    var responseData = json.decode(response.body);
    setState(() {
      isLoadingMobile = false;
    });

    if (response.statusCode == 200 && responseData['success'] == true) {
      setState(() {
       /* _secondsRemaining = int.parse(
          responseData['data']['expiresIn'].replaceAll(RegExp(r'[^0-9]'), ''),
        );*/
        isMobileOtpSent = true;
        isLoadingMobile = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
    } else {
      setState(() => isLoadingMobile = false);
      String errorMessage =
          responseData['message'] ?? 'get otp in failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }

  Future<void> _verifyMobileOtp() async {
    final otp = mobileOtpControllers.map((e) => e.text).join();

    print("📥 Entered OTP: $otp");

    if (otp.length != 6) {
      print("⚠️ Invalid OTP length");
      Utils.showErrorMessage(context, "Enter valid 6 digit Mobile OTP");
      return;
    }

    setState(() => isLoadingMobileOtp = true);

    http.Response response = await Provider.of<VerifyOtpProvider>(
      context,
      listen: false,
    ).verifyOtp(_mobileController.text.trim(), otp);
    var responseData = json.decode(response.body);
    setState(() {
      isLoadingMobileOtp = false;
    });

    if (responseData['success'] == true) {
      setState(() {
        phoneVerificationToken=responseData['data']['phoneVerificationToken'];
        isLoadingMobileOtp = false;
        isMobileVerified = true;
        isMobileOtpSent = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
    } else {
      setState(() => isLoadingMobileOtp = false);
      String errorMessage =
          responseData['message'] ?? 'get otp in failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
    }
  }

  // ---------------- REGISTER ----------------

  Future<void> _registerUser() async {
    final role = PrefUtils.getRole();
    final versionNumber = await Utils.getVersionNumber();

    /// ---------------- VALIDATIONS ----------------
    if (role == "Vehicle Owner" && widget.mMode == "Company" && _companyNameController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your company name');
      return;
    }

    if (_nameController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your first name');
      return;
    }

    if (!isMobileVerified) {
      Utils.showErrorMessage(
        context,
        "Please verify your Mobile number first",
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your password');
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter Re-password');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Utils.showErrorMessage(context, 'Password does not match');
      return;
    }

    if (role == "driver" && selectedLicense == null) {
      Utils.showErrorMessage(context, 'Please select your license');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await Provider.of<SignupProvider>(
        context,
        listen: false,
      ).signup(
        type: role,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _mobileController.text.trim(),
        password: _passwordController.text.trim(),
        referralCode: _referralCodeController.text.trim(),
        phoneVerificationToken: "phoneVerificationToken"!,

        address: role == "driver" ? "" : _locationController.text.trim(),
        city: role == "driver" ? "" : (city ?? ""),
        state: role == "driver" ? "" : (state ?? ""),
        pincode: role == "driver" ? "" : _pinCodeController.text.trim(),

        selectedLicense: role == "driver" ? (selectedLicense ?? '') : "",
        mode: (role == "owner" || role == "operator") ? (widget.mMode ?? "") : "",

        bankName: role == "owner" ? _bankNameController.text.trim() : "",
        accountNumber: role == "owner" ? _accountNoController.text.trim() : "",
        ifscCode: role == "owner" ? _ifcCodeController.text.trim() : "",
        companyName: role == "owner" ? _companyNameController.text.trim() : "",

        /// optional fields (safe to skip or pass null)
        registered_time_lat: registered_time_lat,
        registered_time_long: registered_time_long,
        location_accuracy: location_accuracy,
        device_id: PrefUtils.getFcmToken(),
        device_type: Utils.getDeviceType(),
        app_version: versionNumber,
        registration_source: Utils.getDeviceType(),
      );


      final responseData = json.decode(response.body);

      /// ---------------- SUCCESS ----------------
      if (responseData['success'] == true) {
        final data = responseData['data'];

        PrefUtils.setToken(data['token']);

        final userRole = data['user']['role'];

        PrefUtils.setRole(userRole);

        if (userRole == 'driver') {
          PrefUtils.setUserId(data["driver"]["id"].toString());
          PrefUtils.setEmail(data["driver"]["email"] ?? '');
          PrefUtils.setName(data["driver"]["fullName"]);
          PrefUtils.setMobile(data["driver"]["mobileNo"] ?? '');
        }
        else if (userRole == 'operator') {
          PrefUtils.setUserId(data["operator"]["id"].toString());
          PrefUtils.setEmail(data["user"]["email"] ?? '');
          PrefUtils.setName(data["operator"]["ownerName"]);
        }
        else if (userRole == 'customer') {
          PrefUtils.setUserId(data["customer"]["id"].toString());
          PrefUtils.setEmail(data["customer"]["email"] ?? '');
          PrefUtils.setMobile(data["customer"]["phone"] ?? '');
          PrefUtils.setName(data["customer"]["customerName"]);
        }
        else if (userRole == 'owner') {
          PrefUtils.setUserId(data["owner"]["id"].toString());
          PrefUtils.setEmail(data["user"]["email"] ?? '');
          PrefUtils.setName(data["owner"]["ownerName"]);
        }

        PrefUtils.setLoggedIn(true);
        PrefUtils.setFirstTime(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );

        _sendOTP();
      }
      else {
        Utils.showErrorMessage(context, responseData['message']);
      }
    } catch (e) {
      print("RanjeetTest=========${e.toString()}");
      Utils.showErrorMessage(context, e.toString());
    } finally {
      setState(() => isLoading = false);
    }
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

  Future<void> sendOtpOnEmail() async {
    if (_formKey.currentState!.validate()) {
      if (_emailController.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter your  email');
        return;
      }
      setState(() {
        isLoadingEmail = true;
      });

      http.Response response = await Provider.of<SendOtpEmailProvider>(
        context,
        listen: false,
      ).sentOtpEmail(_emailController.text);
      var responseData = json.decode(response.body);
      setState(() {
        isLoadingEmail = false;
      });

      if (responseData['success'] == true) {
        setState(() => isEmailOtpSent = true);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData['message'])));
      } else {
        setState(() {
          isLoadingEmail = false;
        });
        String errorMessage =
            responseData['message'] ?? 'Email OTP failed. Please try again.';
        Utils.showErrorMessage(context, errorMessage);
      }
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    bool isCompanyUser = (PrefUtils.getRole() == "owner" || PrefUtils.getRole() == "operator") && widget.mMode == "Company";
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: const Text("Register"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isCompanyUser ? _label("Company Name *") : SizedBox(),
              isCompanyUser ? _textField(_companyNameController, "Enter company name") : SizedBox(),

              _label("Full Name *"),
              _textField(_nameController, "Enter full name"),

              _label("Email Address"),
              _emailSection(),

              _label("Mobile Number *"),
              _mobileSection(),

              _label("Password *"),
              _passwordField(),

              _label("Confirm Password *"),
              _confirmPasswordField(),
              if (PrefUtils.getRole() == "driver") ...[
                SizedBox(height: 20,),
                DropdownButtonFormField<String>(
                  value: selectedLicense,
                  decoration: InputDecoration(
                    labelText: 'Driving License Type',
                    hintText: 'Select DL Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.directions_car),
                  ),
                  icon: const Icon(Icons.arrow_drop_down_circle),
                  isExpanded: true,
                  items:
                  licenseTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedLicense = newValue;
                    });
                    print('Selected Driving License: $newValue');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select driving license type';
                    }
                    return null;
                  },
                ),
              ],
              _label("Referral Code (optional)"),
              _textField1(_referralCodeController, "Enter referral code"),
              if (PrefUtils.getRole() != "driver" &&
                  PrefUtils.getRole() != "owner" &&
                  PrefUtils.getRole() != "operator") ...[
                _label("Address *"),
                _addressField(),
                _label("Pin Code *"),
                _pinField(),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
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
                      "Create Account",
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

  // ---------------- HELPERS ----------------

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(t),
  );

  InputDecoration _dec(String h) =>
      InputDecoration(hintText: h, border: OutlineInputBorder());

  Widget _textField(TextEditingController c, String h) => TextFormField(
    controller: c,
    decoration: _dec(h),
    validator: (v) => v!.isEmpty ? "Required" : null,
  );

  Widget _textField1(TextEditingController c, String h) =>
      TextFormField(controller: c, decoration: _dec(h));

  Widget _passwordField() => TextFormField(
    controller: _passwordController,
    obscureText: true,
    decoration: _dec("Password"),
  );

  Widget _confirmPasswordField() => TextFormField(
    controller: _confirmPasswordController,
    obscureText: true,
    decoration: _dec("Confirm Password"),
  );

  Widget _addressField() => TextFormField(
    controller: _locationController,
    readOnly: true,
    decoration: _dec("Location").copyWith(
      suffixIcon: IconButton(
        icon: const Icon(Icons.my_location),
        onPressed: _setCurrentLocation,
      ),
    ),
  );

  Widget _pinField() => TextFormField(
    controller: _pinCodeController,
    decoration: _dec("Pin Code"),
  );

  // ---------------- OTP UI ----------------

  Widget _otpBoxes(List<TextEditingController> controllers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: controllers[i],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              counterText: "",
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < 5) {
                FocusScope.of(context).nextFocus();
              }
              if (v.isEmpty && i > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _emailSection() => Column(
    children: [
      TextFormField(
        controller: _emailController,
        enabled: !isEmailVerified,
        decoration: _dec("Enter email").copyWith(
          /* suffixIcon:
              (!isEmailVerified && _isValidEmail(_emailController.text))
                  ? TextButton(
                    onPressed:
                        isLoadingEmail ||
                                (isEmailOtpSent && _secondsRemaining > 0)
                            ? null
                            : () {
                              sendOtpOnEmail();
                              _startCountdown();
                            },
                    child:
                        isLoadingEmail
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              isEmailOtpSent
                                  ? (_secondsRemaining > 0
                                      ? "Resend ($_secondsRemaining)"
                                      : "Resend")
                                  : "Send OTP",
                            ),
                  )
                  : null,*/
        ),
        onChanged: (_) => setState(() {}),
        //validator: (v) => _isValidEmail(v!) ? null : "Invalid email",
      ),

      /// OTP SECTION
      if (isEmailOtpSent && !isEmailVerified) ...[
        const SizedBox(height: 10),
        _otpBoxes(emailOtpControllers),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondarycolor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _verifyEmailOtp,
            child:
                isLoadingEmailOtp
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      "Confirm Email OTP",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ],

      /// VERIFIED SECTION WITH CHANGE OPTION
      if (isEmailVerified)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "✔ Email Verified",
              style: TextStyle(color: Colors.green),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isEmailVerified = false;
                  isEmailOtpSent = false;
                  _secondsRemaining = 0;

                  // optional: keep or clear email
                  // _emailController.clear();

                  for (var c in emailOtpControllers) {
                    c.clear();
                  }
                });
              },
              child: const Text("Change"),
            ),
          ],
        ),
    ],
  );

  Widget _mobileSection() => Column(
    children: [
      TextFormField(
        controller: _mobileController,
        keyboardType: TextInputType.number,
        // better than phone
        enabled: !isMobileVerified,

        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // only numbers
          LengthLimitingTextInputFormatter(10), // max 10 digit
        ],

        decoration: _dec("Enter mobile").copyWith(
          suffixIcon:
              (!isMobileVerified && _mobileController.text.length == 10)
                  ? TextButton(
                    onPressed:
                        isLoadingMobile ||
                                (isMobileOtpSent && _secondsRemaining > 0)
                            ? null
                            : () {
                              _sendMobileOtp();
                              _startCountdown();
                            },
                    child:
                        isLoadingMobile
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            )
                            : Text(
                              isMobileOtpSent
                                  ? (_secondsRemaining > 0
                                      ? "Resend ($_secondsRemaining)"
                                      : "Resend")
                                  : "Send OTP",
                            ),
                  )
                  : null,
        ),
        onChanged: (_) => setState(() {}),
      ),

      /// OTP SECTION
      if (isMobileOtpSent && !isMobileVerified) ...[
        const SizedBox(height: 10),
        _otpBoxes(mobileOtpControllers),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondarycolor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _verifyMobileOtp,
            child:
                isLoadingMobileOtp
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      "Confirm Mobile OTP",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ],

      /// VERIFIED SECTION WITH CHANGE OPTION
      if (isMobileVerified)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "✔ Mobile Verified",
              style: TextStyle(color: Colors.green),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isMobileVerified = false;
                  isMobileOtpSent = false;
                  _secondsRemaining = 0;

                  // optional: clear or keep number
                  // _mobileController.clear();

                  for (var c in mobileOtpControllers) {
                    c.clear();
                  }
                });
              },
              child: const Text("Change"),
            ),
          ],
        ),
    ],
  );

  void _startCountdown() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });

    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
