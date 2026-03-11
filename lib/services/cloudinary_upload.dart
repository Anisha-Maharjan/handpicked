import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ─── Cloudinary config ────────────────────────────────────────────────────────
const String _cloudName    = 'dldztkoun';
const String _uploadPreset = 'Handpicked_user_profile';

/// Static-method service used throughout the app (e.g. stock.dart).
///
/// Usage:
///   final xfile = await CloudinaryUploadService.pickImage();
///   final url   = await CloudinaryUploadService.uploadImage(File(xfile!.path), folder: 'handpicked/ingredients');
class CloudinaryUploadService {
  CloudinaryUploadService._(); // prevent instantiation

  /// Opens the device gallery and returns the chosen [XFile], or null if
  /// the user cancelled.
  static Future<XFile?> pickImage({int imageQuality = 75}) async {
    final picker = ImagePicker();
    return picker.pickImage(
      source:       ImageSource.gallery,
      imageQuality: imageQuality,
    );
  }

  /// Uploads [file] to Cloudinary under [folder] and returns the secure URL,
  /// or null if the upload failed.
  static Future<String?> uploadImage(
    File file, {
    required String folder,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder']        = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    }
    return null;
  }
}

// ─── Convenience wrapper (kept for backwards compatibility) ───────────────────
/// Picks an image and uploads it in one call.
/// Returns the secure URL or null if cancelled / failed.
Future<String?> pickAndUploadImage({
  String folder = 'product_images',
}) async {
  final xfile = await CloudinaryUploadService.pickImage();
  if (xfile == null) return null;
  return CloudinaryUploadService.uploadImage(File(xfile.path), folder: folder);
}