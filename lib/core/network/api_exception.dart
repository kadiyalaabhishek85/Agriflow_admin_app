/// Shared interface for every feature-specific API exception hierarchy
/// (flutter-03 rec 6: one shared exception type across features).
///
/// Feature hierarchies (`FarmerException`, `GrainSaleException`,
/// `FarmVisitException`, `BookingException`, ...) `implements` this type, so
/// generic layers (error sanitizers, logging) can handle any API failure
/// through one contract while feature code keeps catching its typed subclass.
abstract class AppApiException implements Exception {
  /// User-facing message (already sanitized by the throwing layer).
  String get message;

  /// HTTP status code when a response was received, `0` for transport-level
  /// failures, `null` when unknown.
  int? get statusCode;

  /// True when the failure is a network/transport problem rather than an
  /// API error response.
  bool get isNetworkError;
}
