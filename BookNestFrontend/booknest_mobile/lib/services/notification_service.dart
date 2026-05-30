import 'dart:convert';
import 'http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../layouts/constants.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _authService = AuthService();
  HubConnection? _hubConnection;
  final List<Map<String, dynamic>> _notifications = [];
  final List<Function(Map<String, dynamic>)> _listeners = [];
  bool _notificationsEnabled = true;

  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  bool get notificationsEnabled => _notificationsEnabled;
  int get unreadCount => _notificationsEnabled
      ? _notifications.where((n) => !(n['isRead'] ?? false)).length
      : 0;

  Future<void> connect(int userId) async {
    if (_hubConnection != null) return;

    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    await _loadFromServer();
    for (final listener in _listeners) {
      listener({});
    }

    final token = await _authService.getToken();
    if (token == null) return;

    final hubBaseUrl = AppConstants.baseUrl.replaceAll('/api', '');
    _hubConnection = HubConnectionBuilder()
      .withUrl('$hubBaseUrl/hubs/notifications?access_token=$token')
      .withAutomaticReconnect()
      .build();

    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments == null || arguments.isEmpty) return;

      final data = Map<String, dynamic>.from(arguments[0] as Map);
      final notification = {
        'id': data['id'],
        'title': data['title'],
        'message': data['message'],
        'type': data['notificationType'],
        'bookId': data['bookId'],
        'sendAt': data['sendAt'],
        'isRead': false,
      };

      _notifications.insert(0, notification);

      if (_notificationsEnabled) {
        for (final listener in _listeners) {
          listener(notification);
        }
      }
    });

    try {
      await _hubConnection!.start();
    } catch (e) {
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    if (enabled) {
      await _loadFromServer();
    }
    for (final listener in _listeners) {
      listener({});
    }
  }

  Future<void> _loadFromServer() async {
    try {
      final response = await HttpClient.get(
        Uri.parse('${AppConstants.baseUrl}/Notification/my-notifications'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications.clear();
        _notifications.addAll(data.map((n) => {
          'id': n['id'],
          'title': n['title'],
          'message': n['message'],
          'type': n['notificationType'],
          'sendAt': n['sendAt'],
          'isRead': n['isRead'] ?? false,
        }));
      }
    } catch (e) {
    }
  }

  void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n['isRead'] = true;
    }
    try {
      await HttpClient.put(
        Uri.parse('${AppConstants.baseUrl}/Notification/mark-all-read'),
      );
    } catch (e) {
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
    _notifications.clear();
  }
}
