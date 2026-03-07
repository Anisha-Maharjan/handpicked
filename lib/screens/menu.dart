import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:handpicked/providers/cart_provider.dart';
import 'package:handpicked/screens/bakery_detail.dart';
import 'package:handpicked/screens/cart_screen.dart';
import 'package:handpicked/screens/notifications_screen.dart';
import 'package:handpicked/screens/product_detail.dart';
import 'package:handpicked/screens/your_orders_screen.dart';

const Color _brown     = Color(0xFF834D1E);
const Color _cream     = Color(0xFFF5EDD8);
const Color _textDark  = Color(0xFF1E1E1E);
const Color _textMuted = Color(0xFF9B8165);

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int    _selectedTab  = 0;
  final  _searchCtrl   = TextEditingController();
  String _searchQuery  = '';

  final List<String> _tabs = ['Drink', 'Bakery', 'Custom'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesTab(String type) {
    final t = type.toLowerCase().trim();
    switch (_selectedTab) {
      case 0: return t == 'drink'  || t == 'drinks';
      case 1: return t == 'bakery' || t == 'food' || t == 'pastry';
      case 2: return t == 'custom';
      default: return false;
    }
  }

  bool _isBakery(String type) {
    final t = type.toLowerCase().trim();
    return t == 'bakery' || t == 'food' || t == 'pastry';
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              'What would you\nlike to drink today?',
              style: TextStyle(
                color:      _brown,
                fontSize:   20,
                fontWeight: FontWeight.w800,
                height:     1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _CartIcon(),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.notifications_none_rounded,
                          color: _textDark, size: 22),
                    ),
                    Positioned(
                      right: 4, top: 4,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _unreadNotifStream,
                        builder: (ctx, snap) {
                          final count = snap.data?.docs.length ?? 0;
                          if (count == 0) return const SizedBox.shrink();
                          return Container(
                            width:  7, height: 7,
                            decoration: BoxDecoration(
                              color:  Colors.redAccent,
                              shape:  BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap:        () {},
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child:   Icon(Icons.menu_rounded,
                      color: _textDark, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot>? get _unreadNotifStream {
    final uid =
        FirebaseFirestore.instance.collection('notifications').doc().id;
    return null;
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(24),
          border:       Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged:  (v) => setState(() => _searchQuery = v.toLowerCase()),
          style:       const TextStyle(fontSize: 13, color: _textDark),
          decoration: InputDecoration(
            hintText:       'Search..',
            hintStyle:      TextStyle(
                color: Colors.grey.shade400, fontSize: 13),
            prefixIcon:     Icon(Icons.search,
                color: Colors.grey.shade400, size: 18),
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color:        _cream,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: List.generate(_tabs.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Container(
                  width: 1, height: 20,
                  color: _brown.withOpacity(0.25));
            }
            final tabIdx  = i ~/ 2;
            final selected = _selectedTab == tabIdx;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = tabIdx),
                child: AnimatedContainer(
                  duration:   const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color:        selected ? _brown : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _tabs[tabIdx],
                    style: TextStyle(
                      color:      selected ? Colors.white : _brown,
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _productList(List<QueryDocumentSnapshot> allDocs) {
    final filtered = allDocs.where((doc) {
      final data   = doc.data() as Map<String, dynamic>;
      final type   = (data['type']     as String?) ?? '';
      final name   = (data['name']     as String?) ?? '';
      final active = (data['isActive'] as bool?)   ?? true;
      if (!active) return false;
      if (!_matchesTab(type)) return false;
      if (_searchQuery.isNotEmpty &&
          !name.toLowerCase().contains(_searchQuery)) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Text(
            'No ${_tabs[_selectedTab].toLowerCase()} items found.',
            style: const TextStyle(color: _textMuted, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      physics:          const NeverScrollableScrollPhysics(),
      shrinkWrap:       true,
      padding:          const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount:        filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final data  = filtered[i].data() as Map<String, dynamic>;
        final docId = filtered[i].id;
        final type  = (data['type'] as String?) ?? '';
        return _ProductTile(
          data:      data,
          docId:     docId,
          isBakery:  _isBakery(type),
        );
      },
    );
  }

  Widget _bottomNav() {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: _brown,
        boxShadow: [
          BoxShadow(
              color:      Colors.black26,
              blurRadius: 10,
              offset:     Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon:   Icons.home_rounded,
              label:  'Home',
              active: false,
              onTap:  () => Navigator.of(context).pop(),
            ),
            _NavItem(
                icon:   Icons.local_cafe_outlined,
                label:  'Drink Menu',
                active: true,
                onTap:  () {}),
            _NavItem(
              icon:   Icons.receipt_long_outlined,
              label:  'Your Order',
              active: false,
              onTap:  () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const YourOrdersScreen()),
              ),
            ),
            _NavItem(
                icon:   Icons.favorite_border_rounded,
                label:  'Favorites',
                active: false,
                onTap:  () {}),
          ],
        ),
      ),
    );
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
            _header(),
            _searchBar(),
            _tabBar(),
            const SizedBox(height: 4),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ProductID')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _brown));
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: _textMuted),
                          textAlign: TextAlign.center),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child:   _productList(docs),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon();

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderWidget.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                color: _textDark, size: 22),
            if (cart.totalCount > 0)
              Positioned(
                right: -4, top: -4,
                child: Container(
                  width:  16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: _brown, shape: BoxShape.circle),
                  child: Text(
                    '${cart.totalCount}',
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String               docId;
  final bool                 isBakery;

  const _ProductTile({
    required this.data,
    required this.docId,
    required this.isBakery,
  });

  void _navigate(BuildContext context) {
    if (isBakery) {
      BakeryDetailScreen.show(context, docId: docId, data: data);
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
            docId: docId, initialData: data),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String  name     = (data['name']     as String?) ?? 'Unknown';
    final num     price    = (data['price']    as num?)    ?? 0;
    final String? imageUrl = (data['imageURL'] as String?);

    return GestureDetector(
      onTap: () => _navigate(context),
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft:    Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width:  90,
                height: 90,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color:      _textDark,
                          fontSize:   14,
                          fontWeight: FontWeight.w700,
                          height:     1.2)),
                  const SizedBox(height: 6),
                  Text('Rs ${price.toStringAsFixed(0)}.000',
                      style: const TextStyle(
                          color:      _brown,
                          fontSize:   13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  final cart = CartProviderWidget.of(context);
                  cart.addItem(CartItem(
                    docId:       docId,
                    name:        name,
                    unitPrice:   price,
                    imageUrl:    imageUrl,
                    category:    isBakery ? 'bakery' : 'drink',
                    productType: isBakery ? 'bakery' : 'drink',
                    description: (data['description'] as String?),
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name added to cart!',
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: _brown,
                      duration:        const Duration(seconds: 2),
                      behavior:        SnackBarBehavior.floating,
                      shape:           RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  width:  34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:        _brown,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF5EDD8),
        child: Center(
          child: Icon(
            Icons.local_cafe_rounded,
            color: const Color(0xFF834D1E).withOpacity(0.3),
            size:  30,
          ),
        ),
      );
}

class _HeaderIcon extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child:   Icon(icon, color: _textDark, size: 22),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg =
        active ? Colors.white : Colors.white.withOpacity(0.75);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:      fg,
                    fontSize:   10,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width:  active ? 18 : 0,
              decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(99)),
            ),
          ],
        ),
      ),
    );
  }
}