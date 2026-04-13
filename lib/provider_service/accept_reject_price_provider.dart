import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../resource/Utils.dart';
import '../resource/pref_utils.dart';
import 'URLS.dart';

class AcceptRejectPriceProvider with ChangeNotifier {
  Future<http.Response> validateAcceptReject(String id,String action) async {
    final Uri url = Uri.parse("${URLS.quatationsService}/$id/$action");
    debugPrint("URL: $url");
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${PrefUtils.getToken()}',
      };

      final http.Response response =
      await http.patch(url,headers: headers);

      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 AcceptReject IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      return response;
    } catch (error) {
      debugPrint("🔴 AcceptReject IN ERROR: $error");
      throw Exception('Failed to AcceptReject in: $error');
    }
  }
}
