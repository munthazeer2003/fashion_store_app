import '../models/product_model.dart';
import 'product_catalog_view_model.dart';

class HomeViewModel extends ProductCatalogViewModel {
  List<Product> get popularProducts => products.where((item) => item.isPopular).toList();

  List<Product> get newArrivals => products.where((item) => item.isNewArrival).toList();
}
