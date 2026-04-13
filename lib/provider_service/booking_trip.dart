import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../resource/pref_utils.dart';
import '../ui/model/booking_trip_request.dart';
import 'URLS.dart';

class BookingTrip with ChangeNotifier {

  Future<http.Response> bookingTrip(
      BookingTripRequest bookingRequest) async {

    final url = Uri.parse(URLS.bookingTrip);

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${PrefUtils.getToken()}",
    };

    final body = jsonEncode(bookingRequest.toJson());

    // 🔹 REQUEST LOG
    debugPrint("========== BOOKING TRIP REQUEST ==========");
    debugPrint("URL: $url");
    debugPrint("HEADERS: $headers");
    debugPrint("BODY: $body");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // 🔹 RESPONSE LOG
      debugPrint("========== BOOKING TRIP RESPONSE ==========");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Booking Trip Successful");
      } else {
        debugPrint("❌ Booking Trip Failed");
      }

      return response;

    } catch (error) {
      debugPrint("🔥 BOOKING TRIP ERROR: $error");
      throw Exception('Booking Trip failed: $error');
    }
  }
}
