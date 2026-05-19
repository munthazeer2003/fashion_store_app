import '../core/mvvm/base_view_model.dart';
import '../models/product_model.dart';
import 'cart_view_model.dart';

class ProductDetailViewModel extends BaseViewModel {
  final List<String> sizes = ['S', 'M', 'L', 'XL'];
  final CartViewModel _cartViewModel = CartViewModel();

  int _selectedSizeIndex = 3;
  bool _isFavorite = false;

  int get selectedSizeIndex => _selectedSizeIndex;
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

  Future<bool> addToCart(Product product) {
    return _cartViewModel.addProduct(product);
  }

  @override
  void dispose() {
    _cartViewModel.dispose();
    super.dispose();
  }
}
