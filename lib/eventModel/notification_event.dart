
import 'package:event_bus/event_bus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// ✅ GLOBAL EVENT BUS
final EventBus eventBus = EventBus();

/// ✅ Notification Event Class
class NotificationEvent {
  final RemoteMessage message;
  NotificationEvent(this.message);
}