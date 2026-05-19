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

  factory AddressItem.fromMap(Map<String, dynamic> map) {
    return AddressItem(
      title: (map['title'] ?? 'Address') as String,
      isDefault: (map['isDefault'] ?? false) as bool,
      addressLine1: (map['addressLine1'] ?? '') as String,
      addressLine2: (map['addressLine2'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDefault': isDefault,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
    };
  }
}

class UserProfileModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final List<AddressItem> addresses;

  const UserProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
    required this.addresses,
  });

  AddressItem? get defaultAddress {
    for (final address in addresses) {
      if (address.isDefault) {
        return address;
      }
    }
    return addresses.isEmpty ? null : addresses.first;
  }

  factory UserProfileModel.fromMap(String uid, Map<String, dynamic> map) {
    final rawAddresses = (map['addresses'] as List<dynamic>? ?? const []);
    return UserProfileModel(
      uid: uid,
      name: (map['name'] ?? 'User') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      profileImageUrl: (map['profileImageUrl'] ?? '') as String,
      addresses: rawAddresses
          .map((e) => AddressItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'addresses': addresses.map((e) => e.toMap()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    List<AddressItem>? addresses,
  }) {
    return UserProfileModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      addresses: addresses ?? this.addresses,
    );
  }
}
