import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../resource/pref_utils.dart';
import 'URLS.dart';

class ClusterCheckProvider with ChangeNotifier {

  Future<http.Response> clusterCheck(
      String pincode1,
      String pincode2,
      ) async {

    /// ---------------- URL ----------------
    final Uri url = Uri.parse(URLS.clustersCheckSame);

    /// ---------------- HEADERS ----------------
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${PrefUtils.getToken()}",
    };

    /// ---------------- BODY ----------------
    late Map<String, dynamic> bodyMap;

    bodyMap = {
      "pincode1": pincode1,
      "pincode2": pincode2,
    };

    final body = jsonEncode(bodyMap);

    debugPrint("Cluster chek same URL: $url");
    debugPrint("Cluster chek same Body: $body");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint("Cluster chek same Status: ${response.statusCode}");
      debugPrint("Cluster chek same Response: ${response.body}");

      return response;

    } catch (e) {
      throw Exception("Cluster chek same failed: $e");
    }
  }
}
