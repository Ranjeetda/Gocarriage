import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../provider_service/URLS.dart';
import '../../../provider_service/booking_provider.dart';
import '../../../resource/pref_utils.dart';

class DriverSocketService {
  /// ---------------- SINGLETON ----------------
  static final DriverSocketService _instance = DriverSocketService._internal();
  factory DriverSocketService() => _instance;
  DriverSocketService._internal();

  IO.Socket? _socket;
  BookingProvider? _bookingProvider;
  bool _isConnecting = false;
  int? _userId; // can be driverId or customerId
  bool _isCustomer = false;

  /// ---------------- ATTACH PROVIDER ----------------
  void attachProvider(BookingProvider provider) {
    _bookingProvider = provider;
  }

  /// ---------------- CONNECT (CUSTOMER) ----------------
  void connectAsCustomer({required int userId, String? token}) {
    _isCustomer = true;
    _connect(userId: userId, token: token, roomPrefix: 'customer');
  }

  /// ---------------- CONNECT (DRIVER) ----------------
  void connectAsDriver({required int driverId, String? token}) {
    _isCustomer = false;
    _connect(userId: driverId, token: token, roomPrefix: 'driver');
  }

  void _connect({
    required int userId,
    String? token,
    required String roomPrefix,
  }) {
    if (_socket != null && _socket!.connected) {
      debugPrint('⚠️ Socket already connected');
      return;
    }

    if (_isConnecting) {
      debugPrint('⏳ Socket connection in progress...');
      return;
    }

    _isConnecting = true;
    _userId = userId;

    final authToken = token ?? PrefUtils.getToken();

    debugPrint('🔌 Connecting socket as $roomPrefix...');
    debugPrint('🌐 URL: ${URLS.bookingBaseUrl}');

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

  /// ---------------- LISTENERS ----------------
  void _registerListeners(String roomPrefix) {
    _socket!.clearListeners();

    // CONNECT
    _socket!.onConnect((_) {
      _isConnecting = false;
      debugPrint('✅ Socket CONNECTED → ${_socket!.id}');

      if (_userId != null) {
        final joinPayload = {"room": "${roomPrefix}_$_userId"};
        debugPrint('📤 JOIN ROOM → $joinPayload');

        _socket!.emitWithAck(
          'join_room',
          joinPayload,
          ack: (response) {
            debugPrint('📥 JOIN ACK → $response');
          },
        );
      }
    });

    // ---------- CUSTOMER EVENTS ----------
    // Backend should emit one of these when driver accepts the booking.
    // Keep only the event name your backend actually sends.
    _socket!.on('DRIVER_ASSIGNED', _onDriverAssigned);
    _socket!.on('BOOKING_ACCEPTED', _onDriverAssigned);
    _socket!.on('RIDE_ACCEPTED', _onDriverAssigned);
    _socket!.on('NEW_BOOKING', _onDriverAssigned); // fallback if backend reuses same name

    // ---------- DRIVER EVENTS ----------
    if (!_isCustomer) {
      _socket!.on('NEW_BOOKING', (data) {
        debugPrint('📦 NEW_BOOKING (driver)');
        _handleNewBooking(data);
      });
    }

    // RECONNECT
    _socket!.onReconnect((_) {
      debugPrint('🔁 Socket RECONNECTED');
      if (_userId != null) {
        final joinPayload = {"room": "${roomPrefix}_$_userId"};
        _socket!.emit('join_room', joinPayload);
      }
    });

    // DISCONNECT
    _socket!.onDisconnect((reason) {
      debugPrint('❌ Socket DISCONNECTED → $reason');
    });

    // ERRORS
    _socket!.onConnectError((error) {
      _isConnecting = false;
      debugPrint('⛔ CONNECT ERROR → $error');
    });

    _socket!.onError((error) {
      debugPrint('🔥 SOCKET ERROR → $error');
    });
  }

  void _onDriverAssigned(dynamic data) {
    debugPrint('📦 DRIVER ASSIGNED / BOOKING ACCEPTED');
    try {
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));
    } catch (_) {
      debugPrint(data.toString());
    }
    _handleNewBooking(data);
  }

  void _handleNewBooking(dynamic data) {
    if (_bookingProvider == null) {
      debugPrint('⚠️ BookingProvider not attached');
      return;
    }

    try {
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      _bookingProvider!.setUpcomingRide(map);
    } catch (e) {
      debugPrint('❌ Error parsing booking data: $e');
    }
  }

  /// ---------------- LOCATION UPDATE (driver) ----------------
  void updateLocation({
    required double lat,
    required double lng,
  }) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Socket not connected, skipping location update');
      return;
    }

    final payload = {
      "lat": lat,
      "lng": lng,
    };

    debugPrint('📡 DRIVER_LOCATION_UPDATE → $payload');
    _socket!.emit('DRIVER_LOCATION_UPDATE', payload);
  }

  /// ---------------- DISCONNECT ----------------
  void disconnect() {
    debugPrint('🔌 Disconnecting socket');

    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
    _isConnecting = false;
    _userId = null;
  }

  /// ---------------- STATUS ----------------
  bool get isConnected => _socket?.connected ?? false;
}