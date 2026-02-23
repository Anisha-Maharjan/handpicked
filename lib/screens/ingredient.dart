import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color _brown     = Color(0xFF834D1E);
const Color _cream     = Color(0xFFF5EDD8);
const Color _textDark  = Color(0xFF3B2005);
const Color _textMuted = Color(0xFF9B8165);

// ─────────────────────────────────────────────────────────────────────────────
class IngredientsListScreen extends StatelessWidget {
  const IngredientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: back arrow + title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _textDark,
                      size: 22,
                    ),
                    splashRadius: 22,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Ingredients List',
                    style: TextStyle(
                      color:      _textDark,
                      fontSize:   20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Ingredient list from Firestore ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Ingredients')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _brown));
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error: ${snap.error}',
                          style: const TextStyle(color: _textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No ingredients found.',
                        style: TextStyle(color: _textMuted, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics:          const BouncingScrollPhysics(),
                    padding:          const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount:        docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _IngredientCard(data: data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ingredient card ──────────────────────────────────────────────────────────
class _IngredientCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _IngredientCard({required this.data});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // URL could not be launched
    }
  }

  @override
  Widget build(BuildContext context) {
    final String  name        = (data['name']        as String?) ?? 'Unknown';
    final String  description = (data['description'] as String?) ?? '';
    final String? imageUrl    = (data['imageURL']    as String?);  // image only
    final String? linkUrl     = (data['url']         as String?);  // clickable link

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        const Color(0xFFF9F3E8),
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: const Color(0xFFE8D5BC), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image (imageURL field) ──
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width:  72,
              height: 72,
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

          // ── Name, description, url ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),

                // Name
                Text(
                  name,
                  style: const TextStyle(
                    color:      _textDark,
                    fontSize:   14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    color:    _textMuted,
                    fontSize: 12,
                    height:   1.45,
                  ),
                ),

                // Clickable URL (url field) — shown only if present
                if (linkUrl != null && linkUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => _launchUrl(linkUrl),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Learn more',
                              style: TextStyle(
                                color:           _brown,
                                fontSize:        11,
                                fontWeight:      FontWeight.w700,
                                decoration:      TextDecoration.underline,
                                decorationColor: _brown,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.open_in_new_rounded,
                                color: _brown, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: _cream,
        child: Center(
          child: Icon(
            Icons.local_cafe_rounded,
            color: _brown.withOpacity(0.3),
            size:  28,
          ),
        ),
      );
}