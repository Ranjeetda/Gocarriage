import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../resource/pref_utils.dart';
import '../resource/Utils.dart';
import 'URLS.dart';

class VehicleDocumentsBulkProvider with ChangeNotifier {
  bool _isUpdating = false;
  String _message = '';

  bool get isUpdating => _isUpdating;
  String get message => _message;
   String TAG = "UPLOAD_DOC";
  Future<Map<String, dynamic>?> validateVehicleBuckDocumentUpload({
    required String mVehicleId,
    required List<Map<String, dynamic>> documents,
  }) async {
    _isUpdating = true;
    notifyListeners();

    final url = "${URLS.vehicleDocumentsBulk}/$mVehicleId";

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${PrefUtils.getToken()}",
    };

    final body = jsonEncode({
      "documents": documents,
    });

    /// 🔵 REQUEST LOG
    debugPrint("📤 [UPLOAD_DOC] REQUEST START =====================");
    debugPrint("📤 [UPLOAD_DOC] URL: $url");
    debugPrint("📤 [UPLOAD_DOC] HEADERS: $headers");
    Utils.printFullText("📤 [UPLOAD_DOC] BODY: $body");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);

      /// 🟢 RESPONSE LOG
      debugPrint("📥 [UPLOAD_DOC] RESPONSE =====================");
      debugPrint("📥 [UPLOAD_DOC] STATUS: ${response.statusCode}");
      Utils.printFullText("📥 [UPLOAD_DOC] RAW: ${response.body}");

      const encoder = JsonEncoder.withIndent('  ');
      debugPrint("📥 [UPLOAD_DOC] FORMATTED:\n${encoder.convert(responseData)}");

      if (response.statusCode == 200 && responseData['success'] == true) {
        _message = responseData['message'] ?? "Success";
      } else {
        _message = responseData['message'] ?? "Failed";
      }

      return responseData;
    } catch (e) {
      debugPrint("❌ [UPLOAD_DOC] ERROR: $e");
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
      debugPrint("🔚 [UPLOAD_DOC] REQUEST END =====================");
    }
  }
}