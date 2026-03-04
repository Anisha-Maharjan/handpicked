import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:handpicked/screens/ingredient.dart';

const Color _brown     = Color(0xFF834D1E);
const Color _cream     = Color(0xFFF5EDD8);
const Color _textDark  = Color(0xFF1E1E1E);
const Color _textMuted = Color(0xFF9B8165);

class ProductDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const ProductDetailScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavourite = false;

  String? _selectedMilkType;
  String? _selectedSweetenerType;
  final Set<String> _selectedExtras = {};

  bool _milkExpanded      = false;
  bool _sweetenerExpanded = false;
  bool _extrasExpanded    = false;

  static const List<String> _milkOptions = [
    'Oat Milk',
    'Whole Milk',
    'Low Fat Milk',
    'Soy Milk',
  ];

  static const List<String> _sweetenerOptions = [
    'Sugar Syrup',
    'Honey',
    'White Sugar',
    'Brown Sugar',
  ];

  static const List<String> _extrasOptions = [
    'Whipped Cream',
    'Tapioca Pearl',
    'Sprinkles',
    'Chocolate Syrup',
    'Marshmallow',
  ];

  final TextEditingController _instructionCtrl = TextEditingController();

  @override
  void dispose() {
    _instructionCtrl.dispose();
    super.dispose();
  }

  Widget _singleSelectOption({
    required String label,
    required bool expanded,
    required List<String> options,
    required String? selected,
    required VoidCallback onToggle,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color:      _textDark,
                        fontSize:   14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:        _brown.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selected,
                          style: const TextStyle(
                            color:      _brown,
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _textDark,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = selected == opt;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color:        isSelected ? _brown : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(
                      color: isSelected ? _brown : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      color:      isSelected ? Colors.white : _textDark,
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        Divider(color: Colors.grey.shade200, height: 1),
      ],
    );
  }

  Widget _multiSelectOption({
    required String label,
    required bool expanded,
    required List<String> options,
    required Set<String> selected,
    required VoidCallback onToggle,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color:      _textDark,
                        fontSize:   14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (selected.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:        _brown.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selected.length} added',
                          style: const TextStyle(
                            color:      _brown,
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _textDark,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = selected.contains(opt);
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color:        isSelected ? _brown : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(
                      color: isSelected ? _brown : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        opt,
                        style: TextStyle(
                          color:      isSelected ? Colors.white : _textDark,
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        Divider(color: Colors.grey.shade200, height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ProductID')
          .doc(widget.docId)
          .snapshots(),
      builder: (ctx, snap) {
        final data = (snap.hasData && snap.data!.exists)
            ? snap.data!.data() as Map<String, dynamic>
            : widget.initialData;

        final String  name        = (data['name']        as String?) ?? 'Unknown';
        final String  description = (data['description'] as String?) ?? '';
        final num     price       = (data['price']       as num?)    ?? 0;
        final String? imageUrl    = (data['imageURL']    as String?);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            width:  double.infinity,
                            height: 300,
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholder(),
                                  )
                                : _imagePlaceholder(),
                          ),
                          Positioned(
                            bottom: 0,
                            left:   0,
                            right:  0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end:   Alignment.topCenter,
                                  colors: [
                                    Color(0xCC000000),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color:      Colors.white,
                                      fontSize:   20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        color:    Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _CircleButton(
                                    icon:  Icons.arrow_back_rounded,
                                    onTap: () => Navigator.of(context).pop(),
                                  ),
                                  _CircleButton(
                                    icon:  _isFavourite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    iconColor: _isFavourite
                                        ? Colors.redAccent
                                        : Colors.white,
                                    onTap: () =>
                                        setState(() => _isFavourite = !_isFavourite),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rs. ${price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color:      _textDark,
                                    fontSize:   16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                _QuantitySelector(
                                  quantity:   _quantity,
                                  onDecrement: () {
                                    if (_quantity > 1) {
                                      setState(() => _quantity--);
                                    }
                                  },
                                  onIncrement: () =>
                                      setState(() => _quantity++),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            Divider(color: Colors.grey.shade200, height: 1),

                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const IngredientsListScreen(),
                                ),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'View Ingredient List',
                                      style: TextStyle(
                                        color:      _textDark,
                                        fontSize:   14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: _textDark, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            Divider(color: Colors.grey.shade200, height: 1),

                            const SizedBox(height: 10),
                            const Text(
                              'Select Options:',
                              style: TextStyle(
                                color:      _textDark,
                                fontSize:   14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            _singleSelectOption(
                              label:    'Milk Type',
                              expanded: _milkExpanded,
                              options:  _milkOptions,
                              selected: _selectedMilkType,
                              onToggle: () => setState(() => _milkExpanded = !_milkExpanded),
                              onSelect: (v) => setState(() => _selectedMilkType = v),
                            ),

                            _singleSelectOption(
                              label:    'Sweetener Type',
                              expanded: _sweetenerExpanded,
                              options:  _sweetenerOptions,
                              selected: _selectedSweetenerType,
                              onToggle: () => setState(() => _sweetenerExpanded = !_sweetenerExpanded),
                              onSelect: (v) => setState(() => _selectedSweetenerType = v),
                            ),

                            _multiSelectOption(
                              label:    'Add extras',
                              expanded: _extrasExpanded,
                              options:  _extrasOptions,
                              selected: _selectedExtras,
                              onToggle: () => setState(() => _extrasExpanded = !_extrasExpanded),
                              onSelect: (v) => setState(() {
                                if (_selectedExtras.contains(v)) {
                                  _selectedExtras.remove(v);
                                } else {
                                  _selectedExtras.add(v);
                                }
                              }),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: InkWell(
                                onTap: () {},
                                child: const Text(
                                  'Add special instruction',
                                  style: TextStyle(
                                    color:      _textDark,
                                    fontSize:   14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Divider(color: Colors.grey.shade200, height: 1),

                            const SizedBox(height: 12),
                            Container(
                              height:     90,
                              width:      double.infinity,
                              decoration: BoxDecoration(
                                color:        _cream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: TextField(
                                controller: _instructionCtrl,
                                maxLines:   null,
                                style: const TextStyle(
                                    fontSize: 13, color: _textDark),
                                decoration: InputDecoration(
                                  hintText:  '...........',
                                  hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13),
                                  border:         InputBorder.none,
                                  isDense:        true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label:   'Buy Now',
                        filled:  true,
                        onTap:   () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label:   'Add to cart',
                        filled:  false,
                        onTap:   () {},
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
  }

  Widget _imagePlaceholder() => Container(
        color: _cream,
        child: Center(
          child: Icon(Icons.local_cafe_rounded,
              color: _brown.withOpacity(0.3), size: 60),
        ),
      );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  36,
        height: 36,
        decoration: BoxDecoration(
          color:  Colors.black.withOpacity(0.28),
          shape:  BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onIncrement,
          child: const Text(
            '+',
            style: TextStyle(
              color:      _textDark,
              fontSize:   18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$quantity',
            style: const TextStyle(
              color:      _textDark,
              fontSize:   15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: onDecrement,
          child: const Text(
            '−',
            style: TextStyle(
              color:      _textDark,
              fontSize:   18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String       label;
  final bool         filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height:     52,
        alignment:  Alignment.center,
        decoration: BoxDecoration(
          color:        filled ? _brown : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border:       filled ? null : Border.all(color: _brown, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      filled ? Colors.white : _brown,
            fontSize:   15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}