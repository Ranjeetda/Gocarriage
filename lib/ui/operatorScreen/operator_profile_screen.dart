import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/email_verify_otp_provider.dart';
import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/file_upload_provider.dart';
import '../../../provider_service/owner_profile_update_provider.dart';
import '../../../provider_service/profile_provider.dart';
import '../../../provider_service/send_otp_email_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/aadhaar_input_formatter.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/pref_utils.dart';
import '../../../resource/upper_case_text_formatter.dart';
import 'package:http/http.dart' as http;

import '../../provider_service/operator_profile_update_provider.dart';

class OperatorProfileScreen extends StatefulWidget {
  const OperatorProfileScreen({super.key});

  @override
  State<OperatorProfileScreen> createState() => _OperatorProfileScreen();
}

class _OperatorProfileScreen extends State<OperatorProfileScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // ---------------------- CONTROLLERS ------------------------
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _contactPersonNameController = TextEditingController();
  final _contactPersonEmailController = TextEditingController();
  final _contactPersonPhoneController = TextEditingController();

  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  final aadhaarNumberController = TextEditingController();
  final panNumberController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final gstNumberController = TextEditingController();

  // Bank Controllers
  final bankNameController = TextEditingController();
  final bankAccountController = TextEditingController();
  final confirmAccountController = TextEditingController();
  final ifscController = TextEditingController();
  final branchAddressController = TextEditingController();

  // 6-digit OTP controllers
  final List<TextEditingController> emailOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // ---------------------- SECURE FIELD STATE ------------------------
  bool _obscureAccountNumber = true;
  bool _obscureConfirmAccountNumber = false;

  // ---------------------- IMAGES ------------------------
  File? profilePhotoFile;
  File? aadhaarFrontFile;
  File? licenseFrontFile;
  File? panDocumentFile;
  File? gstDocumentFile;
  File? cancelChequeFile;

  String? profilePhotoUrl;
  String? aadhaarFrontUrl;
  String? licenseFrontUrl;
  String? panDocumentUrl;
  String? gstCertificateUrl;
  String? cancelChequeUrl;

  bool isLoading = false;
  bool isProfileLoading = false;
  bool isAadhaarLoading = false;
  bool isLicenseLoading = false;
  bool isPanLoading = false;
  bool isGstLoading = false;
  bool isCancelChequeLoading = false;
  bool isLoadingEmailOtp = false;
  bool isLoadingEmail = false;

  bool isSameNumber = false;
  bool isEmailOtpSent = false;
  bool isEmailVerified = false;

  int _secondsRemaining = 0;
  Timer? _timer;

  void toggleCheckbox(bool? value) {
    setState(() {
      isSameNumber = value ?? false;
      if (isSameNumber) {
        _whatsappController.text = _phoneController.text;
      } else {
        _whatsappController.clear();
      }
    });
  }

  // ================= VALIDATORS =================
  bool isValidPAN(String value) =>
      RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value);

  bool isValidAadhaar(String value) => RegExp(r'^\d{12}$').hasMatch(value);

  bool isValidGST(String value) =>
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{3}$').hasMatch(value);

  bool isValidDL(String value) =>
      RegExp(r'^[A-Z]{2}[0-9]{2}\d{7,}$').hasMatch(value);

  bool isValidAccountNumber(String value) {
    return RegExp(r'^[0-9]{9,18}$').hasMatch(value);
  }

  bool isValidIFSC(String value) {
    return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value);
  }

  // ================= STEP VALID =================
  bool isStepValid() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _companyNameController.text.isNotEmpty &&
            _addressController.text.isNotEmpty &&
            _postalCodeController.text.isNotEmpty &&
            _cityController.text.isNotEmpty &&
            _stateController.text.isNotEmpty;

      case 2:
        return bankNameController.text.isNotEmpty &&
            bankAccountController.text.isNotEmpty &&
            confirmAccountController.text.isNotEmpty &&
            bankAccountController.text == confirmAccountController.text &&
            ifscController.text.isNotEmpty;
      default:
        return false;
    }
  }

  // ================== IMAGE PICKER & UPLOAD BOX ==================
  Future<void> pickImage(Function(File file) onPicked, String fileType) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      onPicked(file);
      _fileUpload('operators', file, fileType);
    }
  }

  Widget buildUploadBox(
    String label,
    File? localFile,
    String? url,
    Function(File) callback,
    bool isLoading,
    Function(bool) setLoading,
  ) {
    final safeUrl =
        (url != null && url.isNotEmpty) ? Uri.encodeFull(url) : null;

    return GestureDetector(
      onTap: () => pickImage(callback, label),
      child: Container(
        height: 175,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (localFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      localFile,
                      height: 85,
                      width: 85,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (safeUrl != null)
                  const Icon(Icons.check_circle, size: 50, color: Colors.green)
                else
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  "(Max 25 MB)",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            if (safeUrl != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showImage(safeUrl, setLoading),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryColor,
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
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

  // ================== FILE UPLOAD & PREVIEW (unchanged) ==================
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
      final fileKey = response['data']?['key'];
      setState(() {
        switch (mType) {
          case "Profile Photo":
            profilePhotoUrl = fileKey;
            break;
          case "PAN Document":
            panDocumentUrl = fileKey;
            break;
          case "GST Certificate":
            gstCertificateUrl = fileKey;
            break;
          case "License":
            licenseFrontUrl = fileKey;
            break;
          case "Aadhaar":
            aadhaarFrontUrl = fileKey;
            break;
          case "Upload Cancelled Cheque":
            cancelChequeUrl = fileKey;
            break;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Uploaded successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response?['message'] ?? 'Upload failed')),
      );
    }
  }

  Future<void> _showImage(String fileName, Function(bool) setLoading) async {
    setLoading(true);
    final response = await Provider.of<FetchImageUrlProvider>(
      context,
      listen: false,
    ).fetchImagePath(fileName);
    var responseData = json.decode(response.body);
    setLoading(false);

    if (responseData['success'] == true &&
        responseData['data']?['url'] != null) {
      showImagePreview(context, responseData['data']['url']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData?['message'] ?? 'Failed to load image'),
        ),
      );
    }
  }

  void showUploadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(minHeight: 8),
                  SizedBox(height: 16),
                  Text("Uploading your document..."),
                ],
              ),
            ),
          ),
    );
  }

  void showImagePreview(BuildContext context, String imageUrl) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.1,
            ),
            child: Container(
              width: size.width * 0.9,
              height: size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Image.network(imageUrl, fit: BoxFit.contain),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
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
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
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
          ),
    );
  }

  // ================== SET PROFILE DATA ==================
  void setProfileData(Map data) {
    _nameController.text = data["fullName"] ?? data["ownerName"] ?? "";
    _emailController.text = data["email"] ?? "";
    _phoneController.text = data["mobileNo"] ?? data['User']?["phone"] ?? "";
    _addressController.text = data["address"] ?? "";
    _addressLine2Controller.text = data["addressLine2"] ?? "";
    _cityController.text = data["city"] ?? "";
    _stateController.text = data["state"] ?? "";
    _postalCodeController.text = data["pinCode"] ?? data["postalCode"] ?? "";
    _whatsappController.text = data["whatsappNumber"] ?? "";
    _contactPersonNameController.text = data["contactPersonName"] ?? "";
    _contactPersonEmailController.text = data["contactPersonEmail"] ?? "";
    _contactPersonPhoneController.text = data["contactPersonPhone"] ?? "";
    _companyNameController.text = data["companyName"] ?? "";

    isSameNumber = (data['whatsappNumber'] == data['contactPersonPhone']);

    aadhaarNumberController.text = data["aadhaarNumber"] ?? "";
    panNumberController.text = data["panNumber"] ?? "";
    drivingLicenseController.text = data["drivingLicenceNumber"] ?? "";
    gstNumberController.text = data["gstNumber"] ?? "";

    bankNameController.text = data["bankName"] ?? "";
    bankAccountController.text = data["accountNumber"] ?? "";
    confirmAccountController.text = data["accountNumber"] ?? "";
    ifscController.text = data["ifscCode"] ?? "";
    branchAddressController.text = data["branchAddress"] ?? "";

    profilePhotoUrl = data["profile_pic"] ?? "";
    aadhaarFrontUrl = data["aadhaarUpload"] ?? "";
    panDocumentUrl = data["panUpload"] ?? "";
    licenseFrontUrl = data["drivingLicenceUpload"] ?? "";
    gstCertificateUrl = data["gstCertificateUpload"] ?? "";
    cancelChequeUrl = data["cancel_cheque"] ?? "";

    setState(() {});
  }

  // ================== UPDATE PROFILE ==================

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

  Future<void> sendOtpOnEmail() async {
    if (_formKey.currentState!.validate()) {
      if (_emailController.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter your  email');
        return;
      }
      _startCountdown();
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

  Future<void> _updateProfile() async {
    setState(() => isLoading = true);

    try {
      final response = await Provider.of<OperatorProfileUpdateProvider>(
        context,
        listen: false,
      ).updateProfile(
        ownerName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        companyName: _companyNameController.text.trim(),
        contactPersonName: _contactPersonNameController.text.trim(),
        contactPersonEmail: _contactPersonEmailController.text.trim(),
        contactPersonPhone: _contactPersonPhoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        address: _addressController.text.trim(),
        addressLine2: _addressLine2Controller.toString().trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        city: _cityController.text.trim(),
        panNumber: panNumberController.text.trim(),
        aadhaarNumber: aadhaarNumberController.text.trim(),
        gstNumber: gstNumberController.text.trim(),
        drivingLicenceNumber: drivingLicenseController.text.trim(),
        ifscCode: ifscController.text.trim(),
        bankName: bankNameController.text.trim(),
        accountNumber: bankAccountController.text.trim(),
        branchAddress: branchAddressController.text.trim(),
        panUpload: panDocumentFile != null ? (panDocumentUrl ?? '') : '',
        aadhaarUpload: aadhaarFrontFile != null ? (aadhaarFrontUrl ?? '') : '',
        gstCertificateUpload:
            gstDocumentFile != null ? (gstCertificateUrl ?? '') : '',
        drivingLicenceUpload:
            licenseFrontFile != null ? (licenseFrontUrl ?? '') : '',
      );

      setState(() => isLoading = false);

      /// ✅ Handle response
      final bool success = response['success'] ?? false;
      final String message = response['message'] ?? 'Profile update response';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      /// ✅ Optional: do something on success
      if (success) {
        // Navigate back or refresh UI
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      await provider.fetchProfile('owner', "owner", PrefUtils.getUserId());
      if (provider.profileData.isNotEmpty) setProfileData(provider.profileData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepCancel: () => setState(() => _currentStep -= 1),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text("Previous"),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: (!isStepValid() || isLoading) ? 0 : 4,
                        backgroundColor:
                            (!isStepValid() || isLoading)
                                ? Colors.grey.shade300
                                : AppColors.primaryColor,
                      ),
                      onPressed:
                          (!isStepValid() || isLoading)
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  if (_currentStep == 2) {
                                    _updateProfile();
                                  } else {
                                    setState(() => _currentStep += 1);
                                  }
                                }
                              },
                      child: Text(
                        _currentStep == 2 ? "Update" : "Next",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            // Personal Step (unchanged)
            Step(
              title: const Text("Personal"),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    sectionTitle('Full Name', isRequired: true),
                    textField("Enter full name", _nameController, Icons.person),
                    sectionTitle('Phone Number', isRequired: true),
                    textField(
                      "Phone Number",
                      _phoneController,
                      Icons.phone,
                      enabled: false,
                    ),
                    sectionTitle('Company Name', isRequired: true),
                    textField(
                      "Company Name",
                      _companyNameController,
                      Icons.holiday_village,
                      enabled: true,
                    ),
                    sectionTitle('Email Address', isRequired: false),
                    _emailSection(),
                    const SizedBox(height: 10),
                    const Text(
                      'Contact Person',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    sectionTitle('Contact person name', isRequired: true),
                    textField(
                      "Contact person name",
                      _contactPersonNameController,
                      Icons.man,
                      enabled: true,
                    ),
                    const SizedBox(height: 10),
                    sectionTitle('Contact person phone', isRequired: true),
                    textField(
                      "Contact person phone",
                      _contactPersonPhoneController,
                      Icons.phone,
                      enabled: true,
                    ),
                    const SizedBox(height: 10),
                    sectionTitle('Contact person email', isRequired: false),
                    textField(
                      "Contact person email",
                      _contactPersonEmailController,
                      Icons.email,
                      enabled: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: isSameNumber,
                          onChanged: toggleCheckbox,
                        ),
                        const Text(
                          "WhatsApp number same as phone number *",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    if (!isSameNumber) ...[
                      sectionTitle('WhatsApp Number', isRequired: false),
                      textField(
                        "Whatsapp Number",
                        _whatsappController,
                        FontAwesomeIcons.whatsapp,
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    sectionTitle('Address Line 1', isRequired: true),
                    textField(
                      "Enter address line 1",
                      _addressController,
                      Icons.location_on,
                    ),
                    sectionTitle('Address Line 2', isRequired: false),
                    textField(
                      "Apartment, suit, landmark (optional)",
                      _addressLine2Controller,
                      Icons.location_on,
                    ),
                    sectionTitle('Pin Code', isRequired: true),
                    textField(
                      "Enter pin code",
                      _postalCodeController,
                      Icons.pin,
                      keyboard: TextInputType.number,
                    ),
                    sectionTitle('City', isRequired: true),
                    textField(
                      "Enter city",
                      _cityController,
                      Icons.location_city,
                    ),
                    sectionTitle('State', isRequired: true),
                    textField("Enter state", _stateController, Icons.map),
                  ],
                ),
              ),
            ),

            // Documents Step (unchanged)
            Step(
              title: const Text("Documents"),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identity Verification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    sectionTitle('PAN Number', isRequired: true),
                    textField(
                      "ABCDE1234F",
                      panNumberController,
                      Icons.credit_card,
                      formatters: [
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return "PAN required";
                        if (!isValidPAN(v)) return "Invalid PAN";
                        return null;
                      },
                    ),
                    sectionTitle('Aadhaar Number', isRequired: true),
                    textField(
                      "1234 5678 9012",
                      aadhaarNumberController,
                      Icons.credit_card,
                      formatters: [AadhaarInputFormatter()],
                      validator: (v) {
                        final clean = v?.replaceAll(" ", "") ?? "";
                        if (clean.isEmpty) return "Aadhaar required";
                        if (!isValidAadhaar(clean)) return "Invalid Aadhaar";
                        return null;
                      },
                    ),

                    sectionTitle('Driving License No', isRequired: false),
                    textField(
                      "Driving License (e.g. MH1220110012345)",
                      drivingLicenseController,
                      Icons.badge,
                      formatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                      ],
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            !isValidDL(value)) {
                          return "Invalid DL number";
                        }
                        return null;
                      },
                    ),
                    sectionTitle('GST Number', isRequired: false),
                    textField(
                      "15-digit GSTIN eg. 27ABCDE1234F1Z5",
                      gstNumberController,
                      Icons.receipt_long,
                      formatters: [
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(15),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                      ],
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            !isValidGST(value)) {
                          return "Invalid GST";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Document Uploads',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      padding: const EdgeInsets.all(8),
                      children: [
                        buildUploadBox(
                          "Profile Photo",
                          profilePhotoFile,
                          profilePhotoUrl,
                          (f) => setState(() => profilePhotoFile = f),
                          isProfileLoading,
                          (l) => setState(() => isProfileLoading = l),
                        ),
                        buildUploadBox(
                          "Aadhaar Card*",
                          aadhaarFrontFile,
                          aadhaarFrontUrl,
                          (f) => setState(() => aadhaarFrontFile = f),
                          isAadhaarLoading,
                          (l) => setState(() => isAadhaarLoading = l),
                        ),
                        buildUploadBox(
                          "Driver License",
                          licenseFrontFile,
                          licenseFrontUrl,
                          (f) => setState(() => licenseFrontFile = f),
                          isLicenseLoading,
                          (l) => setState(() => isLicenseLoading = l),
                        ),
                        buildUploadBox(
                          "PAN Card*",
                          panDocumentFile,
                          panDocumentUrl,
                          (f) => setState(() => panDocumentFile = f),
                          isPanLoading,
                          (l) => setState(() => isPanLoading = l),
                        ),
                        buildUploadBox(
                          "GST Certificate",
                          gstDocumentFile,
                          gstCertificateUrl,
                          (f) => setState(() => gstDocumentFile = f),
                          isGstLoading,
                          (l) => setState(() => isGstLoading = l),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ================== BANK STEP WITH SECURE FIELDS ==================
            Step(
              title: const Text("Bank"),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bank Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    sectionTitle('Bank Name', isRequired: true),
                    textField(
                      "Enter bank name",
                      bankNameController,
                      Icons.account_balance,
                    ),

                    sectionTitle('Account Number', isRequired: true),
                    _secureTextField(
                      "Enter account number",
                      bankAccountController,
                      Icons.account_balance,
                      _obscureAccountNumber,
                      (val) {
                        setState(() => _obscureAccountNumber = val);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Account number required";
                        }
                        if (!isValidAccountNumber(value)) {
                          return "Enter valid account number (9–18 digits)";
                        }
                        return null;
                      },
                    ),

                    sectionTitle('Confirm Account Number', isRequired: true),
                    _secureTextField(
                      "Re-enter account number",
                      confirmAccountController,
                      Icons.account_balance,
                      _obscureConfirmAccountNumber,
                      (val) {
                        setState(() => _obscureConfirmAccountNumber = val);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirm account number";
                        }
                        if (value != bankAccountController.text) {
                          return "Account numbers do not match";
                        }
                        return null;
                      },
                    ),

                    sectionTitle('IFSC Code', isRequired: true),
                    textField(
                      "Enter IFSC code (e.g. SBIN0001234)",
                      ifscController,
                      Icons.numbers,
                      formatters: [
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(11),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "IFSC code required";
                        }
                        if (!isValidIFSC(value)) {
                          return "Invalid IFSC (e.g. SBIN0001234)";
                        }
                        return null;
                      },
                    ),
                    sectionTitle('Branch Address', isRequired: false),
                    textField(
                      "Enter branch address",
                      branchAddressController,
                      Icons.location_on,
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== SECURE TEXT FIELD (New) ==================
  Widget _secureTextField(
    String hint,
    TextEditingController controller,
    IconData icon,
    bool obscure,
    Function(bool) onToggle, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: obscure,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () => onToggle(!obscure),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          children: [
            TextSpan(text: title),
            if (isRequired)
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
          ],
        ),
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
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        enabled: enabled,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,

        // ✅ IMPORTANT FIX
        onChanged: (_) => setState(() {}),

        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
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
                    : Text(
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
