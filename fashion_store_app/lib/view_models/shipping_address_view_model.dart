import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/mvvm/base_view_model.dart';
import '../models/user_profile_model.dart';
import '../services/firestore_service.dart';

class ShippingAddressViewModel extends BaseViewModel {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<AddressItem> _addresses = [];
  StreamSubscription<UserProfileModel?>? _sub;

  ShippingAddressViewModel() {
    _listenProfile();
  }

  List<AddressItem> get addresses => List.unmodifiable(_addresses);

  Future<void> addAddress(AddressItem item) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }
    final list = List<AddressItem>.from(_addresses)..add(item);
    await _saveAddresses(uid, list);
  }

  Future<void> updateAddress(int index, AddressItem item) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || index < 0 || index >= _addresses.length) {
      return;
    }
    final list = List<AddressItem>.from(_addresses);
    list[index] = item;
    await _saveAddresses(uid, list);
  }

  Future<void> removeAddress(int index) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || index < 0 || index >= _addresses.length) {
      return;
    }
    final list = List<AddressItem>.from(_addresses)..removeAt(index);
    await _saveAddresses(uid, list);
  }

  Future<void> _saveAddresses(String uid, List<AddressItem> addresses) async {
    final existing = await _firestoreService.streamUserProfile(uid).first;
    if (existing == null) {
      return;
    }
    await _firestoreService.updateUserProfile(profile: existing.copyWith(addresses: addresses));
  }

  void _listenProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }
    _sub?.cancel();
    _sub = _firestoreService.streamUserProfile(uid).listen((profile) {
      _addresses = profile?.addresses ?? [];
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
