import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  FirebaseStorageService._();

  static final FirebaseStorageService instance = FirebaseStorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImageBytes({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref().child('users').child(uid).child('profile.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
