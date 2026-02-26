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


class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _selectedCategory = 0;
  final List<String> _categories = ['DRINK', 'BAKERY'];

  bool _matchesCategory(String type) {
    final t = type.toLowerCase();
    if (_selectedCategory == 0) return t == 'drink' || t == 'drinks';
    return t == 'bakery' || t == 'food' || t == 'pastry';
  }

  // Header 
  Widget _header() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        'Inventory',
        style: TextStyle(
          color:         _brown,
          fontSize:      22,
          fontWeight:    FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  //Category tabs 
  Widget _categoryTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: List.generate(_categories.length, (i) {
          final selected = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin:   const EdgeInsets.only(right: 8),
              padding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:        selected ? _brown : _cream,
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(
                  color: selected ? _brown : _brown.withOpacity(0.25),
                ),
              ),
              child: Text(
                _categories[i],
                style: TextStyle(
                  color:         selected ? Colors.white : _brown,
                  fontSize:      11,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  //Product grid
  Widget _productGrid(List<QueryDocumentSnapshot> allDocs) {
    final filtered = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _matchesCategory((data['type'] as String?) ?? '');
    }).toList();

    final itemCount = filtered.length + 1;

    return GridView.builder(
      physics:  const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding:  const EdgeInsets.fromLTRB(16, 16, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   2,
        crossAxisSpacing: 12,
        mainAxisSpacing:  12,
        childAspectRatio: 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: (ctx, i) {
        if (i == filtered.length) return _addNewTile();
        final data  = filtered[i].data() as Map<String, dynamic>;
        final docId = filtered[i].id;
        return _productTile(data, docId);
      },
    );
  }

  //Individual product tile 
  Widget _productTile(Map<String, dynamic> data, String docId) {
    final String  name     = (data['name']     as String?) ?? 'Unknown';
    final String? imageUrl = (data['imageURL'] as String?);
    final bool    isActive = (data['isActive'] as bool?)   ?? true;
    final String  avail    = (data['Availability'] as String?) ?? 'in_stock';

    return GestureDetector(
      onTap: () => _showProductOptions(data, docId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder())
                : _imgPlaceholder(),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.topCenter,
                    end:    Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                    stops:  const [0.45, 1.0],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 12, bottom: 12, right: 40,
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.2,
                ),
              ),
            ),

            Positioned(
              top: 6, right: 6,
              child: GestureDetector(
                onTap: () => _showProductOptions(data, docId),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3), shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                ),
              ),
            ),

            if (!isActive || avail == 'out_of_stock')
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:        Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: _cream,
        child: Center(
          child: Icon(Icons.local_cafe_rounded,
              color: _brownLight.withOpacity(0.4), size: 40),
        ),
      );

  //Add new item tile
  Widget _addNewTile() {
    return GestureDetector(
      onTap: _showAddProductDialog,
      child: Container(
        decoration: BoxDecoration(
          color:        _cardCream,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: _brown.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _brown.withOpacity(0.08), shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: _brown, size: 26),
            ),
            const SizedBox(height: 10),
            const Text('Add new item',
                style: TextStyle(color: _brown, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
  Widget _ingredientChips(List<String> ingredients, StateSetter setDlgState) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ingredients.map((ing) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        _cream,
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: _brown.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ing,
                style: const TextStyle(
                  color:      _textDark,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setDlgState(() => ingredients.remove(ing)),
                child: const Icon(Icons.close, size: 14, color: _textMuted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _ingredientInputRow(
    TextEditingController ctrl,
    List<String> ingredients,
    StateSetter setDlgState,
  ) {
    void addIngredient() {
      final val = ctrl.text.trim();
      if (val.isNotEmpty && !ingredients.contains(val)) {
        setDlgState(() {
          ingredients.add(val);
          ctrl.clear();
        });
      }
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller:         ctrl,
            textCapitalization: TextCapitalization.words,
            decoration:         _dialogDecoration('Add ingredient'),
            onSubmitted:        (_) => addIngredient(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: addIngredient,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        _brown,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  void _showProductOptions(Map<String, dynamic> data, String docId) {
    final String name     = (data['name']     as String?) ?? 'Product';
    final bool   isActive = (data['isActive'] as bool?)   ?? true;

    showModalBottomSheet(
      context:         context,
      shape:           const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize:      MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(name,
                style: const TextStyle(
                    color: _textDark, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _optionTile(
              icon:  Icons.edit_outlined,
              label: 'Edit product',
              onTap: () { Navigator.pop(ctx); _showEditProductDialog(data, docId); },
            ),
            _optionTile(
              icon:  isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              label: isActive ? 'Mark as unavailable' : 'Mark as available',
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance
                    .collection('ProductID').doc(docId)
                    .update({'isActive': !isActive});
              },
            ),
            _optionTile(
              icon:  Icons.delete_outline,
              label: 'Delete product',
              color: const Color(0xFFB00020),
              onTap: () async {
                Navigator.pop(ctx);
                await _confirmDelete(docId, name);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData     icon,
    required String       label,
    required VoidCallback onTap,
    Color?                color,
  }) {
    final c = color ?? _textDark;
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  //Delete confirmation 
  Future<void> _confirmDelete(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product',
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
    await FirebaseFirestore.instance.collection('ProductID').doc(docId).delete();
  }

  //Add product dialog 
  void _showAddProductDialog() {
    final nameCtrl       = TextEditingController();
    final priceCtrl      = TextEditingController();
    final descCtrl       = TextEditingController();
    final ingCtrl        = TextEditingController();
    String selectedType  = _selectedCategory == 0 ? 'drink' : 'bakery';
    final List<String> ingredients = [];
    File?   pickedImage;
    String? uploadedUrl;
    bool    uploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Product',
              style: TextStyle(color: _textDark, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image picker ──
                _imagePicker(
                  pickedImage: pickedImage,
                  existingUrl: uploadedUrl,
                  uploading:   uploading,
                  onPick: () async {
                    setDlgState(() => uploading = true);
                    final url = await pickAndUploadImage();
                    setDlgState(() {
                      uploadedUrl  = url;
                      uploading    = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _dialogField(nameCtrl,  'Name'),
                const SizedBox(height: 10),
                _dialogField(priceCtrl, 'Price', keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                _dialogField(descCtrl,  'Description'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value:      selectedType,
                  decoration: _dialogDecoration('Type'),
                  items: const [
                    DropdownMenuItem(value: 'drink',  child: Text('Drink')),
                    DropdownMenuItem(value: 'bakery', child: Text('Bakery')),
                  ],
                  onChanged: (v) => setDlgState(() => selectedType = v ?? selectedType),
                ),
                const SizedBox(height: 14),
                const Text('Ingredients',
                    style: TextStyle(
                        color: _textDark, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _ingredientInputRow(ingCtrl, ingredients, setDlgState),
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ingredientChips(ingredients, setDlgState),
                ],
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
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('ProductID').add({
                  'name':         nameCtrl.text.trim(),
                  'price':        num.tryParse(priceCtrl.text.trim()) ?? 0,
                  'description':  descCtrl.text.trim(),
                  'imageURL':     uploadedUrl ?? '',
                  'type':         selectedType,
                  'isActive':     true,
                  'Availability': 'in_stock',
                  'ingredients':  ingredients,
                  'createdAt':    FieldValue.serverTimestamp(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  //Edit product dialog
  void _showEditProductDialog(Map<String, dynamic> data, String docId) {
    final nameCtrl  = TextEditingController(text: (data['name']        as String?) ?? '');
    final priceCtrl = TextEditingController(text: (data['price'] ?? '').toString());
    final descCtrl  = TextEditingController(text: (data['description'] as String?) ?? '');
    final ingCtrl   = TextEditingController();
    String selectedType  = (data['type'] as String?) ?? 'drink';
    String? uploadedUrl  = (data['imageURL'] as String?);
    bool    uploading    = false;

    final List<String> ingredients = List<String>.from(
      (data['ingredients'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty && e != 'None'),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Product',
              style: TextStyle(color: _textDark, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image picker ──
                _imagePicker(
                  pickedImage: null,
                  existingUrl: uploadedUrl,
                  uploading:   uploading,
                  onPick: () async {
                    setDlgState(() => uploading = true);
                    final url = await pickAndUploadImage();
                    setDlgState(() {
                      if (url != null) uploadedUrl = url;
                      uploading = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _dialogField(nameCtrl,  'Name'),
                const SizedBox(height: 10),
                _dialogField(priceCtrl, 'Price', keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                _dialogField(descCtrl,  'Description'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value:      selectedType,
                  decoration: _dialogDecoration('Type'),
                  items: const [
                    DropdownMenuItem(value: 'drink',  child: Text('Drink')),
                    DropdownMenuItem(value: 'bakery', child: Text('Bakery')),
                  ],
                  onChanged: (v) => setDlgState(() => selectedType = v ?? selectedType),
                ),
                const SizedBox(height: 14),
                const Text('Ingredients',
                    style: TextStyle(
                        color: _textDark, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _ingredientInputRow(ingCtrl, ingredients, setDlgState),
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ingredientChips(ingredients, setDlgState),
                ],
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
                Navigator.pop(ctx);
                await FirebaseFirestore.instance
                    .collection('ProductID')
                    .doc(docId)
                    .update({
                  'name':        nameCtrl.text.trim(),
                  'price':       num.tryParse(priceCtrl.text.trim()) ?? 0,
                  'description': descCtrl.text.trim(),
                  'imageURL':    uploadedUrl ?? '',
                  'type':        selectedType,
                  'ingredients': ingredients,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  //Image picker widget
  Widget _imagePicker({
    required File?   pickedImage,
    required String? existingUrl,
    required bool    uploading,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: uploading ? null : onPick,
      child: Container(
        width:  double.infinity,
        height: 120,
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
                            errorBuilder: (_, __, ___) => _imgPickerPlaceholder()),
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
                : _imgPickerPlaceholder(),
      ),
    );
  }

  Widget _imgPickerPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: _brown.withOpacity(0.6), size: 32),
          const SizedBox(height: 6),
          Text('Tap to add image', style: TextStyle(color: _textMuted, fontSize: 12)),
        ],
      );

  Widget _dialogField(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller:   ctrl,
        keyboardType: keyboardType,
        decoration:   _dialogDecoration(label),
      );

  InputDecoration _dialogDecoration(String label) => InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        _categoryTabs(),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ProductID').snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _brown));
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
                child:   _productGrid(docs),
              );
            },
          ),
        ),
      ],
    );
  }
}