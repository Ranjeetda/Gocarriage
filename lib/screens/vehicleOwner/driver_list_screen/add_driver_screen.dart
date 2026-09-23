import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../provider_service/add_driver_provider.dart';
import '../../../provider_service/assign_driver_provider.dart';
import '../../../provider_service/email_verify_otp_provider.dart';
import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/file_upload_provider.dart';
import '../../../provider_service/send_otp_email_provider.dart';
import '../../../provider_service/send_otp_provider.dart';
import '../../../provider_service/signup_provider.dart';
import '../../../provider_service/vehicle_type_provider.dart';
import '../../../provider_service/verify_otp_provider..dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/pref_utils.dart';
import '../../widgets/shared_widgets.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final picker = ImagePicker();

  // ---------------------- CONTROLLERS ------------------------
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _experienceController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  String selectedLicense = 'LMV - Light Motor Vehicle (Car)';
  String? phoneVerificationToken;
  String? registered_time_lat;
  String? registered_time_long;
  String? location_accuracy;

  final List<TextEditingController> mobileOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<TextEditingController> emailOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // ---------------------- IMAGES ------------------------
  File? licenseFrontFile;
  File? profilePhotoFile;

  String? license_from_date;
  String? license_to_date;
  String? licenseFrontUrl;
  String? profilePhotoUrl;
  int _secondsRemaining = 0;
  Timer? _timer;

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
    Future.microtask(() => _setCurrentLocation());
  }

  Future<void> _setCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      registered_time_lat = position.latitude.toString();
      registered_time_long = position.longitude.toString();
      location_accuracy = position.accuracy.toString();
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
          profilePhotoUrl = fileKey;
        } else if (mType == "License Document") {
          licenseFrontUrl = fileKey;
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

  void pickImage(Function(File file) onPicked, String fileType) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromSource(ImageSource.camera, onPicked, fileType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromSource(ImageSource.gallery, onPicked, fileType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromSource(
    ImageSource source,
    Function(File file) onPicked,
    String fileType,
  ) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      onPicked(file); // Update local state to show filename
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

  String _unmapLicenseType(String? label) {
    if (label == null) return 'HMV';
    if (label.contains('LMV')) return 'LMV';
    if (label.contains('HMV')) return 'HMV';
    if (label.contains('MCWG')) return 'MCWG';
    if (label.contains('MCWOG')) return 'MCWOG';
    if (label.contains('Transport')) return 'TRANSPORT';
    if (label.contains('PSV')) return 'PSV';
    if (label.contains('Hazardous')) return 'HAZARDOUS';
    return 'OTHER';
  }

  // ---------------------- UPDATE PROFILE ------------------------
  void addDriverService(String mDriverId) async {
    try {
      final response = await AddDriverProvider().driverInformation(
        fullName: _nameController.text,
        email: _emailController.text,
        mobileNo: _mobileController.text,
        licenseNumber: drivingLicenseController.text,
        license_expiry_date: license_to_date!,
        license_from_date: license_from_date!,
        experience_in_yrs: _experienceController.text,
        vehicle_type_preference: selected.toString(),
        service_type: service == 'Within City' ? 'in_city' : 'out_city',
        driversLicenseUpload: licenseFrontUrl!,
        profile_picture: profilePhotoUrl!,
        driverId: mDriverId,
        license_type: _unmapLicenseType(selectedLicense),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      final bool success = response?['success'] == true;
      final String message =
          response?['message']?.toString() ??
          (success ? 'Driver updated' : 'Update failed');
      final Map<String, dynamic>? driverData =
          response?['data'] as Map<String, dynamic>?;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      if (success && driverData != null) {
        debugPrint("Updated driver id: ${driverData['id']}");
        debugPrint("Verification status: ${driverData['verificationStatus']}");
        _assignDriver(driverData['id'].toString());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    }
  }

  Future<void> _assignDriver(String? driverId) async {
    if (driverId == null) {
      Utils.showErrorMessage(context, "Please select Driver");
      return;
    }
    setState(() {
      isLoading = true;
    });
    http.Response response = await Provider.of<AssignDriverProvider>(
      context,
      listen: false,
    ).assignDriver(driverId);
    var responseData = json.decode(response.body);
    setState(() {
      isLoading = false;
    });

    if (responseData['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData['message'])));
      Navigator.pop(context);
    } else {
      setState(() {
        isLoading = false;
      });
      String errorMessage =
          responseData['message'] ?? 'Assign Driver failed. Please try again.';
      Utils.showErrorMessage(context, errorMessage);
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
        _secondsRemaining = int.parse(
          responseData['data']['expiresIn'].replaceAll(RegExp(r'[^0-9]'), ''),
        );
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
        phoneVerificationToken = responseData['data']['phoneVerificationToken'];
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
    final versionNumber = await Utils.getVersionNumber();

    /// ---------------- VALIDATION ----------------
    if (_nameController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your first name');
      return;
    }

    if (!isMobileVerified) {
      Utils.showErrorMessage(context, "Please verify Mobile number");
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

    if (selectedLicense.isEmpty) {
      Utils.showErrorMessage(context, 'Please select your license');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Provider.of<SignupProvider>(
        context,
        listen: false,
      ).signup(
        type: "driver",
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _mobileController.text.trim(),
        password: _passwordController.text.trim(),

        referralCode: _referralCodeController.text.trim(),
        phoneVerificationToken: "",

        // ⚠️ replace if you have real token
        address: "",
        city: "",
        state: "",
        pincode: "",

        selectedLicense: selectedLicense,
        mode: "",

        bankName: "",
        accountNumber: "",
        ifscCode: "",
        companyName: "",

        /// optional
        registered_time_lat: registered_time_lat,
        registered_time_long: registered_time_long,
        location_accuracy: location_accuracy,
        device_id: PrefUtils.getFcmToken(),
        device_type: Utils.getDeviceType(),
        app_version: versionNumber,
        registration_source: Utils.getDeviceType(),
      );

      final data = json.decode(response.body);

      /// ---------------- SUCCESS ----------------
      if (response.statusCode == 201) {
        addDriverService(data['data']['driver']['id'].toString());
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 18,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Add · driver',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Register a new driver to your fleet',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── PERSONAL INFORMATION ─────────────────
                  _sectionHeader(Icons.person_outline, 'PERSONAL INFORMATION'),
                  const SizedBox(height: 14),

                  CommonTextField(
                    hint: 'Enter full name',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    isRequired: true,
                    label: 'Full Name',
                  ),
                  const SizedBox(height: 10),

                  EmailSection(
                    emailController: _emailController,
                    otpControllers: emailOtpControllers,
                    isEmailVerified: isEmailVerified,
                    isEmailOtpSent: isEmailOtpSent,
                    isLoadingEmail: isLoadingEmail,
                    isLoadingEmailOtp: isLoadingEmailOtp,
                    secondsRemaining: _secondsRemaining,
                    isValidEmail: Utils.isEmail,
                    onSendOtp: () {
                      sendOtpOnEmail();
                      _startCountdown();
                    },
                    onVerifyOtp: _verifyEmailOtp,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 10),

                  MobileSection(
                    mobileController: _mobileController,
                    otpControllers: mobileOtpControllers,
                    isMobileVerified: isMobileVerified,
                    isMobileOtpSent: isMobileOtpSent,
                    isLoadingMobile: isLoadingMobile,
                    isLoadingMobileOtp: isLoadingMobileOtp,
                    secondsRemaining: _secondsRemaining,
                    onSendOtp: () {
                      _sendMobileOtp();
                      _startCountdown();
                    },
                    onVerifyOtp: _verifyMobileOtp,
                    onChanged: () => setState(() {}),
                    onChangeMobile: () {
                      setState(() {
                        isMobileVerified = false;
                        isMobileOtpSent = false;
                        _secondsRemaining = 0;
                        for (var c in mobileOtpControllers) {
                          c.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          hint: 'Enter password',
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          label: 'Password',
                          isRequired: true,
                          isObscure: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonTextField(
                          hint: 'Confirm password',
                          controller: _confirmPasswordController,
                          icon: Icons.lock_outline,
                          label: 'Confirm Password',
                          isRequired: true,
                          isObscure: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ── LICENSE DETAILS ──────────────────────
                  _sectionHeader(Icons.badge_outlined, 'LICENSE DETAILS'),
                  const SizedBox(height: 14),

                  CommonTextField(
                    hint: 'Enter Driving License Number',
                    controller: drivingLicenseController,
                    icon: Icons.card_membership_outlined,
                    label: 'Driving License Number',
                    isRequired: true,
                    formatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(16),
                    ],
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          hint: "Valid From",
                          label: "License Valid From",
                          controller: fromDateController,
                          icon: Icons.calendar_today_outlined,
                          isEditable: false,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              fromDateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(date);
                              license_from_date = fromDateController.text;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonTextField(
                          hint: "Valid Upto",
                          label: "License Valid Upto",
                          controller: toDateController,
                          icon: Icons.calendar_today_outlined,
                          isEditable: false,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              toDateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(date);
                              license_to_date = toDateController.text;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  CommonDropdown(
                    hint: 'Select License Category',
                    label: 'Driving License Type',
                    value: selectedLicense.isEmpty ? null : selectedLicense,
                    items: Utils.licenseTypes,
                    icon: Icons.directions_car_outlined,
                    isRequired: true,
                    onChanged:
                        (v) => setState(() => selectedLicense = v ?? ''),
                  ),

                  const SizedBox(height: 30),

                  // ── WORK DETAILS ─────────────────────────
                  _sectionHeader(
                    Icons.local_shipping_outlined,
                    'WORK DETAILS',
                  ),
                  const SizedBox(height: 14),

                  CommonTextField(
                    hint: 'Enter experience in years',
                    controller: _experienceController,
                    icon: Icons.history_outlined,
                    keyboard: TextInputType.number,
                    isRequired: true,
                    label: 'Experience (Years)',
                  ),
                  const SizedBox(height: 12),

                  radioRow(
                    "Service Type *",
                    ["Within City", "Outside City"],
                    service,
                    (v) => setState(() => service = v),
                  ),

                  const SizedBox(height: 30),

                  // ── DOCUMENT UPLOADS ─────────────────────
                  _sectionHeader(Icons.upload_file_outlined, 'DOCUMENT UPLOADS'),
                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      buildUploadBox(
                        "Profile Photo",
                        profilePhotoFile,
                        profilePhotoUrl,
                        (f) => setState(() => profilePhotoFile = f),
                        isProfileLoading,
                        (loading) => setState(() => isProfileLoading = loading),
                      ),
                      buildUploadBox(
                        "License Document",
                        licenseFrontFile,
                        licenseFrontUrl,
                        (f) => setState(() => licenseFrontFile = f),
                        isLicenseLoading,
                        (loading) => setState(() => isLicenseLoading = loading),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ── SUBMIT BUTTON ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.person_add_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Add Driver",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.primaryColor,
          ),
        ),
      ],
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
        SectionTitle(title: label),
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
