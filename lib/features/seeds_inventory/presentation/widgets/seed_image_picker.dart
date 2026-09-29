import 'package:image_picker/image_picker.dart';

/// Resolves the MIME type for a picked image file.
///
/// Prefers the type declared by the picker when it is usable, otherwise
/// falls back to the file extension, then to `image/jpeg`.
String resolveSeedImageMimeType(String fileName, [String? declaredType]) {
  final declared = declaredType?.trim();
  if (declared != null &&
      declared.isNotEmpty &&
      declared != 'application/octet-stream') {
    return declared;
  }
  final dot = fileName.lastIndexOf('.');
  final extension =
      dot >= 0 && dot < fileName.length - 1 ? fileName.substring(dot + 1).toLowerCase() : '';
  switch (extension) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'heic':
      return 'image/heic';
    case 'heif':
      return 'image/heif';
    case 'bmp':
      return 'image/bmp';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    default:
      return 'image/jpeg';
  }
}

/// A user-selected image, ready for multipart upload.
class SeedPickedImage {
  final List<int> bytes;
  final String fileName;
  final String mimeType;

  const SeedPickedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}

typedef SeedImagePickFn = Future<SeedPickedImage?> Function();

/// Gallery image picker for the Seed Inventory upload flow.
///
/// The underlying selection function is injectable so widget tests can
/// supply a controlled double instead of a platform channel.
class SeedImagePicker {
  SeedImagePicker({SeedImagePickFn? pick}) : _pick = pick ?? _pickFromGallery;

  final SeedImagePickFn _pick;

  /// Opens the device gallery. Returns `null` when the user cancels.
  Future<SeedPickedImage?> pickImage() => _pick();

  static Future<SeedPickedImage?> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return SeedPickedImage(
      bytes: bytes,
      fileName: file.name,
      mimeType: resolveSeedImageMimeType(file.name, file.mimeType),
    );
  }
}
