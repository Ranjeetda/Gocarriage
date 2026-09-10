import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../provider_service/booking_provider.dart';
import '../provider_service/URLS.dart';
import '../resource/pref_utils.dart';

class DriverSocketService {
  /// ---------------- SINGLETON ----------------
  static final DriverSocketService _instance = DriverSocketService._internal();
  factory DriverSocketService() => _instance;
  DriverSocketService._internal();

  IO.Socket? _socket;
  BookingProvider? _bookingProvider;
  bool _isConnecting = false;
  int? _driverId;

  /// ---------------- ATTACH PROVIDER ----------------
  void attachProvider(BookingProvider provider) {
    _bookingProvider = provider;
  }

  /// ---------------- CONNECT (ONE SOCKET) ----------------
  void connect({required int driverId, String? token}) {
    // Prevent duplicate connection
    if (_socket != null && _socket!.connected) {
      debugPrint('⚠️ Driver socket already connected');
      return;
    }

    if (_isConnecting) {
      debugPrint('⏳ Driver socket connection in progress...');
      return;
    }

    _isConnecting = true;
    _driverId = driverId;

    final authToken = token ?? PrefUtils.getToken();

    debugPrint('🔌 Connecting driver socket...');
    debugPrint('🌐 URL: ${URLS.bookingBaseUrl}');

    _socket = IO.io(
      URLS.bookingBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()          // important
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({"token": authToken}) // preferred for socket.io v3+
      // .setExtraHeaders({'Authorization': 'Bearer $authToken'}) // alternative
          .build(),
    );

    _registerListeners();
    _socket!.connect();
  }

  /// ---------------- LISTENERS ----------------
  void _registerListeners() {
    _socket!.clearListeners();

    // CONNECT
    _socket!.onConnect((_) {
      _isConnecting = false;
      debugPrint('✅ Driver socket CONNECTED → ${_socket!.id}');

      // Join driver room
      if (_driverId != null) {
        final joinPayload = {"room": "driver_$_driverId"};
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

    // NEW BOOKING
    _socket!.on('NEW_BOOKING', (data) {
      debugPrint('📦 NEW_BOOKING');
      try {
        debugPrint(const JsonEncoder.withIndent('  ').convert(data));
      } catch (_) {
        debugPrint(data.toString());
      }

      if (_bookingProvider == null) {
        debugPrint('⚠️ BookingProvider not attached');
        return;
      }

      _bookingProvider!.setUpcomingRide(
        Map<String, dynamic>.from(data),
      );
    });

    // RECONNECT
    _socket!.onReconnect((_) {
      debugPrint('🔁 Driver socket RECONNECTED');

      // Re-join room after reconnect
      if (_driverId != null) {
        final joinPayload = {"room": "driver_$_driverId"};
        _socket!.emit('join_room', joinPayload);
      }
    });

    // DISCONNECT
    _socket!.onDisconnect((reason) {
      debugPrint('❌ Driver socket DISCONNECTED → $reason');
    });

    // ERRORS
    _socket!.onConnectError((error) {
      _isConnecting = false;
      debugPrint('⛔ CONNECT ERROR → $error');
    });

    _socket!.onError((error) {
      debugPrint('🔥 SOCKET ERROR → $error');
    });

    // Optional: catch-all for debugging
    // _socket!.onAny((event, data) {
    //   debugPrint('📡 EVENT [$event] → $data');
    // });
  }

  /// ---------------- LOCATION UPDATE ----------------
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
    debugPrint('🔌 Disconnecting driver socket');

    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
    _isConnecting = false;
    _driverId = null;
  }

  /// ---------------- STATUS ----------------
  bool get isConnected => _socket?.connected ?? false;
}