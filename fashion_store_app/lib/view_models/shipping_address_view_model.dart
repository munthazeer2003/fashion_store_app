import '../core/mvvm/base_view_model.dart';

class ShippingAddressViewModel extends BaseViewModel {
  final List<AddressItem> _addresses = [
    const AddressItem(
      title: 'Home',
      isDefault: true,
      addressLine1: '123 Main Street, Apt 4B',
      addressLine2: 'New York, NY 10001',
    ),
    const AddressItem(
      title: 'Office',
      isDefault: false,
      addressLine1: '800 Market Street, Suite 200',
      addressLine2: 'San Francisco, CA 94103',
    ),
  ];

  List<AddressItem> get addresses => List.unmodifiable(_addresses);

  void addAddress(AddressItem item) {
    _addresses.add(item);
    notifyListeners();
  }

  void updateAddress(int index, AddressItem item) {
    _addresses[index] = item;
    notifyListeners();
  }

  void removeAddress(int index) {
    _addresses.removeAt(index);
    notifyListeners();
  }
}

class AddressItem {
  final String title;
  final bool isDefault;
  final String addressLine1;
  final String addressLine2;

  const AddressItem({
    required this.title,
    required this.isDefault,
    required this.addressLine1,
    required this.addressLine2,
  });
}
