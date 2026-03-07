import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:handpicked/providers/cart_provider.dart';

const Color _bkBrown     = Color(0xFF834D1E);
const Color _bkCream     = Color(0xFFF5EDD8);
const Color _bkTextDark  = Color(0xFF1E1E1E);
const Color _bkTextMuted = Color(0xFF9B8165);

class BakeryDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const BakeryDetailScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  static Future<void> show(
    BuildContext context, {
    required String docId,
    required Map<String, dynamic> data,
  }) {
    return showModalBottomSheet(
      context:        context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BakeryDetailScreen(docId: docId, initialData: data),
    );
  }

  @override
  State<BakeryDetailScreen> createState() => _BakeryDetailScreenState();
}

class _BakeryDetailScreenState extends State<BakeryDetailScreen> {
  int  _quantity    = 1;
  bool _isFavourite = false;

  void _addToCart(Map<String, dynamic> data) {
    final cart = CartProviderWidget.of(context);
    cart.addItem(CartItem(
      docId:       widget.docId,
      name:        (data['name']        as String?) ?? 'Unknown',
      unitPrice:   (data['price']       as num?)    ?? 0,
      imageUrl:    (data['imageUrl'] as String?) ?? (data['imageURL'] as String?),
      category:    'bakery',
      description: (data['description'] as String?),
      quantity:    _quantity,
    ));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to cart!',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: _bkBrown,
        duration:        const Duration(seconds: 2),
        behavior:        SnackBarBehavior.floating,
        shape:           RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _buyNow(Map<String, dynamic> data) async {
    final cart = CartProviderWidget.of(context);
    cart.addItem(CartItem(
  docId:       widget.docId,
  name:        (data['name']        as String?) ?? 'Unknown',
  unitPrice:   (data['price']       as num?)    ?? 0,
  imageUrl:    (data['imageUrl'] as String?) ?? (data['imageURL'] as String?),
  category:        'bakery',
  description: (data['description'] as String?),
  quantity:    _quantity,
));
    Navigator.of(context).pop();
    try {
      final orderId = await cart.placeOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order $orderId placed!',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: _bkBrown,
          behavior:        SnackBarBehavior.floating,
          shape:           RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('productID')
          .doc(widget.docId)
          .snapshots(),
      builder: (ctx, snap) {
        final data = (snap.hasData && snap.data!.exists)
            ? snap.data!.data() as Map<String, dynamic>
            : widget.initialData;

        final String  name        = (data['name']        as String?) ?? 'Unknown';
        final String  description = (data['description'] as String?) ?? '';
        final num     price       = (data['price']       as num?)    ?? 0;
        final String? imageUrl    = (data['imageUrl'] as String?) ?? (data['imageURL'] as String?);

        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize:     0.6,
          maxChildSize:     0.95,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width:  40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:        Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollCtrl,
                      physics:    const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24)),
                                child: SizedBox(
                                  width:  double.infinity,
                                  height: 260,
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _placeholder(),
                                        )
                                      : _placeholder(),
                                ),
                              ),

                              Positioned(
                                top:   16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _isFavourite = !_isFavourite),
                                  child: Container(
                                    width:  40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:  Colors.white,
                                      shape:  BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:      Colors.black
                                              .withOpacity(0.12),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isFavourite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: _isFavourite
                                          ? Colors.redAccent
                                          : _bkBrown,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),

                              Positioned(
                                top:  16,
                                left: 16,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width:  40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:  Colors.white,
                                      shape:  BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:      Colors.black
                                              .withOpacity(0.12),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.close_rounded,
                                        color: _bkTextDark,
                                        size:  20),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name.toUpperCase(),
                                        style: const TextStyle(
                                          color:      _bkTextDark,
                                          fontSize:   20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    color:  _bkTextMuted,
                                    fontSize: 13,
                                    height:   1.5,
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Divider(
                                    color: Colors.grey.shade200, height: 1),
                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Qty   ',
                                          style: TextStyle(
                                            color:      _bkTextDark,
                                            fontSize:   15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (_quantity > 1) {
                                              setState(() => _quantity--);
                                            }
                                          },
                                          child: Container(
                                            width:  30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: _bkCream,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.remove,
                                                size:  16,
                                                color: _bkBrown),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            '$_quantity',
                                            style: const TextStyle(
                                              fontSize:   15,
                                              fontWeight: FontWeight.w700,
                                              color:      _bkTextDark,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              setState(() => _quantity++),
                                          child: Container(
                                            width:  30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: _bkCream,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.add,
                                                size:  16,
                                                color: _bkBrown),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Price  Rs. ${price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color:      _bkTextDark,
                                        fontSize:   15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _buyNow(data),
                            child: Container(
                              height:     52,
                              alignment:  Alignment.center,
                              decoration: BoxDecoration(
                                color:        _bkBrown,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: const Text(
                                'Buy Now',
                                style: TextStyle(
                                  color:      Colors.white,
                                  fontSize:   15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _addToCart(data),
                            child: Container(
                              height:     52,
                              alignment:  Alignment.center,
                              decoration: BoxDecoration(
                                color:        Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                    color: _bkBrown, width: 1.5),
                              ),
                              child: const Text(
                                'Add To Cart',
                                style: TextStyle(
                                  color:      _bkBrown,
                                  fontSize:   15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _placeholder() => Container(
        color: _bkCream,
        child: Center(
          child: Icon(Icons.bakery_dining_rounded,
              color: _bkBrown.withOpacity(0.3), size: 60),
        ),
      );
}