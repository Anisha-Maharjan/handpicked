import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handpicked/services/notification_service.dart';

class CartItem {
  final String docId;
  final String name;
  final num unitPrice;
  final String? imageUrl;
  final String? milkType;
  final String? sweetenerType;
  final List<String> extras;
  final String? specialInstruction;

  /// keep both for compatibility
  final String category; // drink / bakery
  final String productType; // drink / bakery

  final String? description;
  int quantity;

  CartItem({
    required this.docId,
    required this.name,
    required this.unitPrice,
    this.imageUrl,
    this.milkType,
    this.sweetenerType,
    this.extras = const [],
    this.specialInstruction,
    this.category = 'drink',
    String? productType,
    this.description,
    this.quantity = 1,
  }) : productType = productType ?? category;

  num get total => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'docId': docId,
        'name': name,
        'unitPrice': unitPrice,
        'imageUrl': imageUrl,
        'milkType': milkType,
        'sweetenerType': sweetenerType,
        'extras': extras,
        'specialInstruction': specialInstruction,
        'category': category,
        'productType': productType,
        'type': category,
        'description': description,
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, dynamic> m) {
    final resolvedType =
        (m['productType'] as String?) ??
        (m['category'] as String?) ??
        (m['type'] as String?) ??
        'drink';

    return CartItem(
      docId: (m['docId'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      unitPrice: (m['unitPrice'] as num?) ?? (m['price'] as num?) ?? 0,
      imageUrl: m['imageUrl'] as String?,
      milkType: m['milkType'] as String?,
      sweetenerType: m['sweetenerType'] as String?,
      extras: List<String>.from(m['extras'] ?? []),
      specialInstruction: m['specialInstruction'] as String?,
      category: resolvedType,
      productType: resolvedType,
      description: m['description'] as String?,
      quantity: (m['quantity'] as int?) ?? 1,
    );
  }
}

class CartProvider extends ChangeNotifier {
  static final CartProvider _instance = CartProvider._();
  factory CartProvider() => _instance;
  CartProvider._();

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  num get subtotal => _items.fold(0, (s, i) => s + i.total);
  int get totalCount => _items.fold(0, (s, i) => s + i.quantity);

  void addItem(CartItem item) {
    final idx = _items.indexWhere(
      (e) =>
          e.docId == item.docId &&
          e.milkType == item.milkType &&
          e.sweetenerType == item.sweetenerType &&
          e.category == item.category,
    );

    if (idx >= 0) {
      _items[idx].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void increment(int index) {
    _items[index].quantity++;
    notifyListeners();
  }

  void decrement(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void remove(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Places the order in Firestore and fires local notifications for both
  /// the customer (notification 1) and the admin (notification 10).
  Future<String> placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (_items.isEmpty) throw Exception('Cart is empty');

    final db = FirebaseFirestore.instance;

    final userDoc = await db.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final customerName =
        (userData['username'] ?? userData['name'] ?? 'Customer').toString();

    final counterRef = db.collection('meta').doc('orderCounter');
    final counterSnap = await counterRef.get();
    final int nextNum = ((counterSnap.data()?['count'] as int?) ?? 100) + 1;

    await counterRef.set({'count': nextNum});

    final orderId = 'ORD-$nextNum';
    final orderRef = db.collection('orders').doc(orderId);

    await orderRef.set({
      'orderId': orderId,
      'customerId': user.uid,
      'customerName': customerName,
      'items': _items.map((e) => e.toMap()).toList(),
      'total': subtotal,
      'status': 'incoming',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Customer notification: "Your order {orderId} has been placed."
    await NotificationService.instance.notifyCustomerOrderPlaced(orderId, user.uid);

    // Admin notification: "The order {orderId} has been placed."
    await NotificationService.instance.notifyAdminNewOrder(orderId);

    clear();
    return orderId;
  }
}

class CartProviderWidget extends InheritedNotifier<CartProvider> {
  const CartProviderWidget({
    super.key,
    required CartProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static CartProvider of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<CartProviderWidget>();
    assert(w != null, 'CartProviderWidget not found in tree');
    return w!.notifier!;
  }
}