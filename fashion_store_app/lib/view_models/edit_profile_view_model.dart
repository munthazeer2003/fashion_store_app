import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/mvvm/base_view_model.dart';
import '../models/user_profile_model.dart';
import '../services/firebase_storage_service.dart';
import '../services/firestore_service.dart';

class EditProfileViewModel extends BaseViewModel {
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Uint8List? _selectedImageBytes;
  String _profileImageUrl = '';
  StreamSubscription<UserProfileModel?>? _profileSub;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  EditProfileViewModel() {
    _listenProfile();
  }

  Uint8List? get selectedImageBytes => _selectedImageBytes;
  String get profileImageUrl => _profileImageUrl;
  bool get hasNetworkProfileImage => profileImageUrl.startsWith('http://') || profileImageUrl.startsWith('https://');

  Future<void> pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) {
      return;
    }
    _selectedImageBytes = await picked.readAsBytes();
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      setError('Please login to update your profile.');
      return false;
    }

    try {
      setBusy(true);
      var imageUrl = _profileImageUrl;
      if (_selectedImageBytes != null) {
        imageUrl = await _storageService.uploadProfileImageBytes(
          uid: user.uid,
          bytes: _selectedImageBytes!,
        );
      }

      final existing = await _firestoreService.streamUserProfile(user.uid).first;
      final profile = (existing ??
              UserProfileModel(
                uid: user.uid,
                name: '',
                email: user.email ?? '',
                phone: '',
                profileImageUrl: '',
                addresses: const [],
              ))
          .copyWith(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        profileImageUrl: imageUrl,
      );

      await _firestoreService.updateUserProfile(profile: profile);
      _selectedImageBytes = null;
      return true;
    } catch (error) {
      setError(error.toString());
      return false;
    } finally {
      setBusy(false);
    }
  }

  void _listenProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    _profileSub?.cancel();
    _profileSub = _firestoreService.streamUserProfile(uid).listen((profile) {
      if (profile == null) {
        return;
      }
      _profileImageUrl = profile.profileImageUrl;
      if (nameController.text.isEmpty) {
        nameController.text = profile.name;
      }
      if (emailController.text.isEmpty) {
        emailController.text = profile.email;
      }
      if (phoneController.text.isEmpty) {
        phoneController.text = profile.phone;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
