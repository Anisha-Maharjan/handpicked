import 'package:flutter/material.dart';
import 'package:handpicked/providers/cart_provider.dart';

const Color _cBrown     = Color(0xFF834D1E);
const Color _cCream     = Color(0xFFF5EDD8);
const Color _cTextDark  = Color(0xFF1E1E1E);
const Color _cTextMuted = Color(0xFF9B8165);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<int> _checked = {};
  bool _placing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final count = CartProviderWidget.of(context).items.length;
    _checked.removeWhere((i) => i >= count);
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      final cart    = CartProviderWidget.of(context);
      final orderId = await cart.placeOrder();
      if (!mounted) return;
      setState(() => _checked.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order $orderId placed successfully!',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: _cBrown,
          behavior:        SnackBarBehavior.floating,
          shape:           RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart  = CartProviderWidget.of(context);
    final items = cart.items;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: _cTextDark, size: 22),
                    splashRadius: 22,
                    padding:     EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  const Text('My Cart',
                      style: TextStyle(
                          color:      _cTextDark,
                          fontSize:   20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              color: _cBrown.withOpacity(0.3), size: 64),
                          const SizedBox(height: 12),
                          const Text('Your cart is empty',
                              style: TextStyle(
                                  color:    _cTextMuted,
                                  fontSize: 15)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics:  const BouncingScrollPhysics(),
                      padding:  const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        return _CartTile(
                          item:      item,
                          checked:   _checked.contains(i),
                          onCheck:   (v) => setState(() {
                            if (v == true) {
                              _checked.add(i);
                            } else {
                              _checked.remove(i);
                            }
                          }),
                          onIncrement: () =>
                              setState(() => cart.increment(i)),
                          onDecrement: () =>
                              setState(() => cart.decrement(i)),
                        );
                      },
                    ),
            ),

            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: GestureDetector(
                  onTap: _placing ? null : _placeOrder,
                  child: Container(
                    height:     54,
                    alignment:  Alignment.center,
                    decoration: BoxDecoration(
                      color:        _cBrown,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: _placing
                        ? const SizedBox(
                            width:  22,
                            height: 22,
                            child:  CircularProgressIndicator(
                                color:       Colors.white,
                                strokeWidth: 2.5),
                          )
                        : const Text('Place Order',
                            style: TextStyle(
                                color:      Colors.white,
                                fontSize:   16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem     item;
  final bool         checked;
  final ValueChanged<bool?> onCheck;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartTile({
    required this.item,
    required this.checked,
    required this.onCheck,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        _cCream,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: const Color(0xFFE8D5BC), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width:  24,
            height: 24,
            child:  Checkbox(
              value:           checked,
              onChanged:       onCheck,
              activeColor:     _cBrown,
              shape:           RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              side:            BorderSide(
                  color: _cBrown.withOpacity(0.4), width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width:  56,
              height: 56,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        color:      _cTextDark,
                        fontSize:   14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {},
                  child: const Text('Details',
                      style: TextStyle(
                          color:      _cBrown,
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: _cBrown)),
                ),
              ],
            ),
          ),

          Row(
            children: [
              GestureDetector(
                onTap: onIncrement,
                child: const Text('+',
                    style: TextStyle(
                        color:      _cTextDark,
                        fontSize:   18,
                        fontWeight: FontWeight.w600)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.quantity}',
                    style: const TextStyle(
                        color:      _cTextDark,
                        fontSize:   14,
                        fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: onDecrement,
                child: const Text('−',
                    style: TextStyle(
                        color:      _cTextDark,
                        fontSize:   18,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFEDD9BB),
        child: Center(
          child: Icon(Icons.local_cafe_rounded,
              color: _cBrown.withOpacity(0.3), size: 22),
        ),
      );
}
