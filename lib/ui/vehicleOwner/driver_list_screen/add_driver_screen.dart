import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/provider_service/driver_update_profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../provider_service/add_driver_provider.dart';
import '../../../provider_service/email_verify_otp_provider.dart';
import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/file_upload_provider.dart';
import '../../../provider_service/profile_provider.dart';
import '../../../provider_service/send_otp_email_provider.dart';
import '../../../provider_service/signup_provider.dart';
import '../../../provider_service/vehicle_type_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------- CONTROLLERS ------------------------
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _experienceController = TextEditingController();
  final drivingLicenseController = TextEditingController();

  final List<TextEditingController> mobileOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<TextEditingController> emailOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // ---------------------- IMAGES ------------------------
  File? driversLicenseUploadFile;
  File? profile_pictureFile;

  String? license_from_date;
  String? license_to_date;
  String? driversLicenseUploadUrl;
  String? profile_pictureUrl;
  String _verificationId = '';

  String? service;

  bool isLoading = false;
  bool isProfileLoading = false;
  bool isLicenseLoading = false;

  bool isLoadingEmail = false;
  bool isEmailOtpSent = false;
  bool isLoadingEmailOtp = false;
  bool isEmailVerified = false;

  bool isMobileOtpSent = false;
  bool isMobileVerified = false;
  bool isLoadingMobile = false;
  bool isLoadingMobileOtp = false;

  List<String> selected = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<VehicleTypeProvider>(context, listen: false);
      await provider.fetchVehicleType();
    });
  }

  // ---------------------- PICK IMAGE ------------------------
  Future<void> showUploadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  LinearProgressIndicator(minHeight: 8),
                  SizedBox(height: 16),
                  Text("Wait we are uploading your documents"),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _fileUpload(
    String folderName,
    File? fileName,
    String mType,
  ) async {
    if (fileName == null) return;

    showUploadingDialog(context);

    final response = await Provider.of<FileUploadProvider>(
      context,
      listen: false,
    ).uploadFileOnServer(folder: folderName, mFile: fileName);

    if (!mounted) return;
    Navigator.pop(context);

    if (response != null && response['success'] == true) {
      final message = response['message'] ?? 'File uploaded successfully';
      final fileKey = response['data']?['key'];

      setState(() {
        if (mType == "Profile Photo") {
          profile_pictureUrl = fileKey;
        } else if (mType == "License") {
          driversLicenseUploadUrl = fileKey;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else {
      final message = response?['message'] ?? 'Upload failed';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> pickImage(Function(File file) onPicked, String fileType) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      onPicked(file);
      _fileUpload('drivers', file, fileType);
    }
  }

  // ---------------------- UPLOAD IMAGE BOX ------------------------
  Widget buildUploadBox(
    String label,
    File? localFile,
    String? url,
    Function(File) callback,
    bool isLoading, // ← Individual loading
    Function(bool) setLoading, // ← Callback to update loading
  ) {
    final safeUrl =
        (url != null && url.isNotEmpty) ? Uri.encodeFull(url) : null;
    print("RanjeetTest SAFE ===============>${safeUrl}");

    return GestureDetector(
      onTap: () => pickImage(callback, label),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: AppColors.primaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (localFile != null)
                    Text(
                      localFile.path.split('/').last,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    )
                  else if (safeUrl != null)
                    Text(
                      safeUrl.split('/').last,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    )
                  else
                    Column(
                      children: const [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "(Max 25 MB)",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Eye Icon - Only shows for existing uploaded files
            if (safeUrl != null)
              Positioned(
                bottom: 20,
                left: 8,
                child: GestureDetector(
                  onTap: () => _showImage(safeUrl, setLoading),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Icons.remove_red_eye,
                              color: Colors.white,
                              size: 18,
                            ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Updated to accept specific loading state
  Future<void> _showImage(String fileName, Function(bool) setLoading) async {
    setLoading(true);

    http.Response response = await Provider.of<FetchImageUrlProvider>(
      context,
      listen: false,
    ).fetchImagePath(fileName);

    var responseData = json.decode(response.body);

    setLoading(false);

    if (responseData['success'] == true) {
      final safeUrl = responseData['data']?['url'];
      if (safeUrl != null) {
        showImagePreview(context, safeUrl);
      }
    } else {
      final message = responseData?['message'] ?? 'Image fetch failed';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void showImagePreview(BuildContext context, String imageUrl) {
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85), // Darker elegant overlay
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05, // 5% margin from sides
              vertical: size.height * 0.1, // 10% from top & bottom
            ),
            child: Container(
              width: size.width * 0.9,
              // 90% of screen width
              height: size.height * 0.75,
              // 75% of screen height (you can adjust)
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Main Image with Interactive Zoom
                    InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.white70,
                                    size: 60,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Failed to load image",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Top Bar with Title & Close Button
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Preview",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Optional: Bottom indicator
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Pinch to zoom • Drag to move",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // ---------------------- UPDATE PROFILE ------------------------
  void addDriverService(String mDriverId) async {

    try {
      await AddDriverProvider().driverInformation(
        fullName: _nameController.text,
        email: _emailController.text,
        mobileNo: _mobileController.text,
        licenseNumber: drivingLicenseController.text,
        license_expiry_date: license_to_date!,
        license_from_date: license_from_date!,
        experience_in_yrs: _experienceController.text,
        vehicle_type_preference: selected.toString(),
        service_type: service!,
        driversLicenseUpload: driversLicenseUploadUrl!,
        profile_picture: profile_pictureUrl!,
        driverId: mDriverId,
      );

      Navigator.pop(context); // close dialog
      setState(() => isLoading = false);

      if (!mounted) return;

      final message =
          Provider.of<AddDriverProvider>(context, listen: false).message;

      setState(() => isLoading = false);

      if (message == 'Driver updated successfully') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    }
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
    print("📤 Sending OTP to: +91${_mobileController.text}");

    setState(() => isLoadingMobile = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: "+91${_mobileController.text}",

        verificationCompleted: (PhoneAuthCredential credential) async {
          print("✅ Auto verification completed");
          print("Credential: $credential");

          await _auth.signInWithCredential(credential);

          print("🎉 Auto sign-in success");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Auto sign-in complete")),
          );

          setState(() => isLoadingMobile = false);
        },

        verificationFailed: (FirebaseAuthException e) {
          print("❌ Verification failed");
          print("Error Code: ${e.code}");
          print("Error Message: ${e.message}");

          String errorMessage;

          if (e.code == 'invalid-phone-number') {
            errorMessage = "The phone number is not valid.";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Too many attempts. Please try again later.";
          } else {
            errorMessage = "Verification failed: ${e.message}";
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));

          setState(() => isLoadingMobile = false);
        },

        codeSent: (String verificationId, int? resendToken) {
          print("📩 OTP Sent");
          print("Verification ID: $verificationId");
          print("Resend Token: $resendToken");

          setState(() {
            Utils.showSuccessMessage(context, "Mobile OTP sent");
            _verificationId = verificationId;
            isLoadingMobile = false;
            isMobileOtpSent = true;
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("OTP sent")));
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          print("⏳ Auto retrieval timeout");
          print("Verification ID: $verificationId");

          _verificationId = verificationId;
          setState(() => isLoadingMobile = false);
        },

        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print("🔥 Exception occurred while sending OTP: $e");

      setState(() => isLoadingMobile = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong: $e")));
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

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      print("🔐 Creating credential with:");
      print("Verification ID: $_verificationId");

      final userCredential = await _auth.signInWithCredential(credential);

      print("✅ OTP Verified Successfully");
      print("User: ${userCredential.user}");

      setState(() {
        isLoadingMobileOtp = false;
        isMobileVerified = true;
        isMobileOtpSent = false;
      });
    } catch (e) {
      print("❌ OTP Verification Failed: $e");

      setState(() => isLoadingMobileOtp = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to verify OTP: $e")));
    }
  }

  // ---------------- REGISTER ----------------

  Future<void> _registerUser() async {
    if (_nameController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your  first name');
      return;
    }
   if (!isEmailVerified || !isMobileVerified) {
      Utils.showErrorMessage(context, "Please verify Email and Mobile number");
      return;
    } else if (_passwordController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your  password');
      return;
    } else if (_confirmPasswordController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter Re-password');
      return;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      Utils.showErrorMessage(context, 'Password does not match');
      return;
    }
    setState(() => isLoading = true);

    try {
      final response = await Provider.of<SignupProvider>(
        context,
        listen: false,
      ).signup(
        'driver',
        _nameController.text.trim(),
        _emailController.text.trim(),
        _mobileController.text.trim(),
        _passwordController.text.trim(),
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        addDriverService(data['driver']['id'].toString());
      } else {
        Utils.showErrorMessage(context, data['message']);
      }
    } catch (e) {
      Utils.showErrorMessage(context, e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendOtpOnEmail() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Driver',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Add this
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Personal Information
                sectionTitle("Personal Information"),
                textField("Full Name", _nameController, Icons.person),
                _label("Email Address *"),
                _emailSection(),

                _label("Mobile Number *"),
                _mobileSection(),

                _label("Password *"),
                _passwordField(),

                _label("Confirm Password *"),
                _confirmPasswordField(),
                const SizedBox(height: 10),
                // Identity Verification
                sectionTitle("Identity Verification"),
                textField(
                  "Enter experience",
                  _experienceController,
                  Icons.car_crash_rounded,
                  formatters: [UpperCaseTextFormatter()],
                ),
                SizedBox(height: 10),
                textField(
                  "Driving License Number",
                  drivingLicenseController,
                  Icons.badge,
                  formatters: [UpperCaseTextFormatter()],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: date(
                        "From",
                        license_from_date,
                        (v) => license_from_date = v,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: date(
                        "To",
                        license_to_date,
                        (v) => license_to_date = v,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                radioRow(
                  "Service Type *",
                  ["Within City", "Outside City"],
                  service,
                  (v) => setState(() => service = v),
                ),
                const SizedBox(height: 10),
                sectionTitle("Vehicle Type Preference*"),
                Consumer<VehicleTypeProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            provider.vehicleTypes.map((type) {
                              final String typeId =
                                  type.id?.toString() ?? ''; // Safe conversion
                              final bool isSelected = selected.contains(typeId);

                              return ChoiceChip(
                                key: ValueKey(typeId),
                                // Important for proper rebuild
                                label: Text(type.name ?? 'Unknown'),
                                selected: isSelected,
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      if (!selected.contains(typeId)) {
                                        selected.add(typeId);
                                      }
                                    } else {
                                      selected.remove(typeId);
                                    }
                                  });
                                },
                                selectedColor: Colors.teal.shade100,
                                backgroundColor: Colors.grey.shade200,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.teal.shade800
                                          : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? Colors.teal
                                            : Colors.grey.shade400,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Document Uploads
                sectionTitle("Document Uploads"),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    buildUploadBox(
                      "Profile Photo",
                      profile_pictureFile,
                      profile_pictureUrl,
                      (f) => setState(() => profile_pictureFile = f),
                      isProfileLoading,
                      (loading) => setState(() => isProfileLoading = loading),
                    ),

                    buildUploadBox(
                      "License",
                      driversLicenseUploadFile,
                      driversLicenseUploadUrl,
                      (f) => setState(() => driversLicenseUploadFile = f),
                      isLicenseLoading,
                      (loading) => setState(() => isLicenseLoading = loading),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Update Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                      isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "Add Driver",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
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

  Widget date(String label, String? value, Function(String) onPick) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: value ?? ""),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        DateTime? d = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );
        setState(() {
          if (d != null) onPick(DateFormat("yyyy-MM-dd").format(d));
        });
      },
    );
  }

  // Header

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(t),
  );

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

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget textField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget radioRow(
    String label,
    List<String> options,
    String? group,
    Function(String) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text(label),
        Row(
          children:
              options.map((e) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(e),
                    child: Container(
                      margin: EdgeInsets.all(4),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            group == e
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                          ),
                          SizedBox(width: 6),
                          Text(e),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget text(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(t, style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

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

  InputDecoration _dec(String h) =>
      InputDecoration(hintText: h, border: OutlineInputBorder());

  Widget _emailSection() => Column(
    children: [
      TextFormField(
        controller: _emailController,
        enabled: !isEmailVerified,
        decoration: _dec("Enter email").copyWith(
          suffixIcon:
              (!isEmailVerified && _isValidEmail(_emailController.text))
                  ? TextButton(
                    onPressed: isEmailOtpSent ? null : sendOtpOnEmail,
                    child:
                        isLoadingEmail
                            ? CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            )
                            : Text(isEmailOtpSent ? "SENT" : "Send OTP"),
                  )
                  : null,
        ),
        onChanged: (_) => setState(() {}),
        validator: (v) => _isValidEmail(v!) ? null : "Invalid email",
      ),
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
            onPressed: () {
              _verifyEmailOtp();
            },
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
      if (isEmailVerified)
        const Text("✔ Email Verified", style: TextStyle(color: Colors.green)),
    ],
  );

  Widget _mobileSection() => Column(
    children: [
      TextFormField(
        controller: _mobileController,
        keyboardType: TextInputType.phone,
        enabled: !isMobileVerified,
        decoration: _dec("Enter mobile").copyWith(
          suffixIcon:
              (!isMobileVerified && _mobileController.text.length == 10)
                  ? TextButton(
                    onPressed: isMobileOtpSent ? null : _sendMobileOtp,
                    child:
                        isLoadingMobile
                            ? CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            )
                            : Text(isMobileOtpSent ? "SENT" : "Send OTP"),
                  )
                  : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
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
            onPressed: () {
              _verifyMobileOtp();
            },
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
      if (isMobileVerified)
        const Text("✔ Mobile Verified", style: TextStyle(color: Colors.green)),
    ],
  );
}

// Uppercase Formatter
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
