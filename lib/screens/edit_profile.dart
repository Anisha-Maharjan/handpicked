import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color _brown = Color(0xFF834D1E);
  static const Color _muted = Color(0xFF7A7A7A);

  //Cloudinary config 
  static const String _cloudinaryCloudName = 'dldztkoun';
  static const String _cloudinaryUploadPreset = 'Handpicked_user_profile'; // unsigned preset
  // 

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _contact = TextEditingController();

  String? _photoUrl;
  File? _pickedImageFile;

  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      _firstName.text = (data['firstName'] ?? '').toString();
      _lastName.text = (data['lastName'] ?? '').toString();
      _email.text = (data['email'] ?? user.email ?? '').toString();
      _contact.text = (data['contact'] ?? data['phone'] ?? '').toString();

      final rawUrl = (data['photoUrl'] ?? '').toString();
      _photoUrl = rawUrl.isEmpty ? null : rawUrl;
    } catch (_) {
      _email.text = _user?.email ?? '';
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Picks an image from the device gallery.
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    setState(() {
      _pickedImageFile = File(picked.path);
    });

    if (!_editing) {
      await _saveProfile();
    }
  }

  /// Uploads the picked image to Cloudinary and returns the secure URL.
  Future<String?> _uploadToCloudinary() async {
    if (_pickedImageFile == null) return null;

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['folder'] = 'profile_pictures'
      ..files.add(
        await http.MultipartFile.fromPath('file', _pickedImageFile!.path),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    } else {
      final error = await response.stream.bytesToString();
      throw Exception('Cloudinary upload failed: $error');
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      if (_pickedImageFile != null) {
        final url = await _uploadToCloudinary();
        if (url != null) {
          _photoUrl = url;
          _pickedImageFile = null;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'email': _email.text.trim(),
          'contact': _contact.text.trim(),
          'photoUrl': _photoUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully.")),
      );

      setState(() => _editing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _lineField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _brown,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(
              color: enabled ? Colors.black87 : _muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Container(height: 1, color: _brown.withOpacity(0.45)),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;

    if (_pickedImageFile != null) {
      imageProvider = FileImage(_pickedImageFile!);
    } else if (_photoUrl != null) {
      imageProvider = NetworkImage(_photoUrl!);
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _brown.withOpacity(0.35), width: 2),
                ),
                child: ClipOval(
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                        )
                      : _avatarPlaceholder(),
                ),
              ),
              if (_editing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _brown,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _editing ? _pickImageFromGallery : null,
            child: Text(
              "Change profile picture",
              style: TextStyle(
                color: _editing ? _brown : _muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 46, color: _brown),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: _brown,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Profile",
                        style: TextStyle(
                          color: _brown,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                if (!_editing) {
                                  setState(() => _editing = true);
                                  return;
                                }
                                await _saveProfile();
                              },
                        child: Text(
                          _editing ? "Save" : "Edit",
                          style: const TextStyle(
                            color: _brown,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _buildAvatar(),

                  const SizedBox(height: 22),

                  _lineField(label: "First Name", controller: _firstName, enabled: _editing),
                  _lineField(label: "Last Name", controller: _lastName, enabled: _editing),
                  _lineField(
                    label: "Email Address",
                    controller: _email,
                    enabled: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _lineField(
                    label: "Contact Address",
                    controller: _contact,
                    enabled: _editing,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),

        if (_saving)
          Container(
            color: Colors.black.withOpacity(0.18),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}