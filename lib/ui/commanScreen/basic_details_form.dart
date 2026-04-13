import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gocarriage_universal/provider_service/fetch_image_url_provider.dart';
import 'package:gocarriage_universal/provider_service/file_upload_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../provider_service/profile_provider.dart';
import '../../provider_service/update_profile_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';
import 'package:http/http.dart' as http;

import '../../resource/pref_utils.dart';

class BasicDetailsForm extends StatefulWidget {
  const BasicDetailsForm({super.key});

  @override
  State<BasicDetailsForm> createState() => _BasicDetailsFormState();
}

class _BasicDetailsFormState extends State<BasicDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final panNumberController = TextEditingController();
  final gstNumberController = TextEditingController();

  bool isLoading = false;
  bool isInitialized = false;

  // Separate loading states for each document view
  bool isProfileLoading = false;
  bool isPanLoading = false;
  bool isGstLoading = false;

  String? profilePhotoUrl;
  String? panDocumentUrl;
  String? gstCertificateUrl;

  File? profilePhotoFile;
  File? panDocumentFile;
  File? gstDocumentFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile('customer',"customer",PrefUtils.getUserId());
    });
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')));
      return;
    }

    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')));
      return;
    }

    setState(() => isLoading = true);

    await Provider.of<UpdateProfileProvider>(context, listen: false)
        .updateProfile(
      customerName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      pinCode: _postalCodeController.text,
      panNumber: panNumberController.text,
      gstNumber: gstNumberController.text,
      profileImage: profilePhotoUrl ?? "",
      panUpload: panDocumentUrl ?? "",
      gstUpload: gstCertificateUrl ?? "",
    );

    if (!mounted) return;

    final message =
        Provider.of<UpdateProfileProvider>(context, listen: false).message;

    setState(() => isLoading = false);

    if (message == 'Customer updated successfully') {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile('customer',"customer",PrefUtils.getUserId());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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
        if (mType == "Profile Photo") {
          profilePhotoUrl = fileKey;
        } else if (mType == "PAN Document") {
          panDocumentUrl = fileKey;
        } else if (mType == "GST Certificate") {
          gstCertificateUrl = fileKey;
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

  // Updated to accept specific loading state
  Future<void> _showImage(
      String fileName,
      Function(bool) setLoading,
      ) async {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
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
          "Edit Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Consumer<ProfileProvider>(
                builder: (context, profileProvider, child) {
                  if (profileProvider.isLoading) {
                    return Center(child: Utils.buildLoader());
                  } else if (profileProvider.profileData.isNotEmpty) {
                    if (!isInitialized) {
                      final data = profileProvider.profileData;

                      _nameController.text = data['customerName'] ?? "";
                      _phoneController.text = data['phone'] ?? "";
                      _emailController.text = data['email'] ?? "";
                      _addressController.text = data['address'] ?? "";
                      _cityController.text = data['city'] ?? "";
                      _stateController.text = data['state'] ?? "";
                      _postalCodeController.text = data['postalCode'] ?? "";
                      panNumberController.text = data['panNumber'] ?? "";
                      gstNumberController.text = data['gstNumber'] ?? "";

                      panDocumentUrl = data['panUpload'] ?? "";
                      gstCertificateUrl = data['gstUpload'] ?? "";
                      profilePhotoUrl = data['profile_image'] ?? "";

                      isInitialized = true;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Basic Details",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Edit your Basic Details in below fields",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel("Name"),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'Name',
                        ),

                        const SizedBox(height: 20),
                        const Text("Email Id"),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email',
                        ),

                        const SizedBox(height: 20),
                        _buildLabel("Phone Number"),
                        _buildTextField(
                          controller: _phoneController,
                          enabled: false,
                          hint: 'Mobile',
                        ),

                        const SizedBox(height: 20),
                        const Text("Address"),
                        _buildTextField(
                          controller: _addressController,
                          hint: 'Address',
                        ),

                        const SizedBox(height: 20),
                        const Text("City"),
                        _buildTextField(
                          controller: _cityController,
                          hint: 'City',
                        ),

                        const SizedBox(height: 20),
                        const Text("State"),
                        _buildTextField(
                          controller: _stateController,
                          hint: 'State',
                        ),

                        const SizedBox(height: 20),
                        const Text("Pin code"),
                        _buildTextField(
                          controller: _postalCodeController,
                          hint: 'Pin code',
                        ),

                        const SizedBox(height: 10),
                        textField(
                          "PAN Number",
                          panNumberController,
                          Icons.credit_card,
                          formatters: [UpperCaseTextFormatter()],
                        ),

                        const SizedBox(height: 10),
                        textField(
                          "GST Number",
                          gstNumberController,
                          Icons.receipt_long,
                          formatters: [UpperCaseTextFormatter()],
                        ),

                        const SizedBox(height: 30),

                        buildUploadBox(
                          "Profile Photo",
                          profilePhotoFile,
                          profilePhotoUrl,
                              (f) => setState(() => profilePhotoFile = f),
                          isProfileLoading,
                              (loading) => setState(() => isProfileLoading = loading),
                        ),
                        const SizedBox(height: 10),

                        buildUploadBox(
                          "PAN Document",
                          panDocumentFile,
                          panDocumentUrl,
                              (f) => setState(() => panDocumentFile = f),
                          isPanLoading,
                              (loading) => setState(() => isPanLoading = loading),
                        ),
                        const SizedBox(height: 10),

                        buildUploadBox(
                          "GST Certificate",
                          gstDocumentFile,
                          gstCertificateUrl,
                              (f) => setState(() => gstDocumentFile = f),
                          isGstLoading,
                              (loading) => setState(() => isGstLoading = loading),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Update",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: Text('Failed to load profile data'));
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Helper Widgets ====================

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        text: "* ",
        style: const TextStyle(color: Colors.red),
        children: [TextSpan(text: text, style: const TextStyle(color: Colors.black))],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: enabled ? const Icon(Icons.person_outline) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade200,
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
      ),
    );
  }

  Future<void> pickImage(Function(File file) onPicked, String fileType) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      onPicked(file);
      _fileUpload('customers', file, fileType);
    }
  }

  // Updated buildUploadBox with individual loading
  Widget buildUploadBox(
      String label,
      File? localFile,
      String? url,
      Function(File) callback,
      bool isLoading,                    // ← Individual loading
      Function(bool) setLoading,         // ← Callback to update loading
      ) {
    final safeUrl = (url != null && url.isNotEmpty) ? Uri.encodeFull(url) : null;
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
                        Icon(Icons.cloud_upload_outlined,
                            size: 40, color: AppColors.primaryColor),
                        SizedBox(height: 4),
                        Text("(Max 25 MB)",
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    child: isLoading
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
      builder: (ctx) => Dialog(
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,   // 5% margin from sides
          vertical: size.height * 0.1,     // 10% from top & bottom
        ),
        child: Container(
          width: size.width * 0.9,         // 90% of screen width
          height: size.height * 0.75,      // 75% of screen height (you can adjust)
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
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, color: Colors.white70, size: 60),
                              SizedBox(height: 10),
                              Text("Failed to load image",
                                  style: TextStyle(color: Colors.white70)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Pinch to zoom • Drag to move",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
}

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