import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../provider_service/booking_provider.dart';
import '../resource/pref_utils.dart';
import '../provider_service/URLS.dart';

class DriverKnowBookSocketService {
  /// ---------------- SINGLETON ----------------
  static final DriverKnowBookSocketService _instance =
  DriverKnowBookSocketService._internal();

  factory DriverKnowBookSocketService() => _instance;
  DriverKnowBookSocketService._internal();

  IO.Socket? _socket;
  BookingProvider? _bookingProvider;
  bool _isConnecting = false;

  /// ---------------- ATTACH PROVIDER ----------------
  void attachProvider(BookingProvider provider) {
    _bookingProvider = provider;
  }

  /// ---------------- CONNECT SOCKET ----------------
  void connectDriverSocket(int driverId) {
    /// prevent duplicate connection
    if (_socket != null && _socket!.connected) {
      print('⚠️ Socket already connected');
      return;
    }

    if (_isConnecting) {
      print('⏳ Socket connection in progress...');
      return;
    }

    _isConnecting = true;

    print('🔌 Connecting socket...');
    print('🌐 URL: ${URLS.bookingBaseUrl}');
    print('🪪 TOKEN: ${PrefUtils.getToken()}');

    _socket = IO.io(
      URLS.bookingBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()           // 🔥 IMPORTANT
          .enableReconnection()           // allow reconnect
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({"token": PrefUtils.getToken()})
          .build(),
    );

    _registerListeners(driverId);
    _socket!.connect();
  }

  /// ---------------- REGISTER LISTENERS ----------------
  void _registerListeners(int driverId) {
    _socket!.clearListeners();

    /// CONNECT
    _socket!.onConnect((_) {
      _isConnecting = false;
      print('✅ CONNECTED → ${_socket!.id}');

      final joinPayload = {"room": "driver_$driverId"};

      print('📤 JOIN ROOM');
      print(const JsonEncoder.withIndent('  ').convert(joinPayload));

      _socket!.emitWithAck(
        'join_room',
        joinPayload,
        ack: (response) {
          print('📥 JOIN ACK');
          print(const JsonEncoder.withIndent('  ').convert(response));
        },
      );
    });

    /// NEW BOOKING EVENT
    _socket!.on('NEW_BOOKING', (data) {
      print('📦 NEW_BOOKING');
      print(const JsonEncoder.withIndent('  ').convert(data));

      if (_bookingProvider == null) {
        print('⚠️ BookingProvider not attached');
        return;
      }

      _bookingProvider!.setUpcomingRide(
        Map<String, dynamic>.from(data),
      );
    });

    /// RECONNECT
    _socket!.onReconnect((_) {
      print('🔁 RECONNECTED');
    });

    /// DISCONNECT
    _socket!.onDisconnect((reason) {
      print('❌ DISCONNECTED → $reason');
    });

    /// ERRORS
    _socket!.onConnectError((error) {
      _isConnecting = false;
      print('⛔ CONNECT ERROR');
      print(error);
    });

    _socket!.onError((error) {
      print('🔥 SOCKET ERROR');
      print(error);
    });

    /// CATCH ALL (DEBUG)
    _socket!.onAny((event, data) {
      print('📡 EVENT [$event]');
      if (data != null) {
        try {
          print(const JsonEncoder.withIndent('  ').convert(data));
        } catch (_) {
          print(data);
        }
      }
    });
  }

  /// ---------------- DISCONNECT ----------------
  void disconnect() {
    print('🔌 MANUAL DISCONNECT');

    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
    _isConnecting = false;
  }

  /// ---------------- STATUS ----------------
  bool get isConnected => _socket?.connected ?? false;
}
