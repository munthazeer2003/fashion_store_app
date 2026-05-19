import 'dart:async';

import '../core/mvvm/base_view_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class ProductCatalogViewModel extends BaseViewModel {
  final FirestoreService _firestoreService = FirestoreService.instance;

  final List<String> _categories = ['All'];
  List<Product> _products = [];
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<CategoryModel>>? _categoriesSub;

  ProductCatalogViewModel() {
    _listenProducts();
    _listenCategories();
  }

  int get selectedCategoryIndex => _selectedCategoryIndex;
  List<String> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  String get searchQuery => _searchQuery;

  List<Product> get filteredProducts {
    final String selectedCategory = _categories[_selectedCategoryIndex];
    return _products.where((product) {
      final matchesCategory = selectedCategory == 'All' || product.category == selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void selectCategory(int index) {
    if (_selectedCategoryIndex == index) {
      return;
    }
    _selectedCategoryIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    notifyListeners();
  }

  void _listenProducts() {
    setBusy(true);
    _productsSub?.cancel();
    _productsSub = _firestoreService.streamProducts().listen(
      (items) {
        _products = items;
        setBusy(false);
      },
      onError: (error) {
        setBusy(false);
        setError(error.toString());
      },
    );
  }

  void _listenCategories() {
    _categoriesSub?.cancel();
    _categoriesSub = _firestoreService.streamCategories().listen((items) {
      final names = ['All', ...items.map((e) => e.name)];
      _categories
        ..clear()
        ..addAll(names);
      if (_selectedCategoryIndex >= _categories.length) {
        _selectedCategoryIndex = 0;
      }
      notifyListeners();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
