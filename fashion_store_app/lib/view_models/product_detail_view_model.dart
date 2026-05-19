import '../core/mvvm/base_view_model.dart';
import '../models/product_model.dart';
import 'cart_view_model.dart';

class ProductDetailViewModel extends BaseViewModel {
  final List<String> sizes = ['S', 'M', 'L', 'XL'];
  final CartViewModel _cartViewModel = CartViewModel();

  int _selectedSizeIndex = 3;
  int _quantity = 1;
  bool _isFavorite = false;

  int get selectedSizeIndex => _selectedSizeIndex;
  int get quantity => _quantity;
  bool get isFavorite => _isFavorite;

  void selectSize(int index) {
    if (_selectedSizeIndex == index) {
      return;
    }
    _selectedSizeIndex = index;
    notifyListeners();
  }

  void toggleFavorite() {
    _isFavorite = !_isFavorite;
    notifyListeners();
  }

  void incrementQuantity() {
    if (_quantity >= 99) {
      return;
    }
    _quantity += 1;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_quantity <= 1) {
      return;
    }
    _quantity -= 1;
    notifyListeners();
  }

  Future<bool> addToCart(Product product) async {
    clearError();
    final added = await _cartViewModel.addProduct(product, quantity: _quantity);
    if (!added && _cartViewModel.errorMessage != null) {
      setError(_cartViewModel.errorMessage);
    }
    return added;
  }

  @override
  void dispose() {
    _cartViewModel.dispose();
    super.dispose();
  }
}
