import 'package:flutter/material.dart';

class FavouriteItem {
  final String docId;
  final String name;
  final num price;
  final String? imageUrl;
  final String category; // 'drink' or 'bakery'

  const FavouriteItem({
    required this.docId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
        'docId': docId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
      };
}

class FavouritesProvider extends ChangeNotifier {
  final List<FavouriteItem> _items = [];

  List<FavouriteItem> get items => List.unmodifiable(_items);

  bool isFavourite(String docId) => _items.any((i) => i.docId == docId);

  void toggle(FavouriteItem item) {
    final idx = _items.indexWhere((i) => i.docId == item.docId);
    if (idx >= 0) {
      _items.removeAt(idx);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void remove(String docId) {
    _items.removeWhere((i) => i.docId == docId);
    notifyListeners();
  }
}

// InheritedWidget wrapper so it works without any extra packages
class FavouritesProviderWidget extends StatefulWidget {
  final Widget child;

  const FavouritesProviderWidget({super.key, required this.child});

  static FavouritesProvider of(BuildContext context) {
    final _FavouritesProviderInherited? inherited = context
        .dependOnInheritedWidgetOfExactType<_FavouritesProviderInherited>();
    assert(inherited != null, 'No FavouritesProviderWidget found in context');
    return inherited!.provider;
  }

  @override
  State<FavouritesProviderWidget> createState() =>
      _FavouritesProviderWidgetState();
}

class _FavouritesProviderWidgetState extends State<FavouritesProviderWidget> {
  final FavouritesProvider _provider = FavouritesProvider();

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _provider.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FavouritesProviderInherited(
        provider: _provider,
        child: widget.child,
      );
}

class _FavouritesProviderInherited extends InheritedWidget {
  final FavouritesProvider provider;

  const _FavouritesProviderInherited({
    required this.provider,
    required super.child,
  });

  @override
  bool updateShouldNotify(_FavouritesProviderInherited old) => true;
}