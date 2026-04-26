import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import 'URLS.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/pref_utils.dart';
import 'URLS.dart';

class UploadVehicleDocumentsBulkProvider with ChangeNotifier {
  bool _isUpdating = false;
  bool _success = false;
  String _message = '';

  bool get isUpdating => _isUpdating;

  String get message => _message;

  bool get success => _success;

  Future<void> updateDocumentsBulk({
    required String vehicleId,
    required String document_type,
    required String file_path,
    required String original_filename,
    required String file_type,
    required String valid_from,
    required String valid_to,
    required String? issued_state,
    required String company_name,
    required String policy_number,
  }) async {
    final Uri url = Uri.parse(URLS.uploadVehicleDocumentsBulk + vehicleId);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Area IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");


    try {
      Map<String, dynamic> document = {
        "document_type": document_type,
        "file_path": file_path,
        "original_filename": original_filename,
        "file_type": "image/png",
        "valid_from": valid_from,
        "valid_to": valid_to,
        if (issued_state?.isNotEmpty ?? false) "issued_state": issued_state,
        if (company_name?.isNotEmpty ?? false) "company_name": company_name,
        if (policy_number?.isNotEmpty ?? false) "policy_number": policy_number,
      };

      Map<String, dynamic> payload = {
        "documents": [document],
      };

      final String body = jsonEncode(payload);

      debugPrint("Reqeust Body: ${body}");

      final http.Response response = await http.post(
        url,
        body: body,
        headers: headers,
      );

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 VERIFY OTP IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      final responseData = json.decode(response.body);
      _success = responseData['success'];
      if (response.statusCode == 200 && _success == true) {
        _message = responseData['message'] ?? 'Documents updated successfully';
      } else {
        _message = responseData['message'] ?? 'Failed to update documents';
        debugPrint("ELse Response Body: ${_message}");
      }
    } catch (error) {
      debugPrint("🔴 Update documents In ERROR: $error");
      throw Exception('Failed to Update profile in: $error');
    }
  }

}
