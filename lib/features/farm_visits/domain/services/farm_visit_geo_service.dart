import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/app_dates.dart';

/// Structured GPS fix metadata for Farm Visits
class FarmGpsCoordinates {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  const FarmGpsCoordinates({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  String get formattedLat => latitude.toStringAsFixed(6);
  String get formattedLng => longitude.toStringAsFixed(6);
  String get formattedAccuracy =>
      accuracy != null ? '±${accuracy!.toStringAsFixed(0)}m' : '';

  String get displayCoords =>
      '$formattedLat, $formattedLng${accuracy != null ? ' (±${accuracy!.toStringAsFixed(0)}m)' : ''}';
}

/// Service handling GPS coordinate resolution, geofence validation,
/// and image geolocation stamping for field visit photos.
class FarmVisitGeoService {
  final Future<Position> Function({LocationSettings? locationSettings})?
      getCurrentPosition;
  final Future<bool> Function()? isLocationServiceEnabled;
  final Future<LocationPermission> Function()? checkPermission;
  final Future<LocationPermission> Function()? requestPermission;

  const FarmVisitGeoService({
    this.getCurrentPosition,
    this.isLocationServiceEnabled,
    this.checkPermission,
    this.requestPermission,
  });

  /// Obtains the current device GPS coordinates with high accuracy.
  Future<({FarmGpsCoordinates? coords, String? error})>
      getCurrentGpsLocation() async {
    try {
      final serviceEnabled = isLocationServiceEnabled != null
          ? await isLocationServiceEnabled!()
          : await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return (
          coords: null,
          error:
              'Location services are disabled. Please turn on GPS in device settings.',
        );
      }

      var permission = checkPermission != null
          ? await checkPermission!()
          : await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = requestPermission != null
            ? await requestPermission!()
            : await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          return (
            coords: null,
            error:
                'Location permission was denied. GPS is required to tag the field photo.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return (
          coords: null,
          error:
              'Location permission is permanently denied. Please grant location access in App Settings.',
        );
      }

      final position = getCurrentPosition != null
          ? await getCurrentPosition!(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 12),
              ),
            )
          : await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 12),
              ),
            );

      // Verify coordinate sanity
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        return (
          coords: null,
          error: 'Invalid GPS fix (0.0, 0.0). Please wait for a solid satellite fix.',
        );
      }

      return (
        coords: FarmGpsCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ),
        error: null,
      );
    } catch (e) {
      return (
        coords: null,
        error:
            'Could not acquire GPS position. Please ensure location is enabled and try again.',
      );
    }
  }

  /// Validates distance between current position and target farm location.
  /// Standard geofence threshold is 500 metres (0.5 km).
  ({bool isInside, double distanceMeters}) validateGeofence({
    required double currentLat,
    required double currentLng,
    required double farmLat,
    required double farmLng,
    double radiusMeters = 500.0,
  }) {
    final distance = Geolocator.distanceBetween(
      currentLat,
      currentLng,
      farmLat,
      farmLng,
    );
    return (
      isInside: distance <= radiusMeters,
      distanceMeters: distance,
    );
  }

  /// Stamps GPS metadata onto the image canvas as a visible high-contrast watermark banner.
  Future<List<int>> stampImageWithGps({
    required List<int> imageBytes,
    required FarmGpsCoordinates coords,
    String? farmName,
    String? locationAddress,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(imageBytes));
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final w = image.width.toDouble();
      final h = image.height.toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

      // Draw original photo
      canvas.drawImage(image, Offset.zero, Paint());

      // Scaled responsive typography based on image dimensions
      final fontSize = (w * 0.024).clamp(16.0, 42.0);
      final pad = fontSize * 0.6;
      final lineSpacing = fontSize * 0.25;

      final lines = <String>[
        'Lat: ${coords.formattedLat}  Lng: ${coords.formattedLng}${coords.formattedAccuracy.isNotEmpty ? ' (${coords.formattedAccuracy})' : ''}',
        if (farmName != null && farmName.isNotEmpty) 'Farm: $farmName',
        if (locationAddress != null && locationAddress.isNotEmpty) 'Location: $locationAddress',
        'Captured: ${AppDates.dayMonthYear(coords.timestamp.toIso8601String().split('T')[0])} ${coords.timestamp.hour.toString().padLeft(2, '0')}:${coords.timestamp.minute.toString().padLeft(2, '0')}',
      ];

      final totalTextHeight =
          lines.length * fontSize + (lines.length - 1) * lineSpacing;
      final boxHeight = totalTextHeight + pad * 2.2;

      // Dark semi-translucent overlay background banner
      final bgPaint = Paint()..color = const Color(0xB8000000);
      canvas.drawRect(Rect.fromLTWH(0, h - boxHeight, w, boxHeight), bgPaint);

      // Render text lines
      var currentY = h - boxHeight + pad;
      for (final line in lines) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: line,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: w - pad * 2);
        textPainter.paint(canvas, Offset(pad, currentY));
        currentY += fontSize + lineSpacing;
      }

      final picture = recorder.endRecording();
      final stampedImage = await picture.toImage(w.toInt(), h.toInt());
      final byteData =
          await stampedImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData != null ? byteData.buffer.asUint8List() : imageBytes;
    } catch (_) {
      // Fallback safely to original bytes if canvas rendering fails
      return imageBytes;
    }
  }
}
