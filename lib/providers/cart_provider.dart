import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartItem {
  final String  docId;
  final String  name;
  final num     unitPrice;
  final String? imageUrl;
  final String? milkType;
  final String? sweetenerType;
  final List<String> extras;
  final String? specialInstruction;
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
    this.quantity = 1,
  });

  num get total => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
    'docId':              docId,
    'name':               name,
    'unitPrice':          unitPrice,
    'imageUrl':           imageUrl,
    'milkType':           milkType,
    'sweetenerType':      sweetenerType,
    'extras':             extras,
    'specialInstruction': specialInstruction,
    'quantity':           quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
    docId:              (m['docId']         as String?) ?? '',
    name:               (m['name']          as String?) ?? '',
    unitPrice:          (m['unitPrice']      as num?)   ?? 0,
    imageUrl:           m['imageUrl']        as String?,
    milkType:           m['milkType']        as String?,
    sweetenerType:      m['sweetenerType']   as String?,
    extras:             List<String>.from(m['extras'] ?? []),
    specialInstruction: m['specialInstruction'] as String?,
    quantity:           (m['quantity']       as int?)   ?? 1,
  );
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
    final idx = _items.indexWhere((e) => e.docId == item.docId &&
        e.milkType == item.milkType &&
        e.sweetenerType == item.sweetenerType);
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

  Future<String> placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (_items.isEmpty) throw Exception('Cart is empty');

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData   = userDoc.data() ?? {};
    final customerName = (userData['username'] ?? userData['name'] ?? 'Customer').toString();

    final counter = await FirebaseFirestore.instance
        .collection('meta')
        .doc('orderCounter')
        .get();
    int nextNum = ((counter.data()?['count'] as int?) ?? 100) + 1;
    await FirebaseFirestore.instance
        .collection('meta')
        .doc('orderCounter')
        .set({'count': nextNum});

    final orderId = 'ORD-$nextNum';

    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    await orderRef.set({
      'orderId':      orderId,
      'customerId':   user.uid,
      'customerName': customerName,
      'items':        _items.map((e) => e.toMap()).toList(),
      'total':        subtotal,
      'status':       'incoming',
      'createdAt':    FieldValue.serverTimestamp(),
    });

    await _addNotification(
      userId:  user.uid,
      message: 'Your order $orderId has been placed.',
      type:    'order_placed',
      orderId: orderId,
    );

    await _addAdminNotification(
      message: 'New order $orderId has been placed.',
      type:    'new_order',
      orderId: orderId,
    );

    clear();
    return orderId;
  }

  static Future<void> _addNotification({
    required String userId,
    required String message,
    required String type,
    required String orderId,
  }) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .add({
      'message':   message,
      'type':      type,
      'orderId':   orderId,
      'read':      false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _addAdminNotification({
    required String message,
    required String type,
    required String orderId,
  }) async {
    await FirebaseFirestore.instance
        .collection('adminNotifications')
        .add({
      'message':   message,
      'type':      type,
      'orderId':   orderId,
      'read':      false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> notifyCustomerOrderReady({
    required String customerId,
    required String orderId,
  }) async {
    await _addNotification(
      userId:  customerId,
      message: 'Your order $orderId is ready to pick up!',
      type:    'order_ready',
      orderId: orderId,
    );
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