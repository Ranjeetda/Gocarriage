import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../provider_service/create_corporate_provider.dart';
import '../../../provider_service/email_verify_otp_provider.dart';
import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/file_upload_provider.dart';
import '../../../provider_service/send_otp_email_provider.dart';
import '../../../provider_service/send_otp_provider.dart';
import '../../../provider_service/verify_otp_provider..dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/upper_case_text_formatter.dart';
import '../../commanScreen/common_screen.dart';
import '../../widgets/shared_widgets.dart';

class CompanyFormPage extends StatefulWidget {
  CompanyFormPage();

  @override
  State<CompanyFormPage> createState() => _CompanyFormPage();
}

class _CompanyFormPage extends State<CompanyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  final companyName = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final postalCode = TextEditingController();
  final mobile = TextEditingController();
  final gst = TextEditingController();
  final email = TextEditingController();
  String _stateController = 'Uttar Pradesh';
  String selectedCompany = 'Private Limited';
  String? phoneVerificationToken;

  String? gstCertificateUrl;
  File? gstDocumentFile;

  bool isLoadingEmail = false;
  bool isLoadingEmailOtp = false;
  bool isGstLoading = false;
  bool isChecked = false;

  bool isEmailOtpSent = false;
  bool isEmailVerified = false;

  bool isMobileOtpSent = false;
  bool isMobileVerified = false;
  bool isLoadingMobile = false;
  bool isLoadingMobileOtp = false;
  bool isLoading = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  final List<TextEditingController> emailOtpControllers = List.generate(
    6,
        (_) => TextEditingController(),
  );
  final List<TextEditingController> mobileOtpControllers = List.generate(
    6,
        (_) => TextEditingController(),
  );

  Future<void> _sendMobileOtp() async {
    if (mobile.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your mobile or email');
      return;
    }
    setState(() {
      isLoadingMobile = true;
    });

    http.Response response = await Provider.of<SendOtpProvider>(
      context,
      listen: false,
    ).sendOtp(mobile.text.trim());
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
    ).verifyOtp(mobile.text.trim(), otp);
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


  Future<void> sendOtpOnEmail() async {
    if (_formKey.currentState!.validate()) {
      if (email.text.isEmpty) {
        Utils.showErrorMessage(context, 'Please enter your  email');
        return;
      }
      setState(() {
        isLoadingEmail = true;
      });

      http.Response response = await Provider.of<SendOtpEmailProvider>(
        context,
        listen: false,
      ).sentOtpEmail(email.text);
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
    ).verifyOtpEmail(email.text, otp);
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Corporate Account Application',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CommonTextField(
                hint: 'Please enter company name',
                controller: companyName,
                icon: Icons.business,
                isRequired: true,
                label: 'Enter company name',
              ),
              const SizedBox(height: 16),
              CommonDropdown(
                hint: 'Company Type',
                label: 'Select Company Type',
                value: selectedCompany.isEmpty ? null : selectedCompany,
                items: Utils.companyTypes,
                icon: Icons.directions_car,
                isRequired: true,
                onChanged: (v) => setState(() => selectedCompany = v ?? ''),
              ),

              const SizedBox(height: 16),
              CommonTextField(
                hint: 'Please enter registered address',
                controller: address,
                icon: Icons.location_city,
                isRequired: true,
                label: 'Registered Address',
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(

                    child:  CommonTextField(
                      hint: 'Please enter city',
                      controller: city,
                      icon: Icons.location_city,
                      isRequired: true,
                      label: 'City',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:   CommonDropdown(
                      hint: 'Select State',
                      label: 'State',
                      value: _stateController.isEmpty ? null : _stateController,
                      items: Utils.indiaStates,
                      icon: Icons.location_on,
                      isRequired: true,
                      onChanged: (v) => setState(() => _stateController = v ?? ''),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              CommonTextField(
                hint: 'Please enter pin code',
                controller: postalCode,
                icon: Icons.person,
                isRequired: true,
                label: 'Postal Code',
              ),

              const SizedBox(height: 16),
              MobileSection(
                mobileController: mobile,
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
              CommonTextField(
                hint: 'Enter GST Number',
                controller: gst,
                icon: Icons.receipt_long,
                label: 'GST Number',
                formatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(15),
                ],
                onChanged: () => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // optional
                  if (!RegExp(
                    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                  ).hasMatch(v))
                    return 'Enter a valid GST (e.g. 27ABCDE1234F1Z5)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              EmailSection(
                emailController: email,
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

              const SizedBox(height: 20),

              buildUploadBox(
                "GST Certificate",
                gstDocumentFile,
                gstCertificateUrl,
                    (f) => setState(() => gstDocumentFile = f),
                isGstLoading,
                    (loading) => setState(() => isGstLoading = loading),
              ),

              const SizedBox(height: 30),

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
                              recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  _navigateTo(
                                    CommonScreen(
                                      'https://gocarriage.com/terms-condition',
                                      'Terms & Conditions',
                                    ),
                                  );
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
                              recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  _navigateTo(
                                    CommonScreen(
                                      'https://gocarriage.com/privacy-policy',
                                      'Privacy Policy',
                                    ),
                                  );
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
            ],
          ),
        ),
      ),

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
              _createCorporateCustomer();
            },
            child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              "Save",
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

  Future<void> _createCorporateCustomer() async {

    setState(() => isLoading = true);

    await Provider.of<CreateCorporateProvider>(
      context,
      listen: false,
    ).createCorporate(
      companyName:companyName.text.trim(),
      companyType:selectedCompany,
      registeredAddress:address.text.trim(),
      city:city.text.trim(),
      state:_stateController,
      postalCode:postalCode.text.trim(),
      mobileNumber:mobile.text,
      gstNumber:gst.text.trim(),
      companyEmail:email.text.trim(),
      gstUpload: gstCertificateUrl ?? "",
    );

    if (!mounted) return;

    final message = Provider.of<CreateCorporateProvider>(context, listen: false).message;

    setState(() => isLoading = false);

    if (message == 'Customer updated successfully') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
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
       if (mType == "GST Certificate") {
          gstCertificateUrl = fileKey;
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

  Future<void> _pickFromSource(
      ImageSource source,
      Function(File file) onPicked,
      String fileType,
      ) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      onPicked(file); // update UI
      _fileUpload('corporate', file, fileType); // your API call
    }
  }
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
    print("RanjeetTest===============>${safeUrl}");
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
                bottom: 8,
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
}