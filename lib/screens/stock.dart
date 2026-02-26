import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:handpicked/services/cloudinary_upload.dart';

//Palette 
const Color _brown      = Color(0xFF7B4A1E);
const Color _brownLight = Color(0xFF9C6235);
const Color _cream      = Color(0xFFF5EDD8);
const Color _cardCream  = Color(0xFFF9F3E8);
const Color _textDark   = Color(0xFF3B2005);
const Color _textMuted  = Color(0xFF9B8165);

//Filter types
const List<String> _filterTypes = [
  'All', 'Milk', 'Sugar', 'Coffee Beans', 'Toppings', 'Sweetener',
];

//Status helpers 
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
    case 'milk':   return 'L';
    case 'syrup':  return 'L';
    default:       return 'KG';
  }
}

// Auto-compute status from percent
String _statusFromPercent(double percent) {
  if (percent <= 0.25) return 'critical';
  if (percent <= 0.55) return 'low';
  return 'in_stock';
}

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _selectedFilter = 'All';

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText:      label,
        labelStyle:     const TextStyle(color: _textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        focusedBorder:  OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: _brown),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: _brown.withOpacity(0.3)),
        ),
      );

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Stock Control',
            style: TextStyle(
              color:         _brown,
              fontSize:      22,
              fontWeight:    FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Row(
            children: [
              // Active filter chip
              if (_selectedFilter != 'All')
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        _brown,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilter,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFilter = 'All'),
                        child: const Icon(Icons.close, color: Colors.white, size: 13),
                      ),
                    ],
                  ),
                ),
              // Filter button
              GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        _selectedFilter != 'All'
                        ? _brown.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: _brown,
                    size:  24,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Add ingredient button
              GestureDetector(
                onTap: _showAddIngredientDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        _brown,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //Filter bottom sheet 
  void _showFilterSheet() {
    showModalBottomSheet(
      context:         context,
      shape:           const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:        Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Filter by Type',
              style: TextStyle(
                color: _textDark, fontSize: 16, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing:   10,
              runSpacing: 10,
              children: _filterTypes.map((type) {
                final selected = _selectedFilter == type;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilter = type);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:        selected ? _brown : _cream,
                      borderRadius: BorderRadius.circular(20),
                      border:       Border.all(
                        color: selected ? _brown : _brown.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color:      selected ? Colors.white : _brown,
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  //Add ingredient dialog 
  void _showAddIngredientDialog() {
    final nameCtrl    = TextEditingController();
    final descCtrl    = TextEditingController();
    final urlCtrl     = TextEditingController();
    final amountCtrl  = TextEditingController();
    final currentCtrl = TextEditingController();
    String selectedType = 'Milk';
    String? uploadedUrl;
    bool    uploading   = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Add Ingredient',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Image picker ──
                _stockImagePicker(
                  existingUrl: uploadedUrl,
                  uploading:   uploading,
                  onPick: () async {
                    setDlgState(() => uploading = true);
                    final url = await pickAndUploadImage();
                    setDlgState(() {
                      uploadedUrl = url;
                      uploading   = false;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl,  decoration: _inputDecoration('Name')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl,  decoration: _inputDecoration('Description')),
                const SizedBox(height: 10),
                TextField(controller: urlCtrl,   decoration: _inputDecoration('Source URL (url)')),
                const SizedBox(height: 10),
                TextField(
                  controller:   amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:   _inputDecoration('Total Amount (max)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller:   currentCtrl,
                  keyboardType: TextInputType.number,
                  decoration:   _inputDecoration('Current Amount'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value:      selectedType,
                  decoration: _inputDecoration('Type'),
                  items: ['Milk', 'Sugar', 'Coffee Beans', 'Toppings', 'Sweetener', 'Syrup']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDlgState(() => selectedType = v ?? selectedType),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _textMuted)),
            ),
            ElevatedButton(
              onPressed: uploading ? null : () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final max     = num.tryParse(amountCtrl.text.trim())  ?? 100;
                final current = num.tryParse(currentCtrl.text.trim()) ?? max;
                final percent = _amountToPercent(current, maxAmount: max);
                final status  = _statusFromPercent(percent);
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('Ingredients').add({
                  'name':          nameCtrl.text.trim(),
                  'description':   descCtrl.text.trim(),
                  'imageURL':      uploadedUrl ?? '',
                  'url':           urlCtrl.text.trim(),
                  'type':          selectedType,
                  'Amount':        max,
                  'currentAmount': current,
                  'status':        status,
                  'updatedAt':     FieldValue.serverTimestamp(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Ingredient card 
  Widget _ingredientCard(Map<String, dynamic> data) {
    final String  name      = (data['name']   as String?)  ?? 'Unknown';
    final String  type      = (data['type']   as String?)  ?? '';
    final String  statusRaw = (data['status'] as String?)  ?? 'in_stock';
    final num     maxAmount = (data['Amount'] ?? data['amount'] ?? 100) as num;
    final num     amount    = (data['currentAmount'] ?? maxAmount) as num;
    final String? imageUrl  = (data['imageURL'] as String?);

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
                  width: 52, height: 52,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl, fit: BoxFit.cover,
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
                    Text(name,
                        style: const TextStyle(
                            color: _textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(type,
                        style: const TextStyle(color: _textMuted, fontSize: 12)),
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
                    color: sc.textColor, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Current level ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current level',
                  style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              Text('${amount.toStringAsFixed(0)} / ${maxAmount.toStringAsFixed(0)} ($unit)',
                  style: const TextStyle(color: _textDark, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),

          const SizedBox(height: 6),

          //Progress bar
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

          //Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Delete button
              OutlinedButton(
                onPressed: () => _confirmDelete(data),
                style: OutlinedButton.styleFrom(
                  side:          BorderSide(color: const Color(0xFFB00020).withOpacity(0.5)),
                  shape:         RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding:       const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize:   Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('DELETE',
                    style: TextStyle(
                        color: Color(0xFFB00020), fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
              const SizedBox(width: 8),
              // Restock button
              OutlinedButton(
                onPressed: () => _showRestockDialog(name, data),
                style: OutlinedButton.styleFrom(
                  side:          BorderSide(color: _brown.withOpacity(0.5)),
                  shape:         RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding:       const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize:   Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('RESTOCK',
                    style: TextStyle(
                        color: _brown, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //Image picker widget for Add Ingredient dialog 
  Widget _stockImagePicker({
    required String? existingUrl,
    required bool    uploading,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: uploading ? null : onPick,
      child: Container(
        width:  double.infinity,
        height: 110,
        decoration: BoxDecoration(
          color:        _cream,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: _brown.withOpacity(0.3)),
        ),
        child: uploading
            ? const Center(child: CircularProgressIndicator(color: _brown))
            : existingUrl != null && existingUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(existingUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _stockImgPlaceholder()),
                        Positioned(
                          bottom: 6, right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:        Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Change', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _stockImgPlaceholder(),
      ),
    );
  }

  Widget _stockImgPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: _brown.withOpacity(0.6), size: 32),
          const SizedBox(height: 6),
          Text('Tap to add image',
              style: TextStyle(color: _textMuted, fontSize: 12)),
        ],
      );

  Widget _thumbPlaceholder() => Container(
        color: _cream,
        child: const Icon(Icons.local_cafe_rounded, color: _brownLight, size: 24),
      );

  //Delete confirmation 
  Future<void> _confirmDelete(Map<String, dynamic> data) async {
    final String  name  = (data['name']  as String?) ?? 'this ingredient';
    final String? docId = data['_docId'] as String?;
    if (docId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Ingredient',
            style: TextStyle(fontWeight: FontWeight.w700, color: _textDark)),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB00020),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await FirebaseFirestore.instance.collection('Ingredients').doc(docId).delete();
  }

  //Restock dialog 
  void _showRestockDialog(String name, Map<String, dynamic> data) {
    final ctrl = TextEditingController();
    final String unit = _unitForType((data['type'] as String?) ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Restock $name',
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700)),
        content: TextField(
          controller:   ctrl,
          keyboardType: TextInputType.number,
          decoration:   _inputDecoration('Add amount ($unit)'),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _restock(Map<String, dynamic> data, num addAmount) async {
    final String? docId   = data['_docId'] as String?;
    if (docId == null) return;

    final num current = (data['currentAmount'] ?? data['Amount'] ?? 0) as num;
    final num max     = (data['Amount'] ?? 100) as num;
    final num updated = (current + addAmount).clamp(0, max);
    final double percent  = _amountToPercent(updated, maxAmount: max);
    final String newStatus = _statusFromPercent(percent);

    await FirebaseFirestore.instance
        .collection('Ingredients')
        .doc(docId)
        .update({
      'currentAmount': updated,
      'status':        newStatus,
      'updatedAt':     FieldValue.serverTimestamp(),
    });
  }

  //Build 
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
                return const Center(child: CircularProgressIndicator(color: _brown));
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
                          style: const TextStyle(color: _textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var docs = snap.data?.docs ?? [];

              // Apply type filter
              if (_selectedFilter != 'All') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final type = (data['type'] as String?) ?? '';
                  return type.toLowerCase() == _selectedFilter.toLowerCase();
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    _selectedFilter == 'All'
                        ? 'No ingredients found.'
                        : 'No $_selectedFilter ingredients found.',
                    style: const TextStyle(color: _textMuted, fontSize: 14),
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