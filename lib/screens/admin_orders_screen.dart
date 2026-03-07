import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _aBrown     = Color(0xFF7B4A1E);
const Color _aCream     = Color(0xFFF5EDD8);
const Color _aCardCream = Color(0xFFF9F3E8);
const Color _aTextDark  = Color(0xFF3B2005);
const Color _aTextMuted = Color(0xFF9B8165);

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  int _tab = 0;

  Stream<QuerySnapshot> _ordersStream(String status) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  Stream<QuerySnapshot> get _historyStream =>
      FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .snapshots();

  Future<void> _updateStatus(
    String orderId,
    String newStatus,
    String customerId,
  ) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});

    if (newStatus == 'active') {
      await _addCustomerNotif(
        customerId: customerId,
        message: 'Your order $orderId has been confirmed.',
        type: 'order_confirmed',
        orderId: orderId,
      );
      await _addAdminNotif(
        'Order $orderId has been started.',
        'order_started',
        orderId,
      );
    } else if (newStatus == 'completed') {
      await _addCustomerNotif(
        customerId: customerId,
        message: 'Your order $orderId is ready to pick up.',
        type: 'order_ready',
        orderId: orderId,
      );
      await _addAdminNotif(
        'Order $orderId has been completed.',
        'order_completed',
        orderId,
      );
    }
  }

  Future<void> _addCustomerNotif({
    required String customerId,
    required String message,
    required String type,
    required String orderId,
  }) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(customerId)
        .collection('items')
        .add({
      'message': message,
      'type': type,
      'orderId': orderId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addAdminNotif(
    String message,
    String type,
    String orderId,
  ) async {
    await FirebaseFirestore.instance.collection('adminNotifications').add({
      'message': message,
      'type': type,
      'orderId': orderId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: const Text(
            'Orders',
            style: TextStyle(
              color: _aBrown,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _aCream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _TabBtn(
                  label: 'Incoming',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: _aBrown.withOpacity(0.2),
                ),
                _TabBtn(
                  label: 'Active',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: _aBrown.withOpacity(0.2),
                ),
                _TabBtn(
                  label: 'History',
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _tab == 0
              ? _buildList('incoming', canStart: true)
              : _tab == 1
                  ? _buildList('active', canReady: true)
                  : _buildHistory(),
        ),
      ],
    );
  }

  Widget _buildList(
    String status, {
    bool canStart = false,
    bool canReady = false,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream(status),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _aBrown),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No $status orders.',
              style: const TextStyle(
                color: _aTextMuted,
                fontSize: 14,
              ),
            ),
          );
        }

        final sorted = [...docs];
        sorted.sort((a, b) {
          final aT = (a.data() as Map)['createdAt'] as Timestamp?;
          final bT = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aT == null || bT == null) return 0;
          return bT.compareTo(aT);
        });

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final data = sorted[i].data() as Map<String, dynamic>;
            final orderId = (data['orderId'] as String?) ?? docs[i].id;
            final custName = (data['customerName'] as String?) ?? 'Customer';
            final items = (data['items'] as List?) ?? [];
            final total = (data['total'] as num?) ?? 0;
            final customerId = (data['customerId'] as String?) ?? '';

            return _AdminOrderCard(
              orderId: orderId,
              custName: custName,
              items: items,
              total: total,
              canStart: canStart,
              canReady: canReady,
              createdAt: data['createdAt'] as Timestamp?,
              onAction: () {
                final next = canStart ? 'active' : 'completed';
                _updateStatus(orderId, next, customerId);
              },
              onTapDetail: () => _showItemDetail(
                context,
                orderId,
                custName,
                items,
                total,
                createdAt: data['createdAt'] as Timestamp?,
                canStart: canStart,
                canReady: canReady,
                customerId: customerId,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _historyStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _aBrown),
          );
        }

        final hdocs = snap.data?.docs ?? [];
        if (hdocs.isEmpty) {
          return const Center(
            child: Text(
              'No completed orders.',
              style: TextStyle(color: _aTextMuted, fontSize: 14),
            ),
          );
        }

        final sorted = [...hdocs];
        sorted.sort((a, b) {
          final aT = (a.data() as Map)['createdAt'] as Timestamp?;
          final bT = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aT == null || bT == null) return 0;
          return bT.compareTo(aT);
        });

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final data = sorted[i].data() as Map<String, dynamic>;
            final orderId = (data['orderId'] as String?) ?? hdocs[i].id;
            final custName = (data['customerName'] as String?) ?? 'Customer';
            final items = (data['items'] as List?) ?? [];
            final total = (data['total'] as num?) ?? 0;

            return _AdminOrderCard(
              orderId: orderId,
              custName: custName,
              items: items,
              total: total,
              isHistory: true,
              createdAt: data['createdAt'] as Timestamp?,
              onTapDetail: () => _showItemDetail(
                context,
                orderId,
                custName,
                items,
                total,
                createdAt: data['createdAt'] as Timestamp?,
                isHistory: true,
                customerId: '',
              ),
            );
          },
        );
      },
    );
  }

  void _showItemDetail(
    BuildContext context,
    String orderId,
    String custName,
    List items,
    num total, {
    Timestamp? createdAt,
    bool canStart = false,
    bool canReady = false,
    bool isHistory = false,
    required String customerId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(
        orderId: orderId,
        custName: custName,
        items: items,
        total: total,
        createdAt: createdAt,
        canStart: canStart,
        canReady: canReady,
        isHistory: isHistory,
        onAction: isHistory
            ? null
            : () {
                final next = canStart ? 'active' : 'completed';
                _updateStatus(orderId, next, customerId);
                Navigator.of(context).pop();
              },
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final String orderId;
  final String custName;
  final List items;
  final num total;
  final bool canStart;
  final bool canReady;
  final bool isHistory;
  final Timestamp? createdAt;
  final VoidCallback? onAction;
  final VoidCallback onTapDetail;

  const _AdminOrderCard({
    required this.orderId,
    required this.custName,
    required this.items,
    required this.total,
    this.canStart = false,
    this.canReady = false,
    this.isHistory = false,
    this.createdAt,
    this.onAction,
    required this.onTapDetail,
  });

  String _fmtDate(Timestamp ts) {
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtTime(Timestamp ts) {
    final d = ts.toDate();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapDetail,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _aCardCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8D5BC),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: _aBrown,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        custName,
                        style: const TextStyle(
                          color: _aTextDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isHistory
                            ? 'Order has been completed $orderId.'
                            : 'New order has been placed $orderId.',
                        style: const TextStyle(
                          color: _aTextMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _aBrown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _fmtDate(createdAt!),
                      style: const TextStyle(
                        color: _aBrown,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${items.length} item${items.length == 1 ? '' : 's'}'
              '${createdAt != null ? '  ·  ${_fmtTime(createdAt!)}' : ''}',
              style: const TextStyle(
                color: _aTextMuted,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 10),
            ...items.take(3).map((item) {
              final m = Map<String, dynamic>.from(item as Map);
              final name = (m['name'] as String?) ?? '';
              final qty = (m['quantity'] as int?) ?? 1;
              final up = (m['unitPrice'] as num?) ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${qty}x $name',
                      style: const TextStyle(
                        color: _aTextDark,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Rs. ${(up * qty).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: _aTextDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (!isHistory && onAction != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _aBrown,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          canStart ? 'Start' : 'Ready',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemDetailSheet extends StatelessWidget {
  final String orderId;
  final String custName;
  final List items;
  final num total;
  final bool canStart;
  final bool canReady;
  final bool isHistory;
  final Timestamp? createdAt;
  final VoidCallback? onAction;

  const _ItemDetailSheet({
    required this.orderId,
    required this.custName,
    required this.items,
    required this.total,
    this.canStart = false,
    this.canReady = false,
    this.isHistory = false,
    this.createdAt,
    this.onAction,
  });

  String _fmtDateTime(Timestamp ts) {
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${d.day} ${months[d.month - 1]} ${d.year}  ·  $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            '$orderId  $custName',
            style: const TextStyle(
              color: _aBrown,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: _aTextMuted,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  _fmtDateTime(createdAt!),
                  style: const TextStyle(
                    color: _aTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ...items.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            final name = (m['name'] as String?) ?? '';
            final qty = (m['quantity'] as int?) ?? 1;
            final type = (m['type'] as String?);
            final category = (m['category'] as String?);
            final productType = (m['productType'] as String?);
            final milk = (m['milkType'] as String?);
            final sweet = (m['sweetenerType'] as String?);
            final extras = List<String>.from(m['extras'] ?? []);
            final special = (m['specialInstruction'] as String?);
            final imageUrl = (m['imageUrl'] as String?);

            bool _isBakeryStr(String? s) =>
                s != null && s.trim().toLowerCase().contains('bakery');
            final bool isBakery =
                _isBakeryStr(productType) ||
                _isBakeryStr(type) ||
                _isBakeryStr(category);
            final bool isDrink = !isBakery;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _aCardCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE8D5BC),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _imgPlaceholder(isDrink),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ] else ...[
                        _imgPlaceholder(isDrink),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _aBrown,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${qty}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: _aTextDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              isDrink ? 'Item details' : 'Bakery item',
                              style: const TextStyle(
                                color: _aTextMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (isDrink) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE8D5BC),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chosen Ingredients',
                            style: TextStyle(
                              color: _aTextDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Divider(
                            color: Color(0xFFE8D5BC),
                            height: 14,
                          ),
                          _Row2Col(
                            'Milk type',
                            milk ?? 'None',
                            'Size',
                            'Small',
                          ),
                          const SizedBox(height: 8),
                          _Row2Col(
                            'Sweetener',
                            sweet ?? 'None',
                            'Toppings',
                            extras.isNotEmpty ? extras.join(', ') : 'None',
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Special Instruction',
                                style: TextStyle(
                                  color: _aTextDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                special?.isNotEmpty == true ? special! : 'None',
                                style: const TextStyle(
                                  color: _aTextMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!isDrink) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE8D5BC),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              color: _aTextDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Divider(
                            color: Color(0xFFE8D5BC),
                            height: 14,
                          ),
                          Text(
                            (m['description'] as String?)?.isNotEmpty == true
                                ? m['description'] as String
                                : 'No description available.',
                            style: const TextStyle(
                              color: _aTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      color: _aTextDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Rs. ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _aBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (!isHistory && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _aBrown,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          canStart ? 'Start' : 'Mark as Ready',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder(bool isDrink) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          color: const Color(0xFFEDD9BB),
          child: Center(
            child: Icon(
              isDrink
                  ? Icons.local_cafe_rounded
                  : Icons.bakery_dining_rounded,
              color: _aBrown.withOpacity(0.35),
              size: 20,
            ),
          ),
        ),
      );
}

class _Row2Col extends StatelessWidget {
  final String label1;
  final String value1;
  final String label2;
  final String value2;

  const _Row2Col(this.label1, this.value1, this.label2, this.value2);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: const TextStyle(
                  color: _aTextDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value1,
                style: const TextStyle(
                  color: _aTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: const TextStyle(
                  color: _aTextDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value2,
                style: const TextStyle(
                  color: _aTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _aBrown : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _aBrown,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}