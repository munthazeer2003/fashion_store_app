import '../core/mvvm/base_view_model.dart';

class WishlistViewModel extends BaseViewModel {
  final List<WishlistItem> _items = [
    const WishlistItem(
      name: 'Puma Shoes',
      category: 'Footwear',
      price: 99.0,
      image: 'assets/images/products/shoes/shoe_5.jpg',
    ),
  ];

  List<WishlistItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }
}

class WishlistItem {
  final String name;
  final String category;
  final double price;
  final String image;

  const WishlistItem({
    required this.name,
    required this.category,
    required this.price,
    required this.image,
  });
}
