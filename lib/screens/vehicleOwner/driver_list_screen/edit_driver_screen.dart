import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../provider_service/driver_profile_provider.dart';
import '../../../provider_service/update_driver_provider.dart';
import '../../../provider_service/file_upload_provider.dart';
import '../../../provider_service/fetch_image_url_provider.dart';
import '../../../provider_service/send_otp_provider.dart';
import '../../../provider_service/verify_otp_provider..dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';

class EditDriverScreen extends StatefulWidget {
  final String driverId;

  const EditDriverScreen({super.key, required this.driverId});

  @override
  State<EditDriverScreen> createState() => _EditDriverScreenState();
}

class _EditDriverScreenState extends State<EditDriverScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController mobileController;
  late TextEditingController licenseNumberController;
  late TextEditingController experienceController;

  // Dates
  DateTime? validFrom;
  DateTime? validUpto;

  // Dropdowns
  String? selectedLicenseType;
  String? selectedServiceType;

  // Photo
  File? selectedPhoto;
  String? existingPhotoUrl;

  // License Document
  File? selectedLicenseFile;
  String? existingLicenseUrl;

  bool isLoading = true;
  bool isMobileVerified = true;
  bool isEditingMobile = false;
  bool isOtpSent = false;
  int secondsRemaining = 60;
  Timer? timer;
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  final List<String> licenseTypes = [
    'LMV – Light Motor Vehicle',
    'HMV – Heavy Motor Vehicle',
    'MGV – Medium Goods Vehicle',
    'HGV – Heavy Goods Vehicle',
    'Trailer',
  ];

  final List<String> serviceTypes = [
    'Within City',
    'Outside City',
  ];

  // Map short code → full label
  String _mapLicenseType(String? code) {
    if (code == null) return 'HMV – Heavy Motor Vehicle';
    switch (code.toUpperCase()) {
      case 'LMV':
        return 'LMV – Light Motor Vehicle';
      case 'HMV':
        return 'HMV – Heavy Motor Vehicle';
      case 'MGV':
        return 'MGV – Medium Goods Vehicle';
      case 'HGV':
        return 'HGV – Heavy Goods Vehicle';
      case 'TRAILER':
        return 'Trailer';
      default:
        return 'HMV – Heavy Motor Vehicle';
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers first (important!)
    nameController = TextEditingController();
    emailController = TextEditingController();
    mobileController = TextEditingController();
    licenseNumberController = TextEditingController();
    experienceController = TextEditingController();

    // Fetch full profile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDriverProfile();
    });
  }

  Future<void> _loadDriverProfile() async {
    setState(() => isLoading = true);

    final provider = Provider.of<DriverProfileProvider>(context, listen: false);


    await provider.fetchProfile(widget.driverId);

    final data = provider.profileData; // ← make sure your provider exposes this

    if (data != null && mounted) {
      _fillForm(data);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _fillForm(Map<String, dynamic> data) {
    nameController.text = data['fullName']?.toString() ?? '';
    emailController.text = data['email']?.toString() ?? '';
    mobileController.text = data['mobileNo']?.toString() ?? '';
    licenseNumberController.text = data['licenseNumber']?.toString() ?? '';
    experienceController.text = data['experience_in_yrs']?.toString() ?? '';

    // Service Type
    final st = (data['service_type'] ?? '').toString().toLowerCase();
    selectedServiceType = st == 'out_city' ? 'Outside City' : 'Within City';

    // License Type
    selectedLicenseType = _mapLicenseType(data['license_type']?.toString());

    // Photo
    existingPhotoUrl = data['profile_picture']?.toString();

    // License Document
    existingLicenseUrl = data['driversLicenseUpload']?.toString();

    // Dates
    try {
      if (data['license_from_date'] != null) {
        validFrom = DateTime.parse(data['license_from_date']);
      }
      if (data['license_expiry_date'] != null) {
        validUpto = DateTime.parse(data['license_expiry_date']);
      }
    } catch (_) {}

    setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    licenseNumberController.dispose();
    experienceController.dispose();
    timer?.cancel();
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var f in otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    secondsRemaining = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining == 0) {
        t.cancel();
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedPhoto = File(picked.path));
      _fileUpload('drivers', selectedPhoto, 'Profile Photo');
    }
  }

  Future<void> _pickLicense() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedLicenseFile = File(picked.path));
      _fileUpload('drivers', selectedLicenseFile, 'License');
    }
  }

  String _unmapLicenseType(String? label) {
    if (label == null) return 'HMV';
    if (label.contains('LMV')) return 'LMV';
    if (label.contains('HMV')) return 'HMV';
    if (label.contains('MGV')) return 'MGV';
    if (label.contains('HGV')) return 'HGV';
    if (label.contains('Trailer')) return 'TRAILER';
    return 'HMV';
  }

  Future<void> _fileUpload(
    String folderName,
    File? fileName,
    String mType,
  ) async {
    if (fileName == null) return;

    Utils.showLoader(context);

    final response = await Provider.of<FileUploadProvider>(
      context,
      listen: false,
    ).uploadFileOnServer(folder: folderName, mFile: fileName);

    if (!mounted) return;
    Utils.hideLoader();

    if (response != null && response['success'] == true) {
      final message = response['message'] ?? 'File uploaded successfully';
      final fileKey = response['data']?['key'];

      setState(() {
        if (mType == 'Profile Photo') {
          existingPhotoUrl = fileKey;
        } else if (mType == 'License') {
          existingLicenseUrl = fileKey;
        }
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } else {
      final message = response?['message'] ?? 'Upload failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showImage(String fileName) async {
    Utils.showLoader(context);

    final response = await Provider.of<FetchImageUrlProvider>(
      context,
      listen: false,
    ).fetchImagePath(fileName);

    if (!mounted) return;
    Utils.hideLoader();

    final responseData = jsonDecode(response.body);

    if (responseData['success'] == true &&
        responseData['data']?['url'] != null) {
      _showImagePreview(responseData['data']['url']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['message'] ?? 'Failed to load image'),
        ),
      );
    }
  }

  void _showImagePreview(String imageUrl) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
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
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
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

  Future<void> _selectDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (validFrom ?? DateTime.now())
          : (validUpto ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          validFrom = picked;
        } else {
          validUpto = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
            decoration:  BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Edit · driver',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Update driver information',
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
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── PERSONAL INFORMATION ─────────────────
                    _sectionTitle(
                        Icons.person_outline, 'PERSONAL INFORMATION'),
                    const SizedBox(height: 14),

                    // Photo
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: selectedPhoto != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedPhoto!,
                                fit: BoxFit.cover,
                              ),
                            )
                                : existingPhotoUrl != null &&
                                existingPhotoUrl!.isNotEmpty
                                ? ClipRRect(
                              borderRadius:
                              BorderRadius.circular(12),
                              child: Image.network(
                                // ⚠️ Change base URL if needed
                                existingPhotoUrl!
                                    .startsWith('http')
                                    ? existingPhotoUrl!
                                    : 'https://your-api-domain.com/$existingPhotoUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person,
                                    color: Colors.grey),
                              ),
                            )
                                : const Icon(Icons.person_outline,
                                color: Colors.grey, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Driver Photo (optional)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.camera_alt_outlined,
                                            size: 18, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            selectedPhoto != null
                                                ? selectedPhoto!.path.split('/').last
                                                : (existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty
                                                ? existingPhotoUrl!.split('/').last
                                                : 'Upload photo (JPG / PNG)'),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty && selectedPhoto == null)
                                          GestureDetector(
                                            onTap: () => _showImage(existingPhotoUrl!),
                                            child: const Icon(Icons.remove_red_eye, color: Color(0xFF0D7377), size: 20),
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

                    const SizedBox(height: 18),

                    // Name + Email
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Full Name *',
                            controller: nameController,
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Email Address *',
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── MOBILE VERIFICATION ──────────────────
                    _sectionTitle(Icons.phone_outlined, 'MOBILE VERIFICATION'),
                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Mobile Number *',
                            controller: mobileController,
                            keyboardType: TextInputType.phone,
                            enabled: isEditingMobile,
                          ),
                        ),
                        if (isEditingMobile && !isOtpSent) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (mobileController.text.length == 10) {
                                  Utils.showLoader(context);
                                  final response =
                                      await Provider.of<SendOtpProvider>(
                                              context,
                                              listen: false)
                                          .sendOtp(mobileController.text);
                                  Utils.hideLoader();
                                  final data = json.decode(response.body);

                                  if (data['success'] == true) {
                                    setState(() {
                                      isOtpSent = true;
                                      _startTimer();
                                    });
                                    Utils.showSuccessMessage(
                                        context, "OTP sent successfully");
                                  } else {
                                    Utils.showErrorMessage(context,
                                        data['message'] ?? "Failed to send OTP");
                                  }
                                } else {
                                  Utils.showErrorMessage(
                                      context, "Enter valid mobile number");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Send OTP'),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (!isEditingMobile && isMobileVerified)
                      // Verified banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF43A047), size: 22),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Mobile verified!',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isEditingMobile = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Edit',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),

                    if (isOtpSent) ...[
                      const SizedBox(height: 16),
                      _buildOtpBox(),
                    ],

                    const SizedBox(height: 28),

                    // ── LICENSE DETAILS ──────────────────────
                    _sectionTitle(
                        Icons.badge_outlined, 'LICENSE DETAILS'),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'License Number *',
                            controller: licenseNumberController,
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  label: 'License Valid From *',
                                  value: _formatDate(validFrom),
                                  onTap: () =>
                                      _selectDate(isFrom: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateField(
                                  label: 'License Valid Upto *',
                                  value: _formatDate(validUpto),
                                  onTap: () =>
                                      _selectDate(isFrom: false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: 'License Type *',
                                  value: selectedLicenseType,
                                  items: licenseTypes,
                                  onChanged: (v) => setState(
                                          () => selectedLicenseType = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'License Document',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF555555),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: _pickLicense,
                                      child: Container(
                                        height: 48,
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          border: Border.all(
                                              color:
                                              Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons
                                                    .upload_file_outlined,
                                                size: 18,
                                                color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                selectedLicenseFile != null
                                                    ? selectedLicenseFile!.path.split('/').last
                                                    : (existingLicenseUrl != null && existingLicenseUrl!.isNotEmpty
                                                    ? existingLicenseUrl!.split('/').last
                                                    : 'Upload (PDF / JPG / PNG)'),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow
                                                    .ellipsis,
                                              ),
                                            ),
                                            if (existingLicenseUrl != null && existingLicenseUrl!.isNotEmpty && selectedLicenseFile == null)
                                              GestureDetector(
                                                onTap: () => _showImage(existingLicenseUrl!),
                                                child: const Icon(Icons.remove_red_eye, color: Color(0xFF0D7377), size: 20),
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── WORK DETAILS ─────────────────────────
                    _sectionTitle(Icons.local_shipping_outlined,
                        'WORK DETAILS'),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Experience *',
                            controller: experienceController,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Service Type *',
                            value: selectedServiceType,
                            items: serviceTypes,
                            onChanged: (v) => setState(
                                    () => selectedServiceType = v),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── BUTTONS ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              side: BorderSide(
                                  color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D7377),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: context.watch<UpdateDriverProvider>().isLoading
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
                                      Icon(Icons.check, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Update Driver',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0D7377)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Color(0xFF0D7377),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            color: enabled ? Colors.black87 : Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: Color(0xFF0D7377), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Select date' : value,
                    style: TextStyle(
                      fontSize: 15,
                      color: value.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600),
              items: items
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 14)),
              ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (!isMobileVerified) {
        Utils.showErrorMessage(context, 'Please verify mobile number');
        return;
      }

      final provider = Provider.of<UpdateDriverProvider>(context, listen: false);

      await provider.updateDriverProfile(
        driverId: widget.driverId,
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        licenseNumber: licenseNumberController.text.trim(),
        licenseFromDate: validFrom != null ? DateFormat('yyyy-MM-dd').format(validFrom!) : "",
        licenseExpiryDate: validUpto != null ? DateFormat('yyyy-MM-dd').format(validUpto!) : "",
        licenseType: _unmapLicenseType(selectedLicenseType),
        experienceInYrs: experienceController.text.trim(),
        serviceType: selectedServiceType == 'Within City' ? 'in_city' : 'out_city',
        driversLicenseUpload: existingLicenseUrl ?? "",
        profilePicture: existingPhotoUrl ?? "",
      );

      if (!mounted) return;

      if (provider.success) {
        Utils.showSuccessMessage(context, provider.message);
        Navigator.pop(context, true); // true to indicate success
      } else {
        Utils.showErrorMessage(context, provider.message);
      }
    }
  }

  Widget _buildOtpBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '6-digit OTP sent to ${mobileController.text}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const Text(
            'OTP valid for 10 minutes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 45,
                height: 50,
                child: TextField(
                  controller: otpControllers[index],
                  focusNode: otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF60A5FA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      otpFocusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      String otp = otpControllers.map((c) => c.text).join();
                      if (otp.length == 6) {
                        Utils.showLoader(context);
                        final response = await Provider.of<VerifyOtpProvider>(
                                context,
                                listen: false)
                            .verifyOtp(mobileController.text, otp);
                        Utils.hideLoader();
                        final data = json.decode(response.body);

                        if (data['success'] == true) {
                          setState(() {
                            isMobileVerified = true;
                            isEditingMobile = false;
                            isOtpSent = false;
                          });
                          Utils.showSuccessMessage(
                              context, "Mobile verified successfully");
                        } else {
                          Utils.showErrorMessage(context,
                              data['message'] ?? "Invalid OTP");
                        }
                      } else {
                        Utils.showErrorMessage(context, "Enter 6-digit OTP");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF86EFAC), // Soft green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: secondsRemaining == 0
                        ? () {
                            _startTimer();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: const Color(0xFF94A3B8),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${secondsRemaining}s',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}