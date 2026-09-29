import 'package:image_picker/image_picker.dart';
import '../../domain/services/farm_visit_geo_service.dart';

/// Resolves MIME type for a picked visit photo.
String resolveVisitPhotoMimeType(String fileName, [String? declaredType]) {
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
    default:
      return 'image/jpeg';
  }
}

/// A captured camera photo for farm visits, ready for upload.
class VisitPickedPhoto {
  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final DateTime capturedAt;
  final FarmGpsCoordinates? gpsCoordinates;

  VisitPickedPhoto({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    DateTime? capturedAt,
    this.gpsCoordinates,
  }) : capturedAt = capturedAt ?? DateTime.now();

  double get sizeInKb => bytes.length / 1024.0;
  double get sizeInMb => bytes.length / (1024.0 * 1024.0);
  String get displaySize => sizeInMb >= 1.0
      ? '${sizeInMb.toStringAsFixed(1)} MB'
      : '${sizeInKb.toStringAsFixed(0)} KB';
}

typedef VisitCameraPickFn = Future<VisitPickedPhoto?> Function({
  required ImageSource source,
  FarmGpsCoordinates? gpsCoordinates,
  String? farmName,
  String? farmAddress,
});

/// Device camera picker for Farm Visits field photo capture with geotagging.
///
/// Injectable for testing without physical camera hardware.
class VisitCameraPicker {
  final VisitCameraPickFn _pickFn;
  final FarmVisitGeoService geoService;

  VisitCameraPicker({
    VisitCameraPickFn? pickFn,
    FarmVisitGeoService? geoService,
  })  : _pickFn = pickFn ?? _defaultPickFromCamera,
        geoService = geoService ?? const FarmVisitGeoService();

  /// Captures photo using the device camera with GPS stamping.
  Future<VisitPickedPhoto?> captureFromCamera({
    FarmGpsCoordinates? gpsCoordinates,
    String? farmName,
    String? farmAddress,
  }) =>
      _pickFn(
        source: ImageSource.camera,
        gpsCoordinates: gpsCoordinates,
        farmName: farmName,
        farmAddress: farmAddress,
      );

  /// Selects photo from device gallery with GPS stamping.
  Future<VisitPickedPhoto?> pickFromGallery({
    FarmGpsCoordinates? gpsCoordinates,
    String? farmName,
    String? farmAddress,
  }) =>
      _pickFn(
        source: ImageSource.gallery,
        gpsCoordinates: gpsCoordinates,
        farmName: farmName,
        farmAddress: farmAddress,
      );

  static Future<VisitPickedPhoto?> _defaultPickFromCamera({
    required ImageSource source,
    FarmGpsCoordinates? gpsCoordinates,
    String? farmName,
    String? farmAddress,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file == null) return null;

    List<int> bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty
        ? file.name
        : 'field_visit_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // If GPS coordinates were captured, stamp the photo with GPS watermark
    if (gpsCoordinates != null) {
      const geo = FarmVisitGeoService();
      bytes = await geo.stampImageWithGps(
        imageBytes: bytes,
        coords: gpsCoordinates,
        farmName: farmName,
        locationAddress: farmAddress,
      );
    }

    return VisitPickedPhoto(
      bytes: bytes,
      fileName: name,
      mimeType: resolveVisitPhotoMimeType(name, file.mimeType),
      gpsCoordinates: gpsCoordinates,
    );
  }
}
