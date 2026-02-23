import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color _brown      = Color(0xFF7B4A1E);
const Color _brownLight = Color(0xFF9C6235);
const Color _cream      = Color(0xFFF5EDD8);
const Color _cardCream  = Color(0xFFF9F3E8);
const Color _textDark   = Color(0xFF3B2005);
const Color _textMuted  = Color(0xFF9B8165);

// ─── Status helpers ───────────────────────────────────────────────────────────
class _StatusConfig {
  final String label;
  final Color  background;
  final Color  textColor;
  const _StatusConfig(this.label, this.background, this.textColor);
}

_StatusConfig _statusConfig(String raw) {
  switch (raw.toLowerCase()) {
    case 'critical':
      return _StatusConfig('CRITICAL', const Color(0xFFFFE5E5), const Color(0xFFB00020));
    case 'low':
      return _StatusConfig('LOW', const Color(0xFFFFF3CD), const Color(0xFF7B5E00));
    case 'in_stock':
    default:
      return _StatusConfig('IN STOCK', const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
  }
}

double _amountToPercent(num amount, {num maxAmount = 100}) =>
    (amount / maxAmount).clamp(0.0, 1.0).toDouble();

Color _progressColor(double percent) {
  if (percent <= 0.25) return const Color(0xFFD32F2F);
  if (percent <= 0.50) return const Color(0xFFF57C00);
  return const Color(0xFF7B4A1E);
}

String _unitForType(String type) {
  switch (type.toLowerCase()) {
    case 'milk':
      return 'L';
    case 'syrup':
      return 'L';
    case 'coffee beans':
    case 'beans':
    case 'sweetener':
    case 'toppings':
    default:
      return 'KG';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StockScreen is used as a tab inside AdminHomeScreen's IndexedStack.
// It does NOT have its own Scaffold or bottomNavigationBar — those live in
// AdminHomeScreen so only one nav bar appears.
// ─────────────────────────────────────────────────────────────────────────────
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'Stock Control',
            style: TextStyle(
              color:         _brown,
              fontSize:      22,
              fontWeight:    FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Icon(Icons.menu_rounded, color: _brown, size: 24),
        ],
      ),
    );
  }

  // ── Ingredient card ──────────────────────────────────────────────────────────
  Widget _ingredientCard(Map<String, dynamic> data) {
    final String  name      = (data['name']   as String?)  ?? 'Unknown';
    final String  type      = (data['type']   as String?)  ?? '';
    final String  statusRaw = (data['status'] as String?)  ?? 'in_stock';
    final num     maxAmount     = (data['Amount'] ?? data['amount'] ?? 100) as num;
    final num     amount        = (data['currentAmount'] ?? maxAmount) as num;
    final String? imageUrl  = (data['imageURL'] ?? data['url']) as String?;

    final double        percent  = _amountToPercent(amount, maxAmount: maxAmount);
    final _StatusConfig sc       = _statusConfig(statusRaw);
    final Color         barColor = _progressColor(percent);
    final String        unit     = _unitForType(type);

    return Container(
      margin:  const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        _cardCream,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _brown.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + name/type + status badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width:  52,
                  height: 52,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type,
                      style: const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        sc.background,
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: sc.textColor.withOpacity(0.25)),
                ),
                child: Text(
                  sc.label,
                  style: TextStyle(
                    color:         sc.textColor,
                    fontSize:      10,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Current level label + percentage ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current level',
                style: TextStyle(
                  color:      _textMuted,
                  fontSize:   12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}% ($unit)',
                style: const TextStyle(
                  color:      _textDark,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           percent,
              backgroundColor: _brown.withOpacity(0.12),
              valueColor:      AlwaysStoppedAnimation<Color>(barColor),
              minHeight:       6,
            ),
          ),

          const SizedBox(height: 10),

          // ── Restock button ──
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _showRestockDialog(name, data),
              style: OutlinedButton.styleFrom(
                side:          BorderSide(color: _brown.withOpacity(0.5)),
                shape:         RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:       const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize:   Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'RESTOCK',
                style: TextStyle(
                  color:         _brown,
                  fontSize:      10,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        color: _cream,
        child: const Icon(Icons.local_cafe_rounded, color: _brownLight, size: 24),
      );

  // ── Restock dialog ──────────────────────────────────────────────────────────
  void _showRestockDialog(String name, Map<String, dynamic> data) {
    final ctrl = TextEditingController();
    final String unit = _unitForType((data['type'] as String?) ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restock $name',
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller:   ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText:  'Add amount ($unit)',
            labelStyle: const TextStyle(color: _textMuted),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:   const BorderSide(color: _brown),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:   BorderSide(color: _brown.withOpacity(0.3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final add = num.tryParse(ctrl.text);
              if (add == null || add <= 0) return;
              Navigator.pop(ctx);
              await _restock(data, add);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restock(Map<String, dynamic> data, num addAmount) async {
    final String? docId = data['_docId'] as String?;
    if (docId == null) return;

    final num current = (data['currentAmount'] ?? data['Amount'] ?? 0) as num;
    final num max     = (data['Amount'] ?? 100) as num;
    final num updated = (current + addAmount).clamp(0, max);

    final String newStatus = updated <= 25
        ? 'critical'
        : updated <= 55
            ? 'low'
            : 'in_stock';

    await FirebaseFirestore.instance
        .collection('Ingredients')
        .doc(docId)
        .update({
      'currentAmount': updated,
      'status':    newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  // Returns a plain Column with no Scaffold — AdminHomeScreen owns the Scaffold.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Ingredients')
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _brown),
                );
              }

              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFB00020), size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load ingredients:\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: _textMuted, fontSize: 13),
                        ),
                      ],
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

              return ListView.builder(
                physics:   const BouncingScrollPhysics(),
                padding:   const EdgeInsets.only(top: 4, bottom: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = {
                    ...(docs[i].data() as Map<String, dynamic>),
                    '_docId': docs[i].id,
                  };
                  return _ingredientCard(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}