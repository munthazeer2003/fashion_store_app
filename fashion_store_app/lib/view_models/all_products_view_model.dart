import 'package:flutter/material.dart';

import '../models/product_model.dart';
import 'product_catalog_view_model.dart';

class AllProductsViewModel extends ProductCatalogViewModel {
  final TextEditingController minController = TextEditingController();
  final TextEditingController maxController = TextEditingController();

  List<String> get filterCategories => categories;

  @override
  List<Product> get filteredProducts {
    final base = super.filteredProducts;
    final double? minPrice = double.tryParse(minController.text);
    final double? maxPrice = double.tryParse(maxController.text);

    return base.where((product) {
      if (minPrice != null && product.price < minPrice) {
        return false;
      }
      if (maxPrice != null && product.price > maxPrice) {
        return false;
      }
      return true;
    }).toList();
  }

  void refreshFilters() {
    notifyListeners();
  }

  @override
  void dispose() {
    minController.dispose();
    maxController.dispose();
    super.dispose();
  }
}
