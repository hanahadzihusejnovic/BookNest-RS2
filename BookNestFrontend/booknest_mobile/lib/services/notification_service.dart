import 'package:signalr_netcore/signalr_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  HubConnection? _hubConnection;
  final List<Map<String, dynamic>> _notifications = [];
  final List<Function(Map<String, dynamic>)> _listeners = [];

  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !(n['isRead'] ?? false)).length;

  Future<void> connect(int userId) async {
    if (_hubConnection != null) return;

    _hubConnection = HubConnectionBuilder()
      .withUrl('http://10.0.2.2:7110/hubs/notifications?userId=$userId')
      .withAutomaticReconnect()
      .build();

    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments == null || arguments.isEmpty) return;

      final data = Map<String, dynamic>.from(arguments[0] as Map);
      final notification = {
        'title': data['title'],
        'message': data['message'],
        'type': data['notificationType'],
        'sendAt': data['sendAt'],
        'isRead': false,
      };

      _notifications.insert(0, notification);

      for (final listener in _listeners) {
        listener(notification);
      }
    });

    try {
      await _hubConnection!.start();
      print('✅ Connected to NotificationHub as user $userId');
    } catch (e) {
      print('❌ Failed to connect to NotificationHub: $e');
    }
  }

  void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  void markAllRead() {
    for (final n in _notifications) {
      n['isRead'] = true;
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }
}