import '../core/mvvm/base_view_model.dart';

class ProductDetailViewModel extends BaseViewModel {
  final List<String> sizes = ['S', 'M', 'L', 'XL'];
  int _selectedSizeIndex = 3;
  bool _isFavorite = false;
  int _quantity = 1;

  int get selectedSizeIndex => _selectedSizeIndex;
  bool get isFavorite => _isFavorite;
  int get quantity => _quantity;

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
}
