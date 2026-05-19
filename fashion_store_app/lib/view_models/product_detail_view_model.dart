import '../core/mvvm/base_view_model.dart';

class ProductDetailViewModel extends BaseViewModel {
  final List<String> sizes = ['S', 'M', 'L', 'XL'];
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
}
