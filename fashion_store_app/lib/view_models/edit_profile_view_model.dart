import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/mvvm/base_view_model.dart';

class EditProfileViewModel extends BaseViewModel {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;

  final nameController = TextEditingController(text: AppConstants.userName);
  final emailController = TextEditingController(text: AppConstants.userEmail);
  final phoneController = TextEditingController(text: '+1 234 567 890');

  Uint8List? get selectedImageBytes => _selectedImageBytes;

  Future<void> pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }
    _selectedImageBytes = await picked.readAsBytes();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
