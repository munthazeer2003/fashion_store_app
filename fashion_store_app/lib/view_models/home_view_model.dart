import '../models/product_model.dart';
import 'product_catalog_view_model.dart';

class HomeViewModel extends ProductCatalogViewModel {
  List<Product> get popularProducts => filteredProducts.where((item) => item.isPopular).toList();

  List<Product> get newArrivals => filteredProducts.where((item) => item.isNewArrival).toList();
}
