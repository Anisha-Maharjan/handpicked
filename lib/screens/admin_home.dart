import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:handpicked/screens/login.dart';
import 'package:handpicked/screens/stock.dart';     
import 'package:handpicked/screens/inventory.dart';

const Color _brown      = Color(0xFF7B4A1E);
const Color _brownLight = Color(0xFF9C6235);
const Color _cream      = Color(0xFFF5EDD8);
const Color _cardCream  = Color(0xFFF9F3E8);
const Color _textDark   = Color(0xFF3B2005);
const Color _textMuted  = Color(0xFF9B8165);

class _ActivityItem {
  final IconData icon;
  final String   message;
  final String   time;
  final bool     isWarning;

  const _ActivityItem({
    required this.icon,
    required this.message,
    required this.time,
    this.isWarning = false,
  });
}
class AdminHomeScreen extends StatefulWidget {
  final User user;
  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int    _selectedTab = 0;
  String _adminName   = 'Admin';
  bool   _loading     = true;

  final List<_ActivityItem> _activities = const [
    _ActivityItem(
      icon:    Icons.receipt_long_outlined,
      message: 'New order has been placed ORD-101.',
      time:    '30 min ago',
    ),
    _ActivityItem(
      icon:    Icons.receipt_long_outlined,
      message: 'Order has been completed ORD-100.',
      time:    '40 min ago',
    ),
    _ActivityItem(
      icon:      Icons.warning_amber_rounded,
      message:   'Whole milk stock is critically low.',
      time:      '3 hr ago',
      isWarning: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(widget.user.uid)
          .get();
      final data = doc.data() ?? {};
      _adminName = (data['name'] ??
              data['username'] ??
              widget.user.displayName ??
              'Admin')
          .toString();
    } catch (_) {
      _adminName = widget.user.displayName ?? 'Admin';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _goToProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _brown)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  //Home tab content

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Good day, $_adminName!',
            style: const TextStyle(
              color:       _brown,
              fontSize:    22,
              fontWeight:  FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          GestureDetector(
            onTap: _goToProfile,
            child: Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _brown.withOpacity(0.3), width: 1.5),
                color: _cream,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _brown,
                size:  22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalSalesCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (ctx, snap) {
          double total = 0;
          if (snap.hasData) {
            for (final doc in snap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              total += ((d['total'] ?? d['amount'] ?? 0) as num).toDouble();
            }
          }

          return Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            decoration: BoxDecoration(
              color:         _brown,
              borderRadius:  BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color:   _brown.withOpacity(0.35),
                  blurRadius: 14,
                  offset:  const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Sales Today',
                  style: TextStyle(
                    color:      Colors.white.withOpacity(0.75),
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snap.connectionState == ConnectionState.waiting
                      ? 'Loading…'
                      : 'Rs. ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color:        Colors.white,
                    fontSize:     28,
                    fontWeight:   FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bestSellerCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('salesCount', descending: true)
            .limit(1)
            .snapshots(),
        builder: (ctx, snap) {
          String  name     = 'Iced Coffee\nSweet Heaven';
          String? imageUrl;

          if (snap.hasData && snap.data!.docs.isNotEmpty) {
            final d = snap.data!.docs.first.data() as Map<String, dynamic>;
            name     = (d['name'] as String?) ?? name;
            imageUrl = d['imageUrl'] as String?;
          }

          return Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 16, 12, 16),
            decoration: BoxDecoration(
              color:        _brown,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color:   _brown.withOpacity(0.3),
                  blurRadius: 12,
                  offset:  const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Text side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best seller of the week',
                        style: TextStyle(
                          color:      Colors.white.withOpacity(0.7),
                          fontSize:   11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   18,
                          fontWeight: FontWeight.w800,
                          height:     1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width:  86,
                          height: 86,
                          fit:    BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width:  86,
      height: 86,
      decoration: BoxDecoration(
        color:        _brownLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.local_cafe_rounded,
        color: Colors.white.withOpacity(0.55),
        size:  36,
      ),
    );
  }

  Widget _activitySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.show_chart_rounded,
                    color: _textDark,
                    size:  18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Activity',
                    style: TextStyle(
                      color:      _textDark,
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color:      _brown,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._activities.map(_activityTile),
        ],
      ),
    );
  }

  Widget _activityTile(_ActivityItem item) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color:        _cardCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brown.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              item.icon,
              color: item.isWarning
                  ? const Color(0xFFB05C00)
                  : _brown.withOpacity(0.75),
              size:  20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.message,
                  style: const TextStyle(
                    color:      _textDark,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    height:     1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.time,
                  style: const TextStyle(
                    color:      _textMuted,
                    fontSize:   11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Home tab
  Widget _homeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          _totalSalesCard(),
          _bestSellerCard(),
          _activitySection(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _placeholderTab(String label) {
    return Center(
      child: Text(
        '$label\nComing soon',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color:      _textMuted,
          fontSize:   16,
          fontWeight: FontWeight.w600,
          height:     1.6,
        ),
      ),
    );
  }

  //Bottom nav
  Widget _bottomNav() {
    const tabs = [
      (Icons.home_rounded,          'Home'),
      (Icons.shopping_bag_outlined, 'Orders'),
      (Icons.inventory_2_outlined,  'Stock'),
      (Icons.assignment_outlined,   'Inventory'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _brown,
        boxShadow: [
          BoxShadow(
            color:      _brown.withOpacity(0.45),
            blurRadius: 16,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final selected = _selectedTab == i;
              return GestureDetector(
                onTap:    () => setState(() => _selectedTab = i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[i].$1,
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].$2,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          fontSize:   10.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2.5,
                        width:  selected ? 22 : 0,
                        decoration: BoxDecoration(
                          color:        Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  //Build
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: _brown),
        ),
      );
    }

    final screens = [
      _homeTab(),                       
      _placeholderTab('Orders'),        
      const StockScreen(),             
      const InventoryScreen(),         
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedTab,
          children: screens,
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }
}