import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider_service/fetch_image_url_provider.dart';
import '../../provider_service/file_upload_provider.dart';

import 'dart:convert';

import '../../resource/app_colors.dart';

class ImageBox extends StatefulWidget {
  final String label;
  final File? localFile;
  final String? url;
  final Function(File) callback;
  final bool isLoading;
  final Function(bool) setLoading;
  final ImagePicker picker;
  final Function(String label, String? fileKey) onUploaded;

  const ImageBox({
    super.key,
    required this.label,
    required this.localFile,
    required this.url,
    required this.callback,
    required this.isLoading,
    required this.setLoading,
    required this.picker,
    required this.onUploaded, // ← parent updates its own URL state
  });

  @override
  State<ImageBox> createState() => _ImageBoxState();
}

class _ImageBoxState extends State<ImageBox> {
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
    final pickedFile = await widget.picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      widget.callback(file); // update parent UI
      _fileUpload('owners', file, fileType);
    }
  }

  Future<void> _fileUpload(
    String folderName,
    File? fileName,
    String mType,
  ) async {
    if (fileName == null) return;

    _showUploadingDialog();

    final response = await Provider.of<FileUploadProvider>(
      context,
      listen: false,
    ).uploadFileOnServer(folder: folderName, mFile: fileName);

    if (!mounted) return;
    Navigator.pop(context); // close uploading dialog

    if (response != null && response['success'] == true) {
      final fileKey = response['data']?['key'];
      widget.onUploaded(mType, fileKey); // ← tell parent to update its URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Uploaded successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response?['message'] ?? 'Upload failed')),
      );
    }
  }

  Future<void> _showImage(String fileName) async {
    widget.setLoading(true);

    final response = await Provider.of<FetchImageUrlProvider>(
      context,
      listen: false,
    ).fetchImagePath(fileName);

    if (!mounted) return;

    final responseData = json.decode(response.body);
    widget.setLoading(false);

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

  void _showUploadingDialog() {
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

  void _showImagePreview(String imageUrl) {
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

  @override
  Widget build(BuildContext context) {
    final safeUrl =
        (widget.url != null && widget.url!.isNotEmpty)
            ? Uri.encodeFull(widget.url!)
            : null;

    return GestureDetector(
      onTap: () => pickImage(widget.callback, widget.label),
      child: Container(
        height: 175,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1.5),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.localFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.localFile!,
                        height: 85,
                        width: 85,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (safeUrl != null)
                    const Icon(
                      Icons.check_circle,
                      size: 50,
                      color: Colors.green,
                    )
                  else
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
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
            ),

            // 👁 View Button
            if (safeUrl != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showImage(safeUrl),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child:
                        widget.isLoading
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
}

class CommonTextField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboard;
  final List<TextInputFormatter>? formatters;
  final bool enabled;
  final bool isEditable;
  final String? Function(String?)? validator;
  final String? label;
  final VoidCallback? onChanged;

  /// Called when text field is tapped
  final VoidCallback? onTap;

  /// Called when prefix icon is tapped
  final VoidCallback? onIconTap;

  final int? maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final bool isRequired;
  final bool isObscure;

  /// OTP / Verify support
  final bool isVerified;
  final bool isOtpSent;
  final bool isLoadingAction;
  final int secondsRemaining;
  final VoidCallback? onSendOtp;

  const CommonTextField({
    Key? key,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.formatters,
    this.enabled = true,
    this.isEditable = true,
    this.validator,
    this.label,
    this.onChanged,
    this.onTap,
    this.onIconTap,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.isRequired = false,
    this.isObscure = false,
    this.isVerified = false,
    this.isOtpSent = false,
    this.isLoadingAction = false,
    this.secondsRemaining = 0,
    this.onSendOtp,
  }) : super(key: key);

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isObscure;
  }

  Widget _buildLabel(String text) {
    if (!widget.isRequired) return Text(text);

    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isVerified) {
      return const Icon(Icons.verified, color: Colors.green);
    }

    if (widget.isObscure) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        child: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
      );
    }

    if (widget.onSendOtp != null) {
      final bool canSend =
          !widget.isLoadingAction &&
          !(widget.isOtpSent && widget.secondsRemaining > 0);

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextButton(
          onPressed: canSend ? widget.onSendOtp : null,
          child:
              widget.isLoadingAction
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(
                    widget.isOtpSent
                        ? (widget.secondsRemaining > 0
                            ? "Resend (${widget.secondsRemaining}s)"
                            : "Resend")
                        : "Send OTP",
                  ),
        ),
      );
    }

    if (!widget.isEditable) {
      return const Icon(Icons.lock_outline, color: Colors.grey, size: 18);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final labelText = widget.label ?? widget.hint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboard,
        inputFormatters: widget.formatters,
        enabled: widget.enabled && !widget.isVerified,
        readOnly: !widget.isEditable,
        validator: widget.validator,
        maxLines: widget.isObscure ? 1 : widget.maxLines,
        maxLength: widget.maxLength,
        obscureText: _obscureText,
        textCapitalization: widget.textCapitalization,
        autovalidateMode: AutovalidateMode.onUserInteraction,

        onChanged: (_) => widget.onChanged?.call(),

        /// TextField Tap
        onTap: widget.onTap,

        decoration: InputDecoration(
          /// Clickable Prefix Icon
          prefixIcon:
              widget.onIconTap != null
                  ? IconButton(
                    onPressed: widget.onIconTap,
                    icon: Icon(
                      widget.icon,
                      color:
                          widget.isVerified
                              ? Colors.green
                              : widget.isEditable
                              ? AppColors.primaryColor
                              : Colors.grey,
                    ),
                  )
                  : Icon(
                    widget.icon,
                    color:
                        widget.isVerified
                            ? Colors.green
                            : widget.isEditable
                            ? AppColors.primaryColor
                            : Colors.grey,
                  ),

          suffixIcon: _buildSuffixIcon(),

          label: _buildLabel(labelText),
          hintText: widget.hint,
          floatingLabelBehavior: FloatingLabelBehavior.auto,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.isVerified ? Colors.green : AppColors.primaryColor,
              width: 2,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.isVerified ? Colors.green : Colors.grey.shade400,
            ),
          ),

          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.isVerified ? Colors.green : Colors.grey.shade300,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),

          filled: true,
          fillColor:
              widget.isVerified
                  ? Colors.green.shade50
                  : widget.isEditable
                  ? Colors.white
                  : Colors.grey.shade100,
        ),
      ),
    );
  }
}

