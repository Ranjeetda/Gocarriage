import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'URLS.dart';

class CheckAreaProvider with ChangeNotifier {

  Future<http.Response> checkArea(
      String pinCode,
      ) async {
    final Uri url = Uri.parse(URLS.clustersPinCheck+pinCode);

    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };


    /// 🔹 PRINT REQUEST
    debugPrint("🔵 Area IN REQUEST");
    debugPrint("URL: $url");
    debugPrint("Headers: $headers");

    try {
      final http.Response response =
      await http.get(url, headers: headers);


      /// 🔹 PRINT RESPONSE
      debugPrint("🟢 SIGN IN RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      if (response.statusCode == 200) {
        return response;
      } else {
        print('Area in failed: ${response.body}');
        return response;
      }

      return response;
    } catch (error) {
      debugPrint("🔴 Area IN ERROR: $error");
      throw Exception('Failed to sign in: $error');
    }
  }
}

