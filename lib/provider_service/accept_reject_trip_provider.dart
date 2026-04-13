import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../resource/pref_utils.dart';
import 'URLS.dart';
import 'accept_reject_provider.dart';

class AcceptRejectTripProvider with ChangeNotifier {
  AcceptRejectProvider? acceptedRejectedProvider;

  /// Call this when you create this provider
  void setAcceptRejectProvider(AcceptRejectProvider provider) {
    acceptedRejectedProvider = provider;
  }

  Future<http.Response> acceptRejectTrip(
      String type, String bookingId) async {
    final Uri url = Uri.parse(
      type == "Accept"
          ? URLS.bookingAccept
          : URLS.bookingReject,
    );

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${PrefUtils.getToken()}",
    };

    final String body = jsonEncode({
      "bookingId": bookingId,
    });

    print('Url: $url');
    print('Request Body: $body');

    try {
      final http.Response response =
      await http.post(url, headers: headers, body: body);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        /// Decode JSON string → Map
        final Map<String, dynamic> decodedResponse =
        jsonDecode(response.body);

        /// Update another provider safely
        acceptedRejectedProvider?.setUpcomingRide(decodedResponse);

        notifyListeners();
      }

      return response;
    } catch (e) {
      throw Exception('Failed to Accept/Reject Ride: $e');
    }
  }
}
