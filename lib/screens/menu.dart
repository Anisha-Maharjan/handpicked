import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color _brown     = Color(0xFF834D1E);
const Color _brownDark = Color(0xFF5C3210);
const Color _cream     = Color(0xFFF5EDD8);
const Color _textDark  = Color(0xFF1E1E1E);
const Color _textMuted = Color(0xFF9B8165);

// ─────────────────────────────────────────────────────────────────────────────
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedTab = 0; // 0=Drink 1=Bakery 2=Custom
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<String> _tabs = ['Drink', 'Bakery', 'Custom'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesTab(String type) {
    final t = type.toLowerCase().trim();
    switch (_selectedTab) {
      case 0: return t == 'drink' || t == 'drinks';
      case 1: return t == 'bakery' || t == 'food' || t == 'pastry';
      case 2: return t == 'custom';
      default: return false;
    }
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: const Text(
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
              _HeaderIcon(icon: Icons.shopping_cart_outlined, onTap: () {}),
              const SizedBox(width: 6),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeaderIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
                  Positioned(
                    right: 2, top: 2,
                    child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              _HeaderIcon(icon: Icons.menu_rounded, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────────
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
          controller:  _searchCtrl,
          onChanged:   (v) => setState(() => _searchQuery = v.toLowerCase()),
          style:        const TextStyle(fontSize: 13, color: _textDark),
          decoration:  InputDecoration(
            hintText:       'Search..',
            hintStyle:      TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon:     Icon(Icons.search, color: Colors.grey.shade400, size: 18),
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────
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
            // Insert dividers between tabs
            if (i.isOdd) {
              return Container(width: 1, height: 20, color: _brown.withOpacity(0.25));
            }
            final tabIdx = i ~/ 2;
            final selected = _selectedTab == tabIdx;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = tabIdx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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

  // ── Product list ─────────────────────────────────────────────────────────────
  Widget _productList(List<QueryDocumentSnapshot> allDocs) {
    final filtered = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final type   = (data['type']   as String?) ?? '';
      final name   = (data['name']   as String?) ?? '';
      final active = (data['isActive'] as bool?)  ?? true;
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
      physics:     const NeverScrollableScrollPhysics(),
      shrinkWrap:  true,
      padding:     const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount:   filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final data  = filtered[i].data() as Map<String, dynamic>;
        final docId = filtered[i].id;
        return _ProductTile(data: data, docId: docId);
      },
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────────────────────
  Widget _bottomNav() {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: _brown,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -4)),
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
            _NavItem(icon: Icons.local_cafe_outlined, label: 'Drink Menu', active: true, onTap: () {}),
            _NavItem(icon: Icons.receipt_long_outlined, label: 'Your Order', active: false, onTap: () {}),
            _NavItem(icon: Icons.favorite_border_rounded, label: 'Favorites', active: false, onTap: () {}),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
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

// ─── Product tile ─────────────────────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _ProductTile({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final String  name     = (data['name']     as String?) ?? 'Unknown';
    final num     price    = (data['price']    as num?)    ?? 0;
    final String? imageUrl = (data['imageURL'] as String?);

    return Container(
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
          // ── Thumbnail ──
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(16),
              bottomLeft:  Radius.circular(16),
            ),
            child: SizedBox(
              width:  90,
              height: 90,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),

          const SizedBox(width: 14),

          // ── Name + price ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color:      _textDark,
                    fontSize:   14,
                    fontWeight: FontWeight.w700,
                    height:     1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs ${price.toStringAsFixed(0)}.000',
                  style: const TextStyle(
                    color:      _brown,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Add button ──
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () {
                // TODO: add to cart
              },
              child: Container(
                width:  34,
                height: 34,
                decoration: BoxDecoration(
                  color:        _brown,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF5EDD8),
        child: Center(
          child: Icon(Icons.local_cafe_rounded,
              color: const Color(0xFF834D1E).withOpacity(0.3), size: 30),
        ),
      );
}

// ─── Header icon ──────────────────────────────────────────────────────────────
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, color: const Color(0xFF1E1E1E), size: 22),
      ),
    );
  }
}

// ─── Bottom nav item ──────────────────────────────────────────────────────────
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
                  color: fg, fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width:  active ? 18 : 0,
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}