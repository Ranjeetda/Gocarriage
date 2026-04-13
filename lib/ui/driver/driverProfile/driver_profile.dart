import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/provider_service/driver_update_profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/file_upload_provider.dart';
import '../../../provider_service/profile_provider.dart';
import '../../../resource/CurvedHeaderClipper.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/image_paths.dart';

class DriverProfile extends StatefulWidget {
  String userId;
  String comeFrom;
  DriverProfile(this.comeFrom,this.userId);

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  final picker = ImagePicker();

  // ---------------------- CONTROLLERS ------------------------
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternateNumberController = TextEditingController();
  final whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  final aadhaarNumberController = TextEditingController();
  final experienceController = TextEditingController();
  final panNumberController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final gstNumberController = TextEditingController();

  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  final bankAccountController = TextEditingController();
  final ifscController = TextEditingController();
  final accountHolderController = TextEditingController();
  final branchAddressController = TextEditingController();

  final vehicleTypeController = TextEditingController();
  final vehicleNumberController = TextEditingController();
  final vehicleOwnerController = TextEditingController();
  final vehicleModelController = TextEditingController();

  // ---------------------- IMAGES ------------------------
  File? driversLicenseUploadFile;
  File? aadhaarCardUploadFile;
  File? panCardUploadFile;
  File? insuranceDocumentUploadFile;
  File? profile_pictureFile;

  String? license_from_date;
  String? license_to_date;
  String? driversLicenseUploadUrl;
  String? aadhaarCardUploadUrl;
  String? panCardUploadUrl;
  String? insuranceDocumentUploadUrl;
  String? profile_pictureUrl;

  String? service;

  bool isLoading = false;
  bool isProfileLoading = false;
  bool isAadhaarLoading = false;
  bool isLicenseLoading = false;
  bool isPanLoading = false;
  bool isInsuranceLoading = false;
  bool isSameNumber = false;

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
        } else if (mType == "PAN Document") {
          panCardUploadUrl = fileKey;
        } else if (mType == "License") {
          driversLicenseUploadUrl = fileKey;
        } else if (mType == "Aadhaar") {
          aadhaarCardUploadUrl = fileKey;
        } else if (mType == "Insurance") {
          insuranceDocumentUploadUrl = fileKey;
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

  // ---------------------- LOAD DATA ------------------------
  void setProfileData(Map data) {

    _nameController.text = data["fullName"] ?? data["ownerName"] ?? "";
    _emailController.text = data["email"] ?? "";
    _phoneController.text = data["mobileNo"] ?? data['user']?["phone"] ?? "";
    _alternateNumberController.text = data["alternateNumber"] ??"";

    _cityController.text = data["city"] ?? "";
    _stateController.text = data["state"] ?? "";
    _postalCodeController.text = data["pinCode"] ?? data["postalCode"] ?? "";

    _addressController.text = data["completeAddress"] ?? "";
    _houseNoController.text = data["street"] ?? "";
    _areaController.text = data["area"] ?? "";

    aadhaarNumberController.text = data["aadhaarCardNumber"] ?? "";
    panNumberController.text = data["panCardNumber"] ?? "";
    drivingLicenseController.text = data["licenseNumber"] ?? "";

    emergencyNameController.text = data["emergencyContactName"] ?? "";
    emergencyPhoneController.text = data["emergencyContactNumber"] ?? "";

    bankAccountController.text = data["accountNumber"] ?? "";
    ifscController.text = data["ifscCode"] ?? "";
    accountHolderController.text = data["accountHolderName"] ?? "";
    branchAddressController.text = data["bankName"] ?? "";

    vehicleTypeController.text = data["transportType"] ?? "";
    vehicleNumberController.text = data["vehicleNumber"] ?? "";
    vehicleModelController.text = data["vehicleModel"] ?? "";
    vehicleOwnerController.text = data["vehicleOwner"] ?? "";

    // Image URLs for Driver
    profile_pictureUrl = data["profile_picture"] ?? "";
    aadhaarCardUploadUrl = data["aadhaarCardUpload"] ?? "";
    panCardUploadUrl = data["panCardUpload"] ?? "";
    insuranceDocumentUploadUrl = data["insuranceDocumentUpload"] ?? "";
    driversLicenseUploadUrl = data["driversLicenseUpload"] ?? "";

    setState(() {});
  }

  // ---------------------- INIT ------------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      await provider.fetchProfile(widget.comeFrom,"driver",widget.userId);
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
    await Provider.of<DriverUpdateProfileProvider>(
      context,
      listen: false,
    ).updateProfile(
      fullName: _nameController.text,
      email: _emailController.text,
      mobileNo: _phoneController.text,
      alternateNumber: _alternateNumberController.text,
      houseNumber: '',
      street: _houseNoController.text,
      area: _areaController.text,
      city: _cityController.text,
      state: _stateController.text,
      pinCode: _postalCodeController.text,
      completeAddress: _addressController.text,
      emergencyContactName: emergencyNameController.text,
      emergencyContactNumber: emergencyPhoneController.text,
      transportType: vehicleTypeController.text,
      vehicleOwner: vehicleOwnerController.text,
      vehicleNumber: vehicleNumberController.text,
      vehicleModel: vehicleModelController.text,
      vehicleFeatures: 'vehicleFeatures',
      vehicleDetails: 'vehicleDetails',

      licenseNumber: drivingLicenseController.text,
      license_expiry_date: license_to_date??"",
      license_from_date: license_from_date??"",
      experience_in_yrs: experienceController.text,

      vehicle_type_preference: 'vehicle_type_preference',
      service_type: service == 'Within City' ? 'in_city' : service ?? '',
      aadhaarCardNumber: aadhaarNumberController.text,
      panCardNumber: panNumberController.text,
      bankName: branchAddressController.text,
      accountNumber: bankAccountController.text,
      ifscCode: ifscController.text,
      driversLicenseUpload: driversLicenseUploadUrl ?? "",
      aadhaarCardUpload: aadhaarCardUploadUrl ?? "",
      panCardUpload: panCardUploadUrl ?? "",
      insuranceDocumentUpload: insuranceDocumentUploadUrl ?? "",
      profile_picture: profile_pictureUrl ?? "",
    );

    final success = Provider.of<DriverUpdateProfileProvider>(
          context,
          listen: false,
        ).success;

    setState(() => isLoading = false);


    if (success == 'Driver updated successfully') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Driver updated successfully')));
      Navigator.pop(context);
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
                "Phone Number",
                _phoneController,
                Icons.phone,
                enabled: false,
                keyboard: TextInputType.phone,
              ),
              textField(
                "Alternate Number",
                _alternateNumberController,
                Icons.phone,
                enabled: true,
                keyboard: TextInputType.phone,
              ),

              const SizedBox(height: 10),

              // Address Details
              sectionTitle("Address Details"),
              textField(
                "Complete Address",
                _addressController,
                Icons.location_on,
              ),
              textField("House No. / Flat No.", _houseNoController, Icons.home),
              textField("Area / Locality", _areaController, Icons.map),
              textField("City", _cityController, Icons.location_city),
              textField("State", _stateController, Icons.location_city),
              textField(
                "Pin Code",
                _postalCodeController,
                Icons.pin,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 10),
              sectionTitle("Emergency Contact"),
              textField(
                "Contact Person Name",
                emergencyNameController,
                Icons.person,
              ),
              textField(
                "Contact Phone Number",
                emergencyPhoneController,
                Icons.phone,
                keyboard: TextInputType.phone,
              ),

              const SizedBox(height: 10),
              sectionTitle("Vehicle Details"),
              textField(
                "Vehicle Type",
                vehicleTypeController,
                Icons.directions_car,
                formatters: [UpperCaseTextFormatter()],
              ),
              textField(
                "Vehicle Model",
                vehicleModelController,
                Icons.build,
                formatters: [UpperCaseTextFormatter()],
              ),
              textField(
                "Vehicle Number",
                vehicleNumberController,
                Icons.confirmation_number,
                formatters: [UpperCaseTextFormatter()],
              ),
              textField(
                "Vehicle Owner Name",
                vehicleOwnerController,
                Icons.person,
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
                "Experience",
                experienceController,
                Icons.car_rental,
                formatters: [UpperCaseTextFormatter()],
              ),
              textField(
                "Driving License Number",
                drivingLicenseController,
                Icons.badge,
                formatters: [UpperCaseTextFormatter()],
              ),
              Container(
                margin: EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Expanded(child: date("From", license_from_date, (v) => license_from_date = v)),
                    SizedBox(width: 10,),
                    Expanded(child: date("To", license_to_date, (v) => license_to_date = v)),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: radioRow(
                  "Service Type *",
                  ["Within City", "Outside City"],
                  service,
                  (v) => setState(() => service = v),
                ),
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
                    "Aadhaar",
                    aadhaarCardUploadFile,
                    aadhaarCardUploadUrl,
                    (f) => setState(() => aadhaarCardUploadFile = f),
                    isAadhaarLoading,
                    (loading) => setState(() => isAadhaarLoading = loading),
                  ),

                  buildUploadBox(
                    "License",
                    driversLicenseUploadFile,
                    driversLicenseUploadUrl,
                    (f) => setState(() => driversLicenseUploadFile = f),
                    isLicenseLoading,
                    (loading) => setState(() => isLicenseLoading = loading),
                  ),

                  buildUploadBox(
                    "PAN Document",
                    panCardUploadFile,
                    panCardUploadUrl,
                    (f) => setState(() => panCardUploadFile = f),
                    isPanLoading,
                    (loading) => setState(() => isPanLoading = loading),
                  ),

                  buildUploadBox(
                    "Insurance",
                    insuranceDocumentUploadFile,
                    insuranceDocumentUploadUrl,
                    (f) => setState(() => insuranceDocumentUploadFile = f),
                    isInsuranceLoading,
                    (loading) => setState(() => isInsuranceLoading = loading),
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
                "Bank Name / Branch",
                branchAddressController,
                Icons.account_balance,
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
