import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider_service/file_upload_provider.dart';
import '../../provider_service/upload_vehicle_documents_bulk_provider.dart';
import '../../resource/Utils.dart';
import '../../resource/app_colors.dart';

class DocumentUploadDialog extends StatefulWidget {
  final String vehicleId;
  final String title;

  const DocumentUploadDialog(this.vehicleId, this.title, {super.key});

  @override
  State<DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  DateTime? validFrom;
  DateTime? validTo;
  final _companyNameController = TextEditingController();
  final _policyNumberController = TextEditingController();

  bool isLoading = false;

  String? document_type;
  String? file_path;
  String? original_filename;
  String? file_type;
  String? uploadUrl;
  String? state;

  final picker = ImagePicker();
  final DateFormat formatter = DateFormat('dd/MM/yyyy');

  /// DATE PICKER
  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          validFrom = picked;
        } else {
          validTo = picked;
        }
      });
    }
  }

  String _format(DateTime? date) {
    if (date == null) return "dd/mm/yyyy";
    return formatter.format(date);
  }

  String _formatAPI(DateTime? date) {
    if (date == null) return "";
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// IMAGE PICKER
  Future<void> pickImage(Function(File file) onPicked, String type) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      onPicked(file);

      /// detect file type
      String extension = file.path.split('.').last;

      file_type = extension;
      if (widget.title == 'RC Certificate') {
        document_type = 'rc_document';
      } else if (widget.title == 'Fitness Certificate') {
        document_type = 'fitness_certificate';
      } else if (widget.title == 'Permit Document') {
        document_type = 'permit_document';
      } else if (widget.title == 'Insurance') {
        document_type = 'insurance';
      } else if (widget.title == 'Pollution Cert.') {
        document_type = 'pollution_certificate';
      }
      await _fileUpload('vehicle-documents', file, type);
    }
  }

  /// FILE UPLOAD API
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
        uploadUrl = fileKey;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response['message'])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response?['message'] ?? 'Upload failed')),
      );
    }
  }

  /// LOADING DIALOG
  Future<void> showUploadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(minHeight: 8),
                  SizedBox(height: 16),
                  Text("Uploading document..."),
                ],
              ),
            ),
          ),
    );
  }

  /// FINAL API CALL
  Future<void> _updateDocuments() async {
    /// VALIDATION
    if (file_path == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a file")));
      return;
    }

    if (validFrom == null || validTo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select dates")));
      return;
    }

    setState(() => isLoading = true);

    await Provider.of<UploadVehicleDocumentsBulkProvider>(
      context,
      listen: false,
    ).updateDocumentsBulk(
      vehicleId: widget.vehicleId,
      document_type: document_type ?? "document",
      file_path: uploadUrl ?? file_path!,
      original_filename: original_filename ?? "file",
      file_type: file_type ?? "jpg",
      valid_from: _formatAPI(validFrom),
      valid_to: _formatAPI(validTo),
      issued_state: state,
      company_name: _companyNameController.text.trim(),
      policy_number: _policyNumberController.text.trim(),
    );

    final success =
        Provider.of<UploadVehicleDocumentsBulkProvider>(
          context,
          listen: false,
        ).success;

    setState(() => isLoading = false);

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents updated successfully')),
      );
      Navigator.pop(context);
    }
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F9D8A), Color(0xFF0B6E63)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DOCUMENT UPLOAD",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            /// BODY
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.title == 'Pollution Cert.'
                      ? DropdownButtonFormField<String>(
                        value: state,
                        hint: const Text("Select State"),
                        items:
                            Utils.indiaStates.map((e) {
                              return DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              );
                            }).toList(),
                        onChanged: (v) {
                          setState(() {
                            state = v;
                          });
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),

                          // ✅ Rectangle border
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // small radius = rectangle look
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.teal,
                              width: 2,
                            ),
                          ),
                        ),
                      )
                      : SizedBox(),

                  widget.title == 'Insurance'
                      ? Column(
                        children: [
                          textField(
                            "Company Name",
                            _companyNameController,
                            Icons.house,
                          ),

                          textField(
                            "Policy Number",
                            _policyNumberController,
                            Icons.numbers,
                          ),
                        ],
                      )
                      : SizedBox(),
                  widget.title == 'Pollution Cert.' ||
                          widget.title == 'Insurance'
                      ? const SizedBox(height: 12)
                      : SizedBox(),

                  /// DATE
                  const Text(
                    "Validity Period",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _dateField("Valid From", true)),
                      const SizedBox(width: 12),
                      Expanded(child: _dateField("Valid To", false)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// FILE UPLOAD
                  const Text(
                    "Upload File",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () {
                      pickImage((file) {
                        setState(() {
                          file_path = file.path;
                          original_filename = file.path.split('/').last;
                        });
                      }, "vehicle_doc");
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.upload_file,
                            size: 40,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text("Click to upload"),
                          const SizedBox(height: 4),

                          if (original_filename != null)
                            Text(
                              original_filename!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updateDocuments,
                          child:
                              isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text("Upload & Save"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// DATE FIELD UI
  Widget _dateField(String label, bool isFrom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickDate(isFrom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(isFrom ? validFrom : validTo)),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),
      ],
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
}