// lib/resource/otp_boxes.dart

class OtpBoxes extends StatelessWidget {
  final List<TextEditingController> controllers;
  final int length;
  final VoidCallback? onCompleted;

  const OtpBoxes({
    super.key,
    required this.controllers,
    this.length = 6,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (i) {
        return SizedBox(
          width: 48,
          height: 55,
          child: TextFormField(
            controller: controllers[i],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < length - 1) {
                FocusScope.of(context).nextFocus();
              } else if (v.isEmpty && i > 0) {
                FocusScope.of(context).previousFocus();
              }

              // ✅ trigger onCompleted when all boxes filled
              if (controllers.every((c) => c.text.isNotEmpty)) {
                onCompleted?.call();
              }
            },
          ),
        );
      }),
    );
  }
}

// lib/resource/email_section.dart

class EmailSection extends StatelessWidget {
  final TextEditingController emailController;
  final List<TextEditingController> otpControllers;
  final bool isEmailVerified;
  final bool isEmailOtpSent;
  final bool isLoadingEmail;
  final bool isLoadingEmailOtp;
  final int secondsRemaining;
  final bool Function(String) isValidEmail;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onChanged;

  const EmailSection({
    super.key,
    required this.emailController,
    required this.otpControllers,
    required this.isEmailVerified,
    required this.isEmailOtpSent,
    required this.isLoadingEmail,
    required this.isLoadingEmailOtp,
    required this.secondsRemaining,
    required this.isValidEmail,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Email field using CommonTextField
        CommonTextField(
          hint: 'Enter email',
          controller: emailController,
          icon: Icons.email_outlined,
          label: 'Email Address',
          isRequired: false,
          keyboard: TextInputType.emailAddress,
          isVerified: isEmailVerified,
          isOtpSent: isEmailOtpSent,
          isLoadingAction: isLoadingEmail,
          secondsRemaining: secondsRemaining,
          onSendOtp: isValidEmail(emailController.text) ? onSendOtp : null,
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            return isValidEmail(v) ? null : 'Enter a valid email';
          },
        ),

        // ✅ OTP boxes + confirm button
        if (isEmailOtpSent && !isEmailVerified) ...[
          const SizedBox(height: 12),
          OtpBoxes(
            controllers: otpControllers,
            length: 6,
            onCompleted: onVerifyOtp, // auto verify when all boxes filled
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isLoadingEmailOtp ? null : onVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

        // ✅ Verified badge
        if (isEmailVerified) ...[
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Text(
                "Email Verified",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// lib/resource/mobile_section.dart

class MobileSection extends StatelessWidget {
  final TextEditingController mobileController;
  final List<TextEditingController> otpControllers;

  final bool isMobileVerified;
  final bool isMobileOtpSent;
  final bool isLoadingMobile;
  final bool isLoadingMobileOtp;
  final int secondsRemaining;

  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onChanged;
  final VoidCallback? onChangeMobile;

  const MobileSection({
    super.key,
    required this.mobileController,
    required this.otpControllers,
    required this.isMobileVerified,
    required this.isMobileOtpSent,
    required this.isLoadingMobile,
    required this.isLoadingMobileOtp,
    required this.secondsRemaining,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onChanged,
    this.onChangeMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Mobile Field
        CommonTextField(
          hint: 'Enter mobile number',
          controller: mobileController,
          icon: Icons.phone_android,
          label: 'Mobile Number',
          keyboard: TextInputType.number,
          isRequired: false,
          enabled: !isMobileVerified,
          maxLength: 10,
          isVerified: isMobileVerified,
          isOtpSent: isMobileOtpSent,
          isLoadingAction: isLoadingMobile,
          secondsRemaining: secondsRemaining,
          onSendOtp: mobileController.text.length == 10 ? onSendOtp : null,
          onChanged: onChanged,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Mobile number is required';
            }
            if (v.length != 10) {
              return 'Enter a valid mobile number';
            }
            return null;
          },
        ),

        /// OTP Section
        if (isMobileOtpSent && !isMobileVerified) ...[
          const SizedBox(height: 12),
          OtpBoxes(
            controllers: otpControllers,
            length: 6,
            onCompleted: onVerifyOtp,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isLoadingMobileOtp ? null : onVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondarycolor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

        /// Verified Section
        if (isMobileVerified) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Mobile Verified",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (onChangeMobile != null)
                TextButton(
                  onPressed: onChangeMobile,
                  child: const Text("Change"),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// lib/resource/common_dropdown.dart
class CommonDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? label;
  final bool isRequired;
  final IconData? icon;
  final String? Function(String?)? validator;

  const CommonDropdown({
    super.key,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.isRequired = false,
    this.icon,
    this.validator,
  });

  Widget _buildLabel(String text) {
    if (!isRequired) return Text(text);
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelText = label ?? hint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator:
            validator ??
            (v) {
              if (isRequired && (v == null || v.isEmpty)) {
                return '$labelText is required';
              }
              return null;
            },
        decoration: InputDecoration(
          label: _buildLabel(labelText),
          hintText: hint,
          prefixIcon:
              icon != null ? Icon(icon, color: AppColors.primaryColor) : null,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        hint: Text(hint, style: TextStyle(color: Colors.grey.shade500)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        items:
            items.map((e) {
              return DropdownMenuItem<String>(value: e, child: Text(e));
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class CommonDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateSelected;
  final String? Function(String?)? validator;

  const CommonDatePicker({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CommonTextField(
      hint: hint,
      controller: controller,
      icon: Icons.calendar_month,
      label: label,
      isRequired: isRequired,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate:
              controller.text.isNotEmpty
                  ? DateFormat("yyyy-MM-dd").parse(controller.text)
                  : DateTime.now(),
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
        );

        if (picked != null) {
          controller.text = DateFormat("yyyy-MM-dd").format(picked);
          onDateSelected?.call(picked);
        }
      },
      validator: validator,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REWARDS BAR
// ═══════════════════════════════════════════════════════════════

class RewardsBar extends StatelessWidget {
  final String percentage, points, complete;
  final bool isActive;
  final Map<String, dynamic> pointsWallet;

  const RewardsBar({
    required this.percentage,
    required this.points,
    required this.complete,
    required this.pointsWallet,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: const Color(0xFF0F766E),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.track_changes, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentage}% completed · $complete/4',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'All sections complete!',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: isActive == true ? 100 : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.yellow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _StatBox('WALLET', '₹ ${pointsWallet['balance']}'),
              const SizedBox(width: 8),
              _StatBox('LIFETIME', '₹ ${pointsWallet['lifetime_earned']}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title, value;

  const _StatBox(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  final double fontSize;

  const SectionTitle({
    super.key,
    required this.title,
    this.color = Colors.green,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
