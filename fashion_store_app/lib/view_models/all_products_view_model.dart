import 'package:flutter/material.dart';
import '../data/dummy_products.dart';
import '../models/product_model.dart';
import 'product_catalog_view_model.dart';

class AllProductsViewModel extends ProductCatalogViewModel {
  final TextEditingController minController = TextEditingController();
  final TextEditingController maxController = TextEditingController();

  List<String> get filterCategories => categories;

  void refreshFilters() {
    notifyListeners();
  }

  List<Product> get filteredProducts {
    final double? minPrice = double.tryParse(minController.text);
    final double? maxPrice = double.tryParse(maxController.text);
    final String selectedCategory = categories[selectedCategoryIndex];

    return dummyProducts.where((product) {
      if (selectedCategory != 'All' && product.category != selectedCategory) {
        return false;
      }
      if (minPrice != null && product.price < minPrice) {
        return false;
      }
      if (maxPrice != null && product.price > maxPrice) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    minController.dispose();
    maxController.dispose();
    super.dispose();
  }
}
