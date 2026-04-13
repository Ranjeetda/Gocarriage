import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gocarriage_universal/resource/pref_utils.dart';
import 'package:http/http.dart' as http;
import '../eventModel/notification_event.dart';
import 'booking_provider.dart';
import 'URLS.dart';

class DriverBooingRequestProvider extends ChangeNotifier {
  final BookingProvider _bookingProvider;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  StreamSubscription? _subscription;

  DriverBooingRequestProvider(this._bookingProvider) {
    debugPrint("🔥 DriverBooingRequestProvider Created");
    _listenNotification();
  }

  void _listenNotification() {
    _subscription = eventBus.on<NotificationEvent>().listen((event) {
      debugPrint("🔥 EVENT RECEIVED IN PROVIDER");

      final type = event.message.data['type'];
      final bookingId = event.message.data['bookingId'];

      debugPrint("Type: $type");
      debugPrint("BookingId: $bookingId");

      if (type == 'TRIP_COMPLETED') {
        _bookingProvider.cancelRide();
        notifyListeners();
      }

      if (type == 'NEW_BOOKING' &&
          bookingId != null &&
          bookingId.toString().isNotEmpty) {
        getBookingDetails(bookingId.toString());
      }
      if (type == 'BOOKING_ACCEPTED' &&
          bookingId != null &&
          bookingId.toString().isNotEmpty) {
        getBookingDetails(bookingId.toString());
      }
    });
  }

  Future<void> getBookingDetails(String bookingId) async {
    try {
      debugPrint("🔥 API CALL START");
      debugPrint("📌 Booking ID: $bookingId");

      _isLoading = true;
      notifyListeners();

      final url = Uri.parse(
        PrefUtils.getRole() == "customer"
            ? URLS.customerBooking + bookingId
            : URLS.driverBooking + bookingId,
      );

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${PrefUtils.getToken()}',
      };

      final response = await http.get(url, headers: headers);

      debugPrint("✅ Status Code: ${response.statusCode}");
      debugPrint("📥 Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _bookingProvider.setUpcomingRide(
            Map<String, dynamic>.from(responseData['data']),
          );
          debugPrint("🎉 Booking data set successfully");
        }
      }
    } catch (e, stackTrace) {
      debugPrint("❌ API ERROR: $e");
      debugPrint("🧵 StackTrace: $stackTrace");
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint("🏁 API CALL END");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
