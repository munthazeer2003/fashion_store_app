import '../core/mvvm/base_view_model.dart';

class CartViewModel extends BaseViewModel {
  final List<CartItem> _items = [
    CartItem(
      name: 'Shoes',
      price: 69.0,
      image: 'assets/images/products/shoes/shoe_1.jpg',
    ),
    CartItem(
      name: 'Laptop',
      price: 69.0,
      image: 'assets/images/products/women/women_dress_1.jpg',
    ),
    CartItem(
      name: 'Jordan Shoes',
      price: 69.0,
      image: 'assets/images/products/shoes/shoe_2.jpg',
    ),
    CartItem(
      name: 'Puma',
      price: 69.0,
      image: 'assets/images/products/shoes/shoe_3.jpg',
    ),
  ];

  List<CartItem> get items => List.unmodifiable(_items);

  double get total {
    double total = 0;
    for (final item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void increment(int index) {
    _items[index].quantity += 1;
    notifyListeners();
  }

  void decrement(int index) {
    if (_items[index].quantity == 1) {
      return;
    }
    _items[index].quantity -= 1;
    notifyListeners();
  }
}

class CartItem {
  CartItem({
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  final String name;
  final double price;
  final String image;
  int quantity;
}
