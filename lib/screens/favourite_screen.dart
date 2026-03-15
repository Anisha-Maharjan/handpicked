import 'package:flutter/material.dart';
import 'package:handpicked/providers/favourites_provider.dart';
import 'package:handpicked/screens/product_detail.dart';
import 'package:handpicked/screens/bakery_detail.dart';
import 'package:handpicked/screens/menu.dart';
import 'package:handpicked/screens/your_orders_screen.dart';

const Color _fsBrown = Color(0xFF834D1E);
const Color _fsCream = Color(0xFFF5EDD8);
const Color _fsDark  = Color(0xFF1E1E1E);

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = FavouritesProviderWidget.of(context);
    final items    = provider.items;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Your favorite drinks to\nlighten up your day',
                style: TextStyle(
                  color:      _fsBrown,
                  fontSize:   22,
                  fontWeight: FontWeight.w800,
                  height:     1.2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Grid ────────────────────────────────────────────────
            Expanded(
              child: items.isEmpty
                  ? _EmptyState()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        physics:  const BouncingScrollPhysics(),
                        padding:  const EdgeInsets.only(bottom: 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:   2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing:  12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) =>
                            _FavouriteCard(item: items[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),

      // ── Bottom Nav ──────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(activeIndex: 3),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Card
// ────────────────────────────────────────────────────────────────────────────
class _FavouriteCard extends StatelessWidget {
  final FavouriteItem item;

  const _FavouriteCard({required this.item});

  void _openDetail(BuildContext context) {
    final data = <String, dynamic>{
      'name':        item.name,
      'price':       item.price,
      'imageURL':    item.imageUrl,
      'imageUrl':    item.imageUrl,
      'description': '',
    };

    if (item.category == 'bakery') {
      BakeryDetailScreen.show(context, docId: item.docId, data: data);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            docId:       item.docId,
            initialData: data,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = FavouritesProviderWidget.of(context);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ──────────────────────────────────
            item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),

            // ── Dark gradient at bottom ───────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: 90,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
            ),

            // ── Name ─────────────────────────────────────────────
            Positioned(
              left:   12,
              right:  40,
              bottom: 12,
              child: Text(
                item.name,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w800,
                  height:     1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Heart icon ───────────────────────────────────────
            Positioned(
              right:  10,
              bottom: 10,
              child: GestureDetector(
                onTap: () => provider.remove(item.docId),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size:  22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: _fsCream,
        child: Center(
          child: Icon(
            Icons.local_cafe_rounded,
            color: _fsBrown.withOpacity(0.3),
            size:  40,
          ),
        ),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Empty state
// ────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 64, color: _fsBrown.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No favourites yet',
            style: TextStyle(
              color:      _fsBrown,
              fontSize:   16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart on any drink or\nbakery item to save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:    _fsDark.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bottom Nav – mirrors the style from homeScreen.dart
// ────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int activeIndex;

  const _BottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: _fsBrown,
        boxShadow: [
          BoxShadow(
            color:      Colors.black26,
            blurRadius: 10,
            offset:     Offset(0, -4),
          ),
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
              active: activeIndex == 0,
              onTap:  () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
            ),
            _NavItem(
              icon:   Icons.local_cafe_outlined,
              label:  'Drink Menu',
              active: activeIndex == 1,
              onTap:  () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MenuScreen()),
              ),
            ),
            _NavItem(
              icon:   Icons.receipt_long_outlined,
              label:  'Your Order',
              active: activeIndex == 2,
              onTap:  () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const YourOrdersScreen()),
              ),
            ),
            _NavItem(
              icon:   Icons.favorite_rounded,
              label:  'Favorites',
              active: activeIndex == 3,
              onTap:  () {}, // already on this page
            ),
          ],
        ),
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
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:      fg,
                fontSize:   10,
                fontWeight: FontWeight.w700,
              ),
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