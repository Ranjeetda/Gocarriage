import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/provider_service/driver_update_profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../provider_service/URLS.dart';
import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/file_upload_provider.dart';
import '../../../provider_service/owner_profile_update_provider.dart';
import '../../../provider_service/profile_provider.dart';
import '../../../resource/CurvedHeaderClipper.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';
import '../../../resource/pref_utils.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreen();
}

class _OwnerProfileScreen extends State<OwnerProfileScreen> {
  final picker = ImagePicker();

  // ---------------------- CONTROLLERS ------------------------
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _ownerTypeNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  final _contactPersonNameController = TextEditingController();
  final _contactPersonEmailController = TextEditingController();
  final _contactPersonPhoneController = TextEditingController();

  final aadhaarNumberController = TextEditingController();
  final panNumberController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final gstNumberController = TextEditingController();

  final bankAccountController = TextEditingController();
  final ifscController = TextEditingController();
  final accountHolderController = TextEditingController();
  final branchAddressController = TextEditingController();

  // ---------------------- IMAGES ------------------------
  File? aadhaarFrontFile;
  File? licenseFrontFile;
  File? profilePhotoFile;
  File? panDocumentFile;
  File? gstDocumentFile;
  File? cancelChequeFile; // <-- Added

  // Network image URLs
  String? aadhaarFrontUrl;
  String? licenseFrontUrl;
  String? profilePhotoUrl;
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
  bool isSameNumber = false;

  Future<void> pickImage(Function(File file) onPicked, String fileType) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      onPicked(file);
      _fileUpload('owners', file, fileType);
    }
  }

  // Updated buildUploadBox with individual loading
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
          print("RanjeetTest   ${mType} ============>${profilePhotoUrl!}");
        } else if (mType == "PAN Document") {
          panDocumentUrl = fileKey;
          print("RanjeetTest ============>${mType + panDocumentUrl!}");
        } else if (mType == "GST Certificate") {
          gstCertificateUrl = fileKey;
          print("RanjeetTest ============>${mType + gstCertificateUrl!}");

        } else if (mType == "License") {
          licenseFrontUrl = fileKey;
          print("RanjeetTest ============>${mType + licenseFrontUrl!}");

        }else if (mType == "Aadhaar") {
          aadhaarFrontUrl = fileKey;
          print("RanjeetTest ============>${mType + aadhaarFrontUrl!}");

        }else if (mType == "Upload Cancelled Cheque") {
          cancelChequeUrl = fileKey;
          print("RanjeetTest ============>${mType + cancelChequeUrl!}");

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

  // ---------------------- LOAD DATA ------------------------
  void setProfileData(Map data) {

    _nameController.text = data["fullName"] ?? data["ownerName"] ?? "";
    _emailController.text = data["email"] ?? "";
    _phoneController.text = data["mobileNo"] ?? data['user']?["phone"] ?? "";

    _cityController.text = data["city"] ?? "";
    _stateController.text = data["state"] ?? "";
    _postalCodeController.text = data["pinCode"] ?? data["postalCode"] ?? "";

    _addressController.text = data["address"] ?? "";
    aadhaarNumberController.text = data["aadhaarNumber"] ?? "";
    panNumberController.text = data["panNumber"] ?? "";
    drivingLicenseController.text = data["drivingLicenceNumber"] ?? "";
    gstNumberController.text = data["gstNumber"] ?? "";

    profilePhotoUrl = URLS.imagBaseUrlOwner + (data["profile_image"]);
    aadhaarFrontUrl = URLS.imagBaseUrlOwner + (data["aadhaarUpload"]);
    panDocumentUrl = URLS.imagBaseUrlOwner + (data["panUpload"]);
    licenseFrontUrl =
        URLS.imagBaseUrlOwner + (data["drivingLicenceUpload"]);
    gstCertificateUrl =
        URLS.imagBaseUrlOwner + (data["gstCertificateUpload"]);
    cancelChequeUrl =
        URLS.imagBaseUrlOwner + (data["cancelCheque"]); // <-- Fixed

    bankAccountController.text = data["accountNumber"] ?? "";
    ifscController.text = data["ifscCode"] ?? "";
    accountHolderController.text = data["accountHolderName"] ?? "";
    branchAddressController.text = data["bankName"] ?? "";

    setState(() {});
  }

  // ---------------------- INIT ------------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      await provider.fetchProfile('owner',"owner",PrefUtils.getUserId());
      if (provider.profileData.isNotEmpty) {
        setProfileData(provider.profileData);
      }
    });
  }

  // ---------------------- UPDATE PROFILE ------------------------
  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    setState(() => isLoading = true);

    // Note: You may need to update your provider method to also accept cancelChequeFile
    await Provider.of<OwnerProfileUpdateProvider>(
      context,
      listen: false,
    ).updateProfile(
      ownerName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      type: _ownerTypeNameController.text,
      companyName: _companyNameController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      pinCode: _postalCodeController.text,
      wa_number: _whatsappController.text,
      contactPersonName: _contactPersonNameController.text,
      contactPersonEmail: _contactPersonEmailController.text,
      contactPersonPhone: _contactPersonPhoneController.text,
      panNumber: panNumberController.text,
      aadhaarNumber: aadhaarNumberController.text,
      gstNumber: gstNumberController.text,
      drivingLicenceNumber: drivingLicenseController.text,
      bankName: bankAccountController.text,
      accountNumber: bankAccountController.text,
      ifscCode: ifscController.text,
      branchAddress: branchAddressController.text,

      panUpload: panDocumentUrl??"",
      aadhaarUpload: aadhaarFrontUrl??"",
      gstCertificateUpload: gstCertificateUrl??"",
      drivingLicenceUpload: licenseFrontUrl??"",
      profilePhotoUpload: profilePhotoUrl??"",
      cancelCheque: cancelChequeUrl??"",
    );

    final message =
        Provider.of<DriverUpdateProfileProvider>(
          context,
          listen: false,
        ).message;

    setState(() => isLoading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Update failed')));

    if (message == 'Driver updated successfully') {

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: header(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Personal Information
              sectionTitle("Personal Information"),
              textField("Full Name", _nameController, Icons.person),
              textField(
                "Email ID",
                _emailController,
                Icons.email,
                keyboard: TextInputType.emailAddress,
              ),
              textField(
                "Company Name",
                _companyNameController,
                Icons.house_rounded,
              ),
              textField(
                "Owner Type",
                _ownerTypeNameController,
                Icons.house_rounded,
              ),
              textField(
                "Phone Number",
                _phoneController,
                Icons.phone,
                enabled: false,
                keyboard: TextInputType.phone,
              ),
              textField(
                "Whatsapp Number",
                _whatsappController,
                Icons.phone,
                enabled: false,
                keyboard: TextInputType.phone,
              ),

              const SizedBox(height: 10),

              // Address Details
              sectionTitle("Contact Person"),
              textField(
                "Contact person name",
                _contactPersonNameController,
                Icons.location_on,
              ),
              textField(
                "Contact person email",
                _contactPersonEmailController,
                Icons.location_city,
              ),
              textField(
                "Contact person phone",
                _contactPersonPhoneController,
                Icons.location_city,
              ),

              sectionTitle("Address Details"),
              textField(
                "Complete Address",
                _addressController,
                Icons.location_on,
              ),
              textField("City", _cityController, Icons.location_city),
              textField("State", _stateController, Icons.location_city),
              textField(
                "Pin Code",
                _postalCodeController,
                Icons.pin,
                keyboard: TextInputType.number,
              ),

              const SizedBox(height: 10),

              // Identity Verification
              sectionTitle("Identity Verification"),
              textField(
                "Aadhaar Number",
                aadhaarNumberController,
                Icons.credit_card,
                keyboard: TextInputType.number,
              ),
              textField(
                "PAN Number",
                panNumberController,
                Icons.credit_card,
                formatters: [UpperCaseTextFormatter()],
              ),
              textField(
                "Driving License Number",
                drivingLicenseController,
                Icons.badge,
                formatters: [UpperCaseTextFormatter()],
              ),

              textField(
                "GST Number",
                gstNumberController,
                Icons.receipt_long,
                formatters: [UpperCaseTextFormatter()],
              ),

              const SizedBox(height: 15),

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
                    profilePhotoFile,
                    profilePhotoUrl,
                    (f) => setState(() => profilePhotoFile = f),
                    isProfileLoading,
                    (loading) => setState(() => isProfileLoading = loading),
                  ),

                  buildUploadBox(
                    "Aadhaar",
                    aadhaarFrontFile,
                    aadhaarFrontUrl,
                    (f) => setState(() => aadhaarFrontFile = f),
                    isAadhaarLoading,
                    (loading) => setState(() => isAadhaarLoading = loading),
                  ),

                  buildUploadBox(
                    "License",
                    licenseFrontFile,
                    licenseFrontUrl,
                    (f) => setState(() => licenseFrontFile = f),
                    isLicenseLoading,
                    (loading) => setState(() => isLicenseLoading = loading),
                  ),

                  buildUploadBox(
                    "PAN Document",
                    panDocumentFile,
                    panDocumentUrl,
                    (f) => setState(() => panDocumentFile = f),
                    isPanLoading,
                    (loading) => setState(() => isPanLoading = loading),
                  ),

                  buildUploadBox(
                    "GST Certificate",
                    gstDocumentFile,
                    gstCertificateUrl,
                    (f) => setState(() => gstDocumentFile = f),
                    isGstLoading,
                    (loading) => setState(() => isGstLoading = loading),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bank Details + Cancelled Cheque (Only for Owner)
              sectionTitle("Bank Details"),
              textField(
                "Bank Account Number",
                bankAccountController,
                Icons.account_balance,
                keyboard: TextInputType.number,
              ),
              textField(
                "IFSC Code",
                ifscController,
                Icons.numbers,
                formatters: [UpperCaseTextFormatter()],
              ),
              textField(
                "Account Holder Name",
                accountHolderController,
                Icons.person,
                formatters: [UpperCaseTextFormatter()],
              ),
              textField(
                "Bank Name / Branch",
                branchAddressController,
                Icons.account_balance,
              ),

              const SizedBox(height: 15),
              sectionTitle("Cancelled Cheque"),
              buildUploadBox(
                "Upload Cancelled Cheque",
                cancelChequeFile,
                cancelChequeUrl,
                    (f) => setState(() => cancelChequeFile = f),
                isCancelChequeLoading,
                    (loading) => setState(() => isCancelChequeLoading = loading),
              ),
              const SizedBox(height: 40),

              // Update Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updateProfile,
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
                              "Update Profile",
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
    );
  }

  // Header
  Widget header() {
    return Stack(
      children: [
        ClipPath(
          clipper: CurvedHeaderClipper(),
          child: Container(
            width: double.infinity,
            height: 280,
            color: AppColors.primaryColor,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "My Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Image.asset(ImagePaths.appLogoVertical, height: 75),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: TextField(
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
      ),
    );
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
