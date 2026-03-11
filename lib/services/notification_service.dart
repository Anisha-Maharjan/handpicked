import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    // Android 13+ (API 33+): request POST_NOTIFICATIONS at runtime
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }

    // iOS: request permission explicitly
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _initialised = true;
  }

  // ── ID helpers ───────────────────────────────────────────────────────────────

  // Each order gets a block of 10 IDs: orderNumber * 10 + step
  // step 0 → customer: order placed
  // step 1 → customer: order being prepared
  // step 2 → customer: order ready for pickup
  // step 3 → customer: order complete
  // step 4 → admin: new order placed
  // step 5 → admin: order complete
  int _orderNum(String orderId) {
    final match = RegExp(r'(\d+)$').firstMatch(orderId);
    if (match != null) return int.parse(match.group(1)!);
    return orderId.hashCode.abs() % 900000;
  }

  int _id(String orderId, int step) => _orderNum(orderId) * 10 + step;

  // ── Notification channel details ─────────────────────────────────────────────

  NotificationDetails get _customerDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'customer_orders',
          'Order Updates',
          channelDescription: 'Notifications about your order status',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  NotificationDetails get _adminDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'admin_orders',
          'Admin – Order Alerts',
          channelDescription: 'Incoming and completed order alerts for admin',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  NotificationDetails get _stockDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'admin_stock',
          'Admin – Stock Warnings',
          channelDescription: 'Low / critical stock warnings for admin',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  // ── Firestore feed helpers ───────────────────────────────────────────────────

  Future<void> _addCustomerFeed({
    required String uid,
    required String message,
    required String type,
    required String orderId,
  }) async {
    if (uid.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('userNotifications')
          .doc(uid)
          .collection('items')
          .add({
        'message': message,
        'type': type,
        'orderId': orderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('NotificationService: Firestore customer feed error: $e');
    }
  }

  Future<void> _addAdminFeed({
    required String message,
    required String type,
    required String orderId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('adminNotifications')
          .add({
        'message': message,
        'type': type,
        'orderId': orderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('NotificationService: Firestore admin feed error: $e');
    }
  }

  // ── Safe show wrapper ────────────────────────────────────────────────────────

  Future<void> _show(
      int id, String title, String body, NotificationDetails details) async {
    try {
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('NotificationService: _plugin.show error: $e');
    }
  }

  // ── Customer notifications ───────────────────────────────────────────────────

  Future<void> notifyCustomerOrderPlaced(String orderId, String uid) async {
    await _show(
      _id(orderId, 0),
      'Order Placed',
      'Your order $orderId has been placed.',
      _customerDetails,
    );
    await _addCustomerFeed(
      uid: uid,
      message: 'Your order has been placed successfully.',
      type: 'order_placed',
      orderId: orderId,
    );
  }

  Future<void> notifyCustomerOrderStarted(String orderId, String uid) async {
    await _show(
      _id(orderId, 1),
      'Order In Progress',
      'Your order $orderId is being prepared.',
      _customerDetails,
    );
    await _addCustomerFeed(
      uid: uid,
      message: 'Your order is being prepared.',
      type: 'order_started',
      orderId: orderId,
    );
  }

  Future<void> notifyCustomerOrderReady(String orderId, String uid) async {
    await _show(
      _id(orderId, 2),
      'Ready for Pickup',
      'Your order $orderId is ready to pick up.',
      _customerDetails,
    );
    await _addCustomerFeed(
      uid: uid,
      message: 'Your order is ready to pick up.',
      type: 'order_ready',
      orderId: orderId,
    );
  }

  Future<void> notifyCustomerOrderComplete(String orderId, String uid) async {
    await _show(
      _id(orderId, 3),
      'Order Complete',
      'Your order $orderId is complete.',
      _customerDetails,
    );
    await _addCustomerFeed(
      uid: uid,
      message: 'Your order has been complete.',
      type: 'order_completed',
      orderId: orderId,
    );
  }

  // ── Admin notifications ──────────────────────────────────────────────────────

  Future<void> notifyAdminNewOrder(String orderId) async {
    await _show(
      _id(orderId, 4),
      'New Order',
      'The order $orderId has been placed.',
      _adminDetails,
    );
    await _addAdminFeed(
      message: 'The order $orderId has been placed.',
      type: 'new_order',
      orderId: orderId,
    );
  }

  Future<void> notifyAdminOrderComplete(String orderId) async {
    await _show(
      _id(orderId, 5),
      'Order Complete',
      'The order $orderId is complete.',
      _adminDetails,
    );
    await _addAdminFeed(
      message: 'The order $orderId is complete.',
      type: 'order_completed',
      orderId: orderId,
    );
  }

  // ── Stock notification ───────────────────────────────────────────────────────

  Future<void> notifyAdminStockCritical(String ingredientName) async {
    final id = 9000000 + ingredientName.hashCode.abs() % 999999;
    final message = '$ingredientName is critically low. Please restock.';
    await _show(id, 'Low Stock Alert', message, _stockDetails);
    await _addAdminFeed(
      message: message,
      type: 'stock_warning',
      orderId: '',
    );
  }
}