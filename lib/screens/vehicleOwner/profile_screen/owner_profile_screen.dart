import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../provider_service/email_verify_otp_provider.dart';
import '../../../provider_service/owner_profile_update_provider.dart';
import '../../../provider_service/profile_provider.dart';
import '../../../provider_service/send_otp_email_provider.dart';
import '../../../resource/Utils.dart';
import '../../../resource/app_colors.dart';
import '../../../resource/pref_utils.dart';
import '../../../resource/upper_case_text_formatter.dart';
import 'package:http/http.dart' as http;
import '../../widgets/shared_widgets.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  int _currentStep = 0;
  final picker = ImagePicker();

  // ─── Controllers ───────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final aadhaarNumberController = TextEditingController();
  final panNumberController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final gstNumberController = TextEditingController();
  final bankNameController = TextEditingController();
  final bankAccountController = TextEditingController();
  final confirmAccountController = TextEditingController();
  final ifscController = TextEditingController();
  final branchAddressController = TextEditingController();

  String _stateController = 'Uttar Pradesh';

  final List<TextEditingController> emailOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // ─── Image Files ───────────────────────────────────────────
  File? profilePhotoFile,
      aadhaarFrontFile,
      licenseFrontFile,
      panDocumentFile,
      gstDocumentFile,
      cancelChequeFile;

  // ─── Image URLs ────────────────────────────────────────────
  String? profilePhotoUrl,
      aadhaarFrontUrl,
      licenseFrontUrl,
      panDocumentUrl,
      gstCertificateUrl,
      cancelChequeUrl;

  // ─── Loading States ────────────────────────────────────────
  bool isLoading = false;
  bool isProfileLoading = false;
  bool isAadhaarLoading = false;
  bool isLicenseLoading = false;
  bool isPanLoading = false;
  bool isGstLoading = false;
  bool isCancelChequeLoading = false;
  bool isLoadingEmailOtp = false;
  bool isLoadingEmail = false;

  // ─── Email / OTP State ─────────────────────────────────────
  bool isSameNumber = false;
  bool isEmailOtpSent = false;
  bool isEmailVerified = false;
  int _secondsRemaining = 0;
  Timer? _timer;

  // ───────────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────────

  void toggleCheckbox(bool? value) {
    setState(() {
      isSameNumber = value ?? false;
      isSameNumber
          ? _whatsappController.text = _phoneController.text
          : _whatsappController.clear();
    });
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining == 0) {
        t.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
    setState(() {});
  }

  /// Central URL updater — eliminates all duplicate switch blocks
  void _onUploaded(String label, String? fileKey) {
    setState(() {
      switch (label) {
        case "Profile Photo":
          profilePhotoUrl = fileKey;
          break;
        case "PAN Card*":
          panDocumentUrl = fileKey;
          break;
        case "GST Certificate":
          gstCertificateUrl = fileKey;
          break;
        case "Driver License":
          licenseFrontUrl = fileKey;
          break;
        case "Aadhaar Card*":
          aadhaarFrontUrl = fileKey;
          break;
        case "Cancelled Cheque":
          cancelChequeUrl = fileKey;
          break;
      }
    });
  }

  // ───────────────────────────────────────────────────────────
  // VALIDATORS
  // ───────────────────────────────────────────────────────────

  bool isStepValid() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _addressController.text.isNotEmpty &&
            _postalCodeController.text.isNotEmpty &&
            _cityController.text.isNotEmpty &&
            _stateController.isNotEmpty;
      case 1:
        return RegExp(
              r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
            ).hasMatch(panNumberController.text) &&
            RegExp(
              r'^\d{12}$',
            ).hasMatch(aadhaarNumberController.text.replaceAll(' ', ''));
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

  // ───────────────────────────────────────────────────────────
  // PROFILE DATA
  // ───────────────────────────────────────────────────────────

  void setProfileData(Map data) {
    _nameController.text = data['fullName'] ?? data['ownerName'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['mobileNo'] ?? data['user']?['phone'] ?? '';
    _addressController.text = data['address'] ?? '';
    _addressLine2Controller.text = data['address1'] ?? '';
    _cityController.text = data['city'] ?? '';
    _stateController = data['state'] ?? '';
    _postalCodeController.text = data['pinCode'] ?? data['postalCode'] ?? '';
    _whatsappController.text = data['wa_number'] ?? '';
    aadhaarNumberController.text = data['aadhaarNumber'] ?? '';
    panNumberController.text = data['panNumber'] ?? '';
    drivingLicenseController.text = data['drivingLicenceNumber'] ?? '';
    gstNumberController.text = data['gstNumber'] ?? '';
    bankNameController.text = data['bankName'] ?? '';
    bankAccountController.text = data['accountNumber'] ?? '';
    confirmAccountController.text = data['accountNumber'] ?? '';
    ifscController.text = data['ifscCode'] ?? '';
    branchAddressController.text = data['branchAddress'] ?? '';

    profilePhotoUrl = data['profile_pic'] ?? '';
    aadhaarFrontUrl = data['aadhaarUpload'] ?? '';
    panDocumentUrl = data['panUpload'] ?? '';
    licenseFrontUrl = data['drivingLicenceUpload'] ?? '';
    gstCertificateUrl = data['gstCertificateUpload'] ?? '';
    cancelChequeUrl = data['cancel_cheque'] ?? '';

    isSameNumber = data['wa_number'] == data['user']?['phone'];
    setState(() {});
  }

  // ───────────────────────────────────────────────────────────
  // API CALLS
  // ───────────────────────────────────────────────────────────

  Future<void> sendOtpOnEmail() async {
    if (_emailController.text.isEmpty) {
      Utils.showErrorMessage(context, 'Please enter your email');
      return;
    }
    setState(() => isLoadingEmail = true);
    _startCountdown();

    final response = await Provider.of<SendOtpEmailProvider>(
      context,
      listen: false,
    ).sentOtpEmail(_emailController.text);

    if (!mounted) return;
    final data = json.decode(response.body);
    setState(() => isLoadingEmail = false);

    if (data['success'] == true) {
      setState(() => isEmailOtpSent = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));
    } else {
      Utils.showErrorMessage(
        context,
        data['message'] ?? 'Email OTP failed. Please try again.',
      );
    }
  }

  Future<void> _verifyEmailOtp() async {
    final otp = emailOtpControllers.map((e) => e.text).join();
    if (otp.length != 6) {
      Utils.showErrorMessage(context, 'Enter valid 6 digit Email OTP');
      return;
    }
    setState(() => isLoadingEmailOtp = true);

    final response = await Provider.of<EmailVerifyOtpProvider>(
      context,
      listen: false,
    ).verifyOtpEmail(_emailController.text, otp);

    if (!mounted) return;
    final data = json.decode(response.body);
    setState(() => isLoadingEmailOtp = false);

    if (data['success'] == true) {
      setState(() {
        isEmailVerified = true;
        isEmailOtpSent = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));
    } else {
      Utils.showErrorMessage(
        context,
        data['message'] ?? 'Email OTP failed. Please try again.',
      );
    }
  }

  Future<void> _updateProfile() async {
    setState(() => isLoading = true);
    try {
      final response = await Provider.of<OwnerProfileUpdateProvider>(
        context,
        listen: false,
      ).updateProfile(
        ownerName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        addressLine2: _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController,
        pinCode: _postalCodeController.text,
        wa_number: _whatsappController.text,
        panNumber: panNumberController.text,
        aadhaarNumber: aadhaarNumberController.text,
        gstNumber: gstNumberController.text,
        drivingLicenceNumber: drivingLicenseController.text,
        bankName: bankNameController.text,
        accountNumber: bankAccountController.text,
        ifscCode: ifscController.text,
        branchAddress: branchAddressController.text,
        panUpload: panDocumentUrl ?? '',
        aadhaarUpload: aadhaarFrontUrl ?? '',
        gstCertificateUpload: gstCertificateUrl ?? '',
        drivingLicenceUpload: licenseFrontUrl ?? '',
        profilePhotoUpload: profilePhotoUrl ?? '',
        cancelCheque: cancelChequeUrl ?? '',
      );

      setState(() => isLoading = false);
      final bool success = response['success'] ?? false;
      final String message = response['message'] ?? 'Profile update response';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success && mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────
  // LIFECYCLE
  // ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      await provider.fetchProfile('owner', 'owner', PrefUtils.getUserId());
      if (provider.profileData.isNotEmpty) setProfileData(provider.profileData);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // dispose all controllers
    for (final c in [
      _nameController,
      _emailController,
      _phoneController,
      _whatsappController,
      _addressController,
      _addressLine2Controller,
      _cityController,
      _postalCodeController,
      aadhaarNumberController,
      panNumberController,
      drivingLicenseController,
      gstNumberController,
      bankNameController,
      bankAccountController,
      confirmAccountController,
      ifscController,
      branchAddressController,
      ...emailOtpControllers,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────

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
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileData, _) {
          if (profileData.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // ── rewards data ──
          String percentage = '0', points = '0', complete = '0';

          bool isActive =false;
          if(profileData.profileData!=null){
            isActive  = profileData.profileData['user']['isActive'];
          }


          for (final r in profileData.rewardsProgress) {
            if (r['code'] == 'owner.profile_complete') {
              percentage = r['total_earned'].toString();
              points = r['points'].toString();
            }
            if (r['code'] == 'owner.vehicle_docs_complete') {
              complete = r['times_earned'].toString();
            }
          }
          return Column(
            children: [
              RewardsBar(
                isActive: isActive,
                percentage: percentage,
                points: points,
                complete: complete,
                pointsWallet: profileData.pointsWallet,
              ),
              Expanded(child: _buildStepper()),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEPPER
  // ───────────────────────────────────────────────────────────

  Widget _buildStepper() {
    return Stepper(
      type: StepperType.horizontal,
      currentStep: _currentStep,
      onStepCancel: () => setState(() => _currentStep--),
      controlsBuilder:
          (context, details) => Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Previous'),
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
                              if (_currentStep == 2) {
                                _updateProfile();
                              } else {
                                setState(() => _currentStep++);
                              }
                            },
                    child: Text(
                      _currentStep == 2 ? 'Update' : 'Next',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
      steps: [
        Step(
          title: const Text('Personal'),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          content: _PersonalStep(
            nameController: _nameController,
            phoneController: _phoneController,
            whatsappController: _whatsappController,
            emailController: _emailController,
            addressController: _addressController,
            addressLine2Controller: _addressLine2Controller,
            cityController: _cityController,
            postalCodeController: _postalCodeController,
            stateValue: _stateController,
            isSameNumber: isSameNumber,
            isEmailVerified: isEmailVerified,
            isEmailOtpSent: isEmailOtpSent,
            isLoadingEmail: isLoadingEmail,
            isLoadingEmailOtp: isLoadingEmailOtp,
            secondsRemaining: _secondsRemaining,
            emailOtpControllers: emailOtpControllers,
            onToggleCheckbox: toggleCheckbox,
            onStateChanged: (v) => setState(() => _stateController = v ?? ''),
            onSendOtp: () {
              sendOtpOnEmail();
              _startCountdown();
            },
            onVerifyOtp: _verifyEmailOtp,
            onChanged: () => setState(() {}),
          ),
        ),
        Step(
          title: const Text('Documents'),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          content: _DocumentsStep(
            panNumberController: panNumberController,
            aadhaarNumberController: aadhaarNumberController,
            drivingLicenseController: drivingLicenseController,
            gstNumberController: gstNumberController,
            profilePhotoFile: profilePhotoFile,
            aadhaarFrontFile: aadhaarFrontFile,
            licenseFrontFile: licenseFrontFile,
            panDocumentFile: panDocumentFile,
            gstDocumentFile: gstDocumentFile,
            profilePhotoUrl: profilePhotoUrl,
            aadhaarFrontUrl: aadhaarFrontUrl,
            licenseFrontUrl: licenseFrontUrl,
            panDocumentUrl: panDocumentUrl,
            gstCertificateUrl: gstCertificateUrl,
            isProfileLoading: isProfileLoading,
            isAadhaarLoading: isAadhaarLoading,
            isLicenseLoading: isLicenseLoading,
            isPanLoading: isPanLoading,
            isGstLoading: isGstLoading,
            picker: picker,
            onUploaded: _onUploaded,
            onFileSelected:
                (label, file) => setState(() {
                  switch (label) {
                    case "Profile Photo":
                      profilePhotoFile = file;
                      break;
                    case "Aadhaar Card*":
                      aadhaarFrontFile = file;
                      break;
                    case "Driver License":
                      licenseFrontFile = file;
                      break;
                    case "PAN Card*":
                      panDocumentFile = file;
                      break;
                    case "GST Certificate":
                      gstDocumentFile = file;
                      break;
                  }
                }),
            onLoadingChanged:
                (label, v) => setState(() {
                  switch (label) {
                    case "Profile Photo":
                      isProfileLoading = v;
                      break;
                    case "Aadhaar Card*":
                      isAadhaarLoading = v;
                      break;
                    case "Driver License":
                      isLicenseLoading = v;
                      break;
                    case "PAN Card*":
                      isPanLoading = v;
                      break;
                    case "GST Certificate":
                      isGstLoading = v;
                      break;
                  }
                }),
            onChanged: () => setState(() {}),
          ),
        ),
        Step(
          title: const Text('Bank'),
          isActive: _currentStep >= 2,
          state: StepState.indexed,
          content: _BankStep(
            bankNameController: bankNameController,
            bankAccountController: bankAccountController,
            confirmAccountController: confirmAccountController,
            ifscController: ifscController,
            branchAddressController: branchAddressController,
            cancelChequeFile: cancelChequeFile,
            cancelChequeUrl: cancelChequeUrl,
            isCancelChequeLoading: isCancelChequeLoading,
            picker: picker,
            onUploaded: _onUploaded,
            onFileSelected: (f) => setState(() => cancelChequeFile = f),
            onLoadingChanged: (v) => setState(() => isCancelChequeLoading = v),
            onChanged: () => setState(() {}),
            bankAccountText: bankAccountController.text,
          ),
        ),
      ],
    );
  }
}
// ═══════════════════════════════════════════════════════════════
// PERSONAL STEP
// ═══════════════════════════════════════════════════════════════

class _PersonalStep extends StatelessWidget {
  final TextEditingController nameController,
      phoneController,
      whatsappController,
      emailController,
      addressController,
      addressLine2Controller,
      cityController,
      postalCodeController;
  final String stateValue;
  final bool isSameNumber,
      isEmailVerified,
      isEmailOtpSent,
      isLoadingEmail,
      isLoadingEmailOtp;
  final int secondsRemaining;
  final List<TextEditingController> emailOtpControllers;
  final ValueChanged<bool?> onToggleCheckbox;
  final ValueChanged<String?> onStateChanged;
  final VoidCallback onSendOtp, onVerifyOtp, onChanged;

  const _PersonalStep({
    required this.nameController,
    required this.phoneController,
    required this.whatsappController,
    required this.emailController,
    required this.addressController,
    required this.addressLine2Controller,
    required this.cityController,
    required this.postalCodeController,
    required this.stateValue,
    required this.isSameNumber,
    required this.isEmailVerified,
    required this.isEmailOtpSent,
    required this.isLoadingEmail,
    required this.isLoadingEmailOtp,
    required this.secondsRemaining,
    required this.emailOtpControllers,
    required this.onToggleCheckbox,
    required this.onStateChanged,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonTextField(
          hint: 'Enter full name',
          controller: nameController,
          icon: Icons.person,
          isRequired: true,
          label: 'Full Name',
          onChanged: onChanged,
        ),
        CommonTextField(
          hint: 'Enter phone number',
          controller: phoneController,
          icon: Icons.phone,
          isRequired: true,
          isEditable: false,
          label: 'Phone Number',
          onChanged: onChanged,
        ),

        Row(
          children: [
            Checkbox(value: isSameNumber, onChanged: onToggleCheckbox),
            const Text(
              'WhatsApp number same as phone number',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),

        if (!isSameNumber)
          CommonTextField(
            hint: 'Enter WhatsApp number',
            controller: whatsappController,
            icon: FontAwesomeIcons.whatsapp.data,
            label: 'WhatsApp Number',
            onChanged: onChanged,
          ),

        const SizedBox(height: 10),
        EmailSection(
          emailController: emailController,
          otpControllers: emailOtpControllers,
          isEmailVerified: isEmailVerified,
          isEmailOtpSent: isEmailOtpSent,
          isLoadingEmail: isLoadingEmail,
          isLoadingEmailOtp: isLoadingEmailOtp,
          secondsRemaining: secondsRemaining,
          isValidEmail: Utils.isEmail,
          onSendOtp: onSendOtp,
          onVerifyOtp: onVerifyOtp,
          onChanged: onChanged,
        ),

        const SizedBox(height: 10),
        SectionTitle(title: "Address"),
        const SizedBox(height: 10),

        CommonTextField(
          hint: 'Enter address line 1',
          controller: addressController,
          icon: FontAwesomeIcons.locationDot.data,
          isRequired: true,
          label: 'Address Line 1',
          onChanged: onChanged,
        ),
        CommonTextField(
          hint: 'Enter address line 2',
          controller: addressLine2Controller,
          icon: FontAwesomeIcons.locationDot.data,
          label: 'Address Line 2',
          onChanged: onChanged,
        ),
        CommonTextField(
          hint: 'Enter pin code',
          controller: postalCodeController,
          icon: Icons.pin_drop,
          isRequired: true,
          label: 'Pin Code',
          onChanged: onChanged,
        ),
        CommonTextField(
          hint: 'Enter city',
          controller: cityController,
          icon: FontAwesomeIcons.city.data,
          isRequired: true,
          label: 'City',
          onChanged: onChanged,
        ),

        CommonDropdown(
          hint: 'Select State',
          label: 'State',
          value: stateValue.isEmpty ? null : stateValue,
          items: Utils.indiaStates,
          icon: Icons.location_on,
          isRequired: true,
          onChanged: onStateChanged,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DOCUMENTS STEP
// ═══════════════════════════════════════════════════════════════

class _DocumentsStep extends StatelessWidget {
  final TextEditingController panNumberController,
      aadhaarNumberController,
      drivingLicenseController,
      gstNumberController;
  final File? profilePhotoFile,
      aadhaarFrontFile,
      licenseFrontFile,
      panDocumentFile,
      gstDocumentFile;
  final String? profilePhotoUrl,
      aadhaarFrontUrl,
      licenseFrontUrl,
      panDocumentUrl,
      gstCertificateUrl;
  final bool isProfileLoading,
      isAadhaarLoading,
      isLicenseLoading,
      isPanLoading,
      isGstLoading;
  final ImagePicker picker;
  final Function(String, String?) onUploaded;
  final Function(String, File?) onFileSelected;
  final Function(String, bool) onLoadingChanged;
  final VoidCallback onChanged;

  const _DocumentsStep({
    required this.panNumberController,
    required this.aadhaarNumberController,
    required this.drivingLicenseController,
    required this.gstNumberController,
    required this.profilePhotoFile,
    required this.aadhaarFrontFile,
    required this.licenseFrontFile,
    required this.panDocumentFile,
    required this.gstDocumentFile,
    required this.profilePhotoUrl,
    required this.aadhaarFrontUrl,
    required this.licenseFrontUrl,
    required this.panDocumentUrl,
    required this.gstCertificateUrl,
    required this.isProfileLoading,
    required this.isAadhaarLoading,
    required this.isLicenseLoading,
    required this.isPanLoading,
    required this.isGstLoading,
    required this.picker,
    required this.onUploaded,
    required this.onFileSelected,
    required this.onLoadingChanged,
    required this.onChanged,
  });

  // Image boxes config — eliminates 5 duplicate ImageBox blocks
  List<Map<String, dynamic>> get _imageBoxes => [
    {
      'label': 'Profile Photo',
      'file': profilePhotoFile,
      'url': profilePhotoUrl,
      'loading': isProfileLoading,
    },
    {
      'label': 'Aadhaar Card*',
      'file': aadhaarFrontFile,
      'url': aadhaarFrontUrl,
      'loading': isAadhaarLoading,
    },
    {
      'label': 'Driver License',
      'file': licenseFrontFile,
      'url': licenseFrontUrl,
      'loading': isLicenseLoading,
    },
    {
      'label': 'PAN Card*',
      'file': panDocumentFile,
      'url': panDocumentUrl,
      'loading': isPanLoading,
    },
    {
      'label': 'GST Certificate',
      'file': gstDocumentFile,
      'url': gstCertificateUrl,
      'loading': isGstLoading,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: "Identity Verification"),
        const SizedBox(height: 20),

        CommonTextField(
          hint: 'Enter PAN Number',
          controller: panNumberController,
          icon: Icons.credit_card,
          label: 'PAN Number',
          isRequired: true,
          formatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) return 'PAN number is required';
            if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(v))
              return 'Enter a valid PAN (e.g. ABCDE1234F)';
            return null;
          },
        ),

        CommonTextField(
          hint: 'Enter Aadhaar Number',
          controller: aadhaarNumberController,
          icon: Icons.credit_card,
          label: 'Aadhaar Number',
          isRequired: true,
          keyboard: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Aadhaar number is required';
            if (v.length != 12) return 'Aadhaar must be 12 digits';
            if (!RegExp(r'^[2-9]{1}[0-9]{11}$').hasMatch(v))
              return 'Enter a valid Aadhaar number';
            return null;
          },
        ),

        CommonTextField(
          hint: 'Enter Driving License Number',
          controller: drivingLicenseController,
          icon: Icons.card_membership,
          label: 'Driving License Number',
          formatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(16),
          ],
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) return null; // optional
            if (!RegExp(r'^[A-Z]{2}[0-9]{2}[0-9]{4}[0-9]{7}$').hasMatch(v))
              return 'Enter a valid license (e.g. MH0120240001234)';
            return null;
          },
        ),

        CommonTextField(
          hint: 'Enter GST Number',
          controller: gstNumberController,
          icon: Icons.receipt_long,
          label: 'GST Number',
          formatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(15),
          ],
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) return null; // optional
            if (!RegExp(
              r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
            ).hasMatch(v))
              return 'Enter a valid GST (e.g. 27ABCDE1234F1Z5)';
            return null;
          },
        ),

        const SizedBox(height: 20),
        SectionTitle(title: "Document Uploads"),

        // ✅ Single loop replaces 5 duplicate ImageBox widgets
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          padding: const EdgeInsets.all(8),
          children:
              _imageBoxes.map((box) {
                final label = box['label'] as String;
                return ImageBox(
                  label: label,
                  localFile: box['file'] as File?,
                  url: box['url'] as String?,
                  isLoading: box['loading'] as bool,
                  picker: picker,
                  callback: (f) => onFileSelected(label, f),
                  setLoading: (v) => onLoadingChanged(label, v),
                  onUploaded: onUploaded,
                );
              }).toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BANK STEP
// ═══════════════════════════════════════════════════════════════

class _BankStep extends StatelessWidget {
  final TextEditingController bankNameController,
      bankAccountController,
      confirmAccountController,
      ifscController,
      branchAddressController;
  final File? cancelChequeFile;
  final String? cancelChequeUrl;
  final bool isCancelChequeLoading;
  final ImagePicker picker;
  final String bankAccountText;
  final Function(String, String?) onUploaded;
  final Function(File?) onFileSelected;
  final Function(bool) onLoadingChanged;
  final VoidCallback onChanged;

  const _BankStep({
    required this.bankNameController,
    required this.bankAccountController,
    required this.confirmAccountController,
    required this.ifscController,
    required this.branchAddressController,
    required this.cancelChequeFile,
    required this.cancelChequeUrl,
    required this.isCancelChequeLoading,
    required this.picker,
    required this.bankAccountText,
    required this.onUploaded,
    required this.onFileSelected,
    required this.onLoadingChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: "Bank Details"),
        const SizedBox(height: 20),
        CommonTextField(
          hint: 'Enter bank name',
          controller: bankNameController,
          icon: Icons.account_balance,
          label: 'Bank Name',
          isRequired: true,
          onChanged: onChanged,
          validator:
              (v) => (v == null || v.isEmpty) ? 'Bank name is required' : null,
        ),

        CommonTextField(
          hint: 'Enter account number',
          controller: bankAccountController,
          icon: Icons.account_balance,
          label: 'Account Number',
          isRequired: true,
          isObscure: true,
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Account number is required';
            if (!RegExp(r'^\d{9,18}$').hasMatch(v))
              return 'Enter valid account number (9–18 digits)';
            return null;
          },
        ),

        CommonTextField(
          hint: 'Re-enter account number',
          controller: confirmAccountController,
          icon: Icons.account_balance,
          label: 'Confirm Account Number',
          isRequired: true,
          isObscure: true,
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm account number';
            if (v != bankAccountText) return 'Account numbers do not match';
            return null;
          },
        ),

        CommonTextField(
          hint: 'Enter IFSC code (e.g. SBIN0001234)',
          controller: ifscController,
          icon: Icons.numbers,
          label: 'IFSC Code',
          isRequired: true,
          formatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(11),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) return 'IFSC code is required';
            if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v))
              return 'Invalid IFSC (e.g. SBIN0001234)';
            return null;
          },
        ),

        CommonTextField(
          hint: 'Enter branch address',
          controller: branchAddressController,
          icon: Icons.location_on,
          label: 'Branch Address',
          maxLines: 3,
          onChanged: onChanged,
        ),

        const SizedBox(height: 20),
        SectionTitle(title: "Cancelled Cheque"),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ImageBox(
            label: 'Cancelled Cheque',
            localFile: cancelChequeFile,
            url: cancelChequeUrl,
            isLoading: isCancelChequeLoading,
            picker: picker,
            callback: (f) => onFileSelected(f),
            setLoading: (v) => onLoadingChanged(v),
            onUploaded: onUploaded,
          ),
        ),
      ],
    );
  }
}
