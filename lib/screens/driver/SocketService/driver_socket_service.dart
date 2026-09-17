import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../provider_service/URLS.dart';
import '../../../provider_service/booking_provider.dart';
import '../../../resource/pref_utils.dart';

class DriverSocketService {
  static final DriverSocketService _instance = DriverSocketService._internal();
  factory DriverSocketService() => _instance;
  DriverSocketService._internal();

  IO.Socket? _socket;
  BookingProvider? _bookingProvider;

  bool _isConnecting = false;
  int? _userId;
  bool _isCustomer = false;

  // ================= POLLING STATE =================
  Timer? _bookingPollingTimer;
  String? _currentPollingBookingId;
  bool _isPollingActive = false;

  void attachProvider(BookingProvider provider) {
    _bookingProvider = provider;
  }

  void connectAsCustomer({required int userId, String? token}) {
    _isCustomer = true;
    _connect(userId: userId, token: token, roomPrefix: 'customer');
  }

  void connectAsDriver({required int driverId, String? token}) {
    _isCustomer = false;
    _connect(userId: driverId, token: token, roomPrefix: 'driver');
  }

  void _connect({
    required int userId,
    String? token,
    required String roomPrefix,
  }) {
    if (_socket != null && _socket!.connected) return;
    if (_isConnecting) return;

    _isConnecting = true;
    _userId = userId;

    final authToken = token ?? PrefUtils.getToken();

    _socket = IO.io(
      URLS.bookingBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({"token": authToken})
          .build(),
    );

    _registerListeners(roomPrefix);
    _socket!.connect();
  }

  void _registerListeners(String roomPrefix) {
    _socket!.clearListeners();

    _socket!.onConnect((_) {
      _isConnecting = false;
      debugPrint("✅ Socket connected");

      if (_userId != null) {
        _socket!.emit("join_room", {
          "room": "${roomPrefix}_$_userId",
        });
        debugPrint("📡 Joined room: ${roomPrefix}_$_userId");
      }
    });

    // Driver assigned / accepted events
    _socket!.on('DRIVER_ASSIGNED', _onDriverAssigned);
    _socket!.on('BOOKING_ACCEPTED', _onDriverAssigned);
    _socket!.on('RIDE_ACCEPTED', _onDriverAssigned);

    // Only drivers receive new booking requests
    if (!_isCustomer) {
      _socket!.on('NEW_BOOKING', (data) {
        _handleBooking(data);
      });
    }

    _socket!.onReconnect((_) {
      debugPrint("🔄 Socket reconnected");
      if (_userId != null) {
        _socket!.emit("join_room", {
          "room": "${roomPrefix}_$_userId",
        });
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint("🔌 Socket disconnected");
      stopBookingPolling();
    });

    _socket!.onConnectError((error) {
      _isConnecting = false;
      debugPrint("❌ Connect Error: $error");
    });

    _socket!.onError((error) {
      debugPrint("❌ Socket Error: $error");
    });
  }

  void _onDriverAssigned(dynamic data) {
    final bookingId = data["bookingId"]?.toString();

    if (bookingId == null || bookingId.isEmpty) {
      debugPrint("⚠️ DRIVER_ASSIGNED received but bookingId is null/empty");
      return;
    }

    debugPrint("📦 DRIVER_ASSIGNED / BOOKING_ACCEPTED → bookingId: $bookingId");
    startBookingPolling(bookingId);
  }

  void _handleBooking(dynamic data) {
    if (_bookingProvider == null) return;

    try {
      final booking = Map<String, dynamic>.from(data);
      _bookingProvider!.setUpcomingRide(booking);
      debugPrint("📥 NEW_BOOKING received and set");
    } catch (e) {
      debugPrint("❌ Error handling NEW_BOOKING: $e");
    }
  }

  // ================= BOOKING POLLING =================

  void startBookingPolling(String bookingId) {
    // Only customers need to poll
    if (!_isCustomer) {
      debugPrint("⚠️ startBookingPolling skipped – not a customer");
      return;
    }

    // Already polling the same booking
    if (_isPollingActive && _currentPollingBookingId == bookingId) {
      debugPrint("⏳ Already polling booking: $bookingId");
      return;
    }

    // Stop any existing polling first
    stopBookingPolling();

    _currentPollingBookingId = bookingId;
    _isPollingActive = true;

    debugPrint("🚀 Starting booking polling for → $bookingId");

    // Call immediately
    _pollOnce(bookingId);

    // Then every 5 seconds
    _bookingPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        if (!_isPollingActive) return;
        _pollOnce(bookingId);
      },
    );
  }

  Future<void> _pollOnce(String bookingId) async {
    if (!_isPollingActive) return;

    debugPrint("🔄 Polling getBookingDetails → $bookingId");

    final status = await getBookingDetails(bookingId);

    if (status == null) return;

    final upperStatus = status.toUpperCase();

    // Stop polling on final statuses
    if (upperStatus == "COMPLETED" ||
        upperStatus == "CANCELLED" ||
        upperStatus == "FAILED" ||
        upperStatus == "REJECTED") {
      debugPrint("✅ Final status ($status) reached → stopping poll");
      stopBookingPolling();
    }
  }

  void stopBookingPolling() {
    _bookingPollingTimer?.cancel();
    _bookingPollingTimer = null;
    _isPollingActive = false;
    _currentPollingBookingId = null;
    debugPrint("🛑 Booking polling stopped");
  }

  Future<String?> getBookingDetails(String bookingId) async {
    try {
      final isCustomer = PrefUtils.getRole() == "customer";

      final url = Uri.parse(
        isCustomer
            ? URLS.customerBooking + bookingId
            : URLS.driverBooking + bookingId,
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${PrefUtils.getToken()}",
        },
      );

      debugPrint("📥 getBookingDetails → statusCode: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse["success"] == true && jsonResponse["data"] != null) {
          final booking = Map<String, dynamic>.from(jsonResponse["data"]);

          // Update the BookingProvider so UI refreshes
          _bookingProvider?.setUpcomingRide(booking);

          final status = booking["status"]?.toString();
          debugPrint("🎉 Booking updated → Status: $status");

          return status;
        }
      } else {
        debugPrint("❌ getBookingDetails failed body: ${response.body}");
      }
    } catch (e, st) {
      debugPrint("❌ getBookingDetails ERROR: $e");
      debugPrint("$st");
    }

    return null;
  }

  // ================= DRIVER LOCATION =================

  void updateLocation({
    required double lat,
    required double lng,
  }) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit("DRIVER_LOCATION_UPDATE", {
      "lat": lat,
      "lng": lng,
    });
  }

  // ================= DISCONNECT =================

  void disconnect() {
    stopBookingPolling();

    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
    _isConnecting = false;
    _userId = null;

    debugPrint("🔌 Socket fully disconnected");
  }

  bool get isConnected => _socket?.connected ?? false;
}