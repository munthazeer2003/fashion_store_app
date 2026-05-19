import '../core/constants.dart';
import '../core/mvvm/base_view_model.dart';

class CheckoutViewModel extends BaseViewModel {
  String get shippingTitle => 'Home';
  String get shippingSubtitle => '123 Main Street, Apt 4B\nNew York, NY 10001';

  String get paymentTitle => 'Visa ending in 4242';
  String get paymentSubtitle => 'Expires 12/24';

  String get subtotal => '${AppConstants.currency} 599.94';
  String get shipping => '${AppConstants.currency} 10.00';
  String get tax => '${AppConstants.currency} 52.49';
  String get total => '${AppConstants.currency} 662.43';
}
