import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../provider_service/URLS.dart';

class DriverLocationUpdateSocketService {
  /// ---------------- SINGLETON ----------------
  static final DriverLocationUpdateSocketService _instance =
  DriverLocationUpdateSocketService._internal();

  factory DriverLocationUpdateSocketService() => _instance;
  DriverLocationUpdateSocketService._internal();

  IO.Socket? _socket;
  bool _isConnecting = false;

  /// ---------------- CONNECT SOCKET ----------------
  void connectSocket(String token) {
    /// Prevent duplicate connection
    if (_socket != null && _socket!.connected) {
      debugPrint('⚠️ Location socket already connected');
      return;
    }

    if (_isConnecting) {
      debugPrint('⏳ Location socket connection in progress...');
      return;
    }

    _isConnecting = true;

    debugPrint('🔌 Connecting driver location socket...');

    _socket = IO.io(
      URLS.bookingBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()             // 🚫 VERY IMPORTANT
          .enableReconnection()             // ✅ auto reconnect
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setExtraHeaders({
        'Authorization': 'Bearer $token',
      })
          .build(),
    );

    _registerListeners();
    _socket!.connect();
  }

  /// ---------------- LISTENERS ----------------
  void _registerListeners() {
    _socket!.clearListeners();

    _socket!.onConnect((_) {
      _isConnecting = false;
      debugPrint('✅ Location socket CONNECTED → ${_socket!.id}');
    });

    _socket!.onReconnect((_) {
      debugPrint('🔁 Location socket RECONNECTED');
    });

    _socket!.onDisconnect((reason) {
      debugPrint('❌ Location socket DISCONNECTED → $reason');
    });

    _socket!.onConnectError((error) {
      _isConnecting = false;
      debugPrint('⛔ Location socket CONNECT ERROR → $error');
    });

    _socket!.onError((error) {
      debugPrint('🔥 Location socket ERROR → $error');
    });
  }

  /// ---------------- LOCATION UPDATE ----------------
  void updateLocation({
    required double lat,
    required double lng,
  }) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Location socket not connected, skipping update');
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
    debugPrint('🔌 Disconnecting location socket');

    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
    _isConnecting = false;
  }

  /// ---------------- STATUS ----------------
  bool get isConnected => _socket?.connected ?? false;
}
