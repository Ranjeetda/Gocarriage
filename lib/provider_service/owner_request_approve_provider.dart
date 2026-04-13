import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/Utils.dart';
import '../resource/pref_utils.dart';
import 'URLS.dart';

class OwnerRequestApproveProvider with ChangeNotifier {
  Future<http.Response> acceptRequest(
      String mRequestId,
      String status,
      String approvedPermissionIds,
      ) async {
    final Uri url = Uri.parse(URLS.requestAcceptOwner+mRequestId);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${PrefUtils.getToken()}',
    };

    final Map<String, dynamic> requestBody = {
      "status": status,
      "approved_permission_ids": approvedPermissionIds,
    };

    final String body = jsonEncode(requestBody);

    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Request Accept Owner REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");

    try {
      final http.Response response =
      await http.put(url, headers: headers, body: body);

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 Request Accept Owner RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 Request Accept Owner ERROR: $error");
      throw Exception('Failed to Request Accept Owner: $error');
    }
  }
}
