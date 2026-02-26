import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ─── Cloudinary config (same as edit_profile.dart) ───────────────────────────
const String _cloudName   = 'dldztkoun';
const String _uploadPreset = 'Handpicked_user_profile';

/// Picks an image from device gallery, uploads to Cloudinary,
/// returns the secure URL or null if cancelled / failed.
Future<String?> pickAndUploadImage() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source:       ImageSource.gallery,
    imageQuality: 75,
  );
  if (picked == null) return null;

  final file = File(picked.path);
  final uri  = Uri.parse(
    'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
  );

  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = _uploadPreset
    ..fields['folder']        = 'product_images'
    ..files.add(await http.MultipartFile.fromPath('file', file.path));

  final response = await request.send();

  if (response.statusCode == 200) {
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String?;
  }
  return null;
}