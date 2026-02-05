import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initializationSettings);

    // Handle background messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  // Handle background messages when app is opened
  void _handleBackgroundMessage(RemoteMessage message) {
    // Navigate to specific screen based on message data
    // You can use GoRouter here to navigate
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'order_channel',
      'Order Notifications',
      channelDescription: 'Notifications for new orders and updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'New Order',
      message.notification?.body ?? 'You have a new order',
      details,
    );
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Subscribe to topics
  Future<void> subscribeToTopics(String restaurantId) async {
    await _firebaseMessaging.subscribeToTopic('restaurant_$restaurantId');
    await _firebaseMessaging.subscribeToTopic('orders');
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopics(String restaurantId) async {
    await _firebaseMessaging.unsubscribeFromTopic('restaurant_$restaurantId');
    await _firebaseMessaging.unsubscribeFromTopic('orders');
  }
}