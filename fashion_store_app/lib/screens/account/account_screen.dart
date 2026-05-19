import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_routes.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/mvvm/view_model_builder.dart';
import '../widgets/app_bottom_navigation_bar.dart';
import '../../view_models/account_view_model.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isUploadingImage = false;
  bool _isUpdatingProfile = false;

  Future<_ProfileData> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _ProfileData.empty();
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? <String, dynamic>{};

    return _ProfileData(
      name: (data['name'] as String?) ?? user.displayName ?? 'Guest User',
      email: (data['email'] as String?) ?? user.email ?? 'No email',
      photoUrl: (data['photoUrl'] as String?) ?? user.photoURL ?? '',
    );
  }

  Future<void> _uploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to update profile image.')),
      );
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final bytes = await file.readAsBytes();
      await _saveProfileImage(user: user, bytes: bytes, fileName: file.name);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated.')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveProfileImage({
    required User user,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${user.uid}_$fileName');

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'email': user.email,
    }, SetOptions(merge: true));

    await user.updatePhotoURL(url);
  }

  Future<void> _showEditProfileDialog(_ProfileData profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final nameController = TextEditingController(text: profile.name);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isUpdatingProfile
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name cannot be empty.'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);
                      setState(() {
                        _isUpdatingProfile = true;
                      });

                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                              'name': name,
                              'email': user.email,
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                        await user.updateDisplayName(name);

                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully.'),
                          ),
                        );
                        setState(() {});
                      } catch (e) {
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update profile: $e')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isUpdatingProfile = false;
                          });
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFF26B3A);

    return ViewModelBuilder<AccountViewModel>(
      create: (_) => AccountViewModel(),
      builder: (context, viewModel, child) {
        return FutureBuilder<_ProfileData>(
          future: _loadProfile(),
          builder: (context, snapshot) {
            final profile = snapshot.data ?? _ProfileData.empty();

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'My Account',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.settings),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              body: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor: const Color(0xFFF2F2F2),
                                    backgroundImage: profile.photoUrl.isNotEmpty
                                        ? NetworkImage(profile.photoUrl)
                                        : const AssetImage(
                                                'assets/images/profile/profile.png')
                                            as ImageProvider,
                                    child: profile.photoUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.black45,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: InkWell(
                                      onTap:
                                          _isUploadingImage ? null : _uploadProfileImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: _isUploadingImage
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.camera_alt_outlined,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.email,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _isUpdatingProfile
                                    ? null
                                    : () => _showEditProfileDialog(profile),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isUpdatingProfile
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Edit Profile'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildMenuTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'My Orders',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.myOrders),
                        ),
                        _buildMenuTile(
                          icon: Icons.location_on_outlined,
                          title: 'Shipping Address',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.shippingAddress,
                          ),
                        ),
                        _buildMenuTile(
                          icon: Icons.help_outline,
                          title: 'Help Center',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.helpCenter),
                        ),
                        _buildMenuTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: () => _showLogoutDialog(context),
                          accentColor: accentColor,
                        ),
                      ],
                    ),
              bottomNavigationBar: _buildBottomNav(context),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE9E2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.logout, color: Color(0xFFF26B3A)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF26B3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color accentColor = const Color(0xFFF26B3A),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: accentColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return AppBottomNavigationBar(
      currentIndex: 3,
      onTap: (index) {
        AppNavigator.switchBottomTab(context, index);
      },
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  factory _ProfileData.empty() {
    return const _ProfileData(
      name: 'Guest User',
      email: 'No email',
      photoUrl: '',
    );
  }

  final String name;
  final String email;
  final String photoUrl;
}
