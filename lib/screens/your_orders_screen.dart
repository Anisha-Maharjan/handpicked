import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:handpicked/providers/cart_provider.dart';
import 'package:handpicked/screens/cart_screen.dart';
import 'package:handpicked/screens/notifications_screen.dart';

const Color _oBrown = Color(0xFF834D1E);
const Color _oCream = Color(0xFFF5EDD8);
const Color _oCardCream = Color(0xFFF9F3E8);
const Color _oTextDark = Color(0xFF1E1E1E);
const Color _oTextMuted = Color(0xFF9B8165);

class YourOrdersScreen extends StatefulWidget {
  const YourOrdersScreen({super.key});

  @override
  State<YourOrdersScreen> createState() => _YourOrdersScreenState();
}

class _YourOrdersScreenState extends State<YourOrdersScreen> {
  int _tab = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<QuerySnapshot> get _incomingStream => FirebaseFirestore.instance
      .collection('orders')
      .where('customerId', isEqualTo: _uid)
      .where('status', isEqualTo: 'incoming')
      .snapshots();

  Stream<QuerySnapshot> get _activeStream => FirebaseFirestore.instance
      .collection('orders')
      .where('customerId', isEqualTo: _uid)
      .where('status', whereIn: ['active', 'ready'])
      .snapshots();

  Stream<QuerySnapshot> get _pastStream => FirebaseFirestore.instance
      .collection('orders')
      .where('customerId', isEqualTo: _uid)
      .where('status', isEqualTo: 'completed')
      .snapshots();

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'incoming':
        return 'Confirmed';
      case 'active':
        return 'In Progress';
      case 'ready':
        return 'In Progress';
      case 'completed':
        return 'Complete';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'incoming':
        return Colors.blue;
      case 'active':
        return Colors.orange;
      case 'ready':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return _oTextMuted;
    }
  }

  Future<void> _reorder(List items) async {
    final cart = CartProviderWidget.of(context);

    for (final item in items) {
      final m = Map<String, dynamic>.from(item as Map);
      cart.addItem(CartItem.fromMap(m));
    }

    try {
      final orderId = await cart.placeOrder();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Re-order $orderId placed!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _oBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your orders',
                    style: TextStyle(
                      color: _oTextDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartScreen(),
                          ),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: _oTextDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: _oTextDark,
                              size: 22,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.menu_rounded,
                        color: _oTextDark,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TabChip(
                    label: 'Recently',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'Past Orders',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _tab == 0 ? _buildRecent() : _buildPast(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildRecent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _incomingStream,
      builder: (ctx, incomingSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _activeStream,
          builder: (ctx, activeSnap) {
            if (incomingSnap.connectionState == ConnectionState.waiting ||
                activeSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _oBrown),
              );
            }

            final docs = [
              ...incomingSnap.data?.docs ?? [],
              ...activeSnap.data?.docs ?? [],
            ];

            docs.sort((a, b) {
              final aT = (a.data() as Map)['createdAt'] as Timestamp?;
              final bT = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aT == null || bT == null) return 0;
              return bT.compareTo(aT);
            });

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No active orders.',
                  style: TextStyle(color: _oTextMuted, fontSize: 14),
                ),
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final items = (data['items'] as List?) ?? [];
                final status = (data['status'] as String?) ?? '';

                return _OrderCard(
                  orderId: (data['orderId'] as String?) ?? '',
                  items: items,
                  date: _formatDate(data['createdAt'] as Timestamp?),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPast() {
    return StreamBuilder<QuerySnapshot>(
      stream: _pastStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _oBrown),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No past orders.',
              style: TextStyle(color: _oTextMuted, fontSize: 14),
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final data = sorted[i].data() as Map<String, dynamic>;
            final items = (data['items'] as List?) ?? [];

            return _OrderCard(
              orderId: (data['orderId'] as String?) ?? '',
              items: items,
              date: _formatDate(data['createdAt'] as Timestamp?),
              trailing: GestureDetector(
                onTap: () => _reorder(items),
                child: const Text(
                  'Re-order',
                  style: TextStyle(
                    color: _oBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bottomNav() {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: _oBrown,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: false,
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            _NavItem(
              icon: Icons.local_cafe_outlined,
              label: 'Drink Menu',
              active: false,
              onTap: () => Navigator.of(context).pop(),
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Your Order',
              active: true,
              onTap: () {},
            ),
            _NavItem(
              icon: Icons.favorite_border_rounded,
              label: 'Favorites',
              active: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final List items;
  final String date;
  final Widget trailing;

  const _OrderCard({
    required this.orderId,
    required this.items,
    required this.date,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _oCardCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8D5BC),
          width: 1,
        ),
      ),
      child: Column(
        children: items.take(3).map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final name = (m['name'] as String?) ?? '';
          final qty = (m['quantity'] as int?) ?? 1;
          final imageUrl = (m['imageUrl'] as String?);
          final description = (m['description'] as String?) ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${qty}x  $name',
                            style: const TextStyle(
                              color: _oTextDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            date,
                            style: const TextStyle(
                              color: _oTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (description.isNotEmpty)
                            Expanded(
                              child: Text(
                                description,
                                style: const TextStyle(
                                  color: _oTextMuted,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          trailing,
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: _oCream,
        child: Center(
          child: Icon(
            Icons.local_cafe_rounded,
            color: _oBrown.withOpacity(0.3),
            size: 20,
          ),
        ),
      );
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _oBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _oBrown : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _oTextMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? Colors.white : Colors.white.withOpacity(0.75);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width: active ? 18 : 0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}