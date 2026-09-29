import 'package:agriflow_admin/core/utils/app_initials.dart';

/// Represents a single Farm Visit item with strict separation between
/// backend-native fields (`FarmVisitPublic`) and enriched display fields.
class FarmVisitItem {
  // -------------------------------------------------------------
  // Backend-Native Fields (strictly matching FarmVisitPublic schema)
  // -------------------------------------------------------------
  final String id;
  final String cropId;
  final String farmerId;
  final String? staffId;
  final int visitMonth;
  final String? scheduledDate; // YYYY-MM-DD
  final String? actualDate;    // YYYY-MM-DD
  final String status;         // scheduled | pending_review | completed | cancelled
  final String? verifiedAcres;
  final String? report;

  // -------------------------------------------------------------
  // Enriched Display Fields (resolved via relationship lookups)
  // -------------------------------------------------------------
  final String? enrichedFarmerName;
  final String? enrichedFarmerPhone;
  final String? enrichedFarmerVillage;
  final String? enrichedCropName;
  final String? enrichedCropAcres;
  final String? enrichedStaffName;

  const FarmVisitItem({
    required this.id,
    required this.cropId,
    required this.farmerId,
    this.staffId,
    required this.visitMonth,
    this.scheduledDate,
    this.actualDate,
    required this.status,
    this.verifiedAcres,
    this.report,
    this.enrichedFarmerName,
    this.enrichedFarmerPhone,
    this.enrichedFarmerVillage,
    this.enrichedCropName,
    this.enrichedCropAcres,
    this.enrichedStaffName,
  });

  /// Factory strictly parsing backend JSON
  factory FarmVisitItem.fromJson(Map<String, dynamic> json) {
    return FarmVisitItem(
      id: (json['id'] ?? '').toString(),
      cropId: (json['crop_id'] ?? '').toString(),
      farmerId: (json['farmer_id'] ?? '').toString(),
      staffId: json['staff_id']?.toString(),
      visitMonth: json['visit_month'] is num
          ? (json['visit_month'] as num).toInt()
          : int.tryParse(json['visit_month']?.toString() ?? '1') ?? 1,
      scheduledDate: json['scheduled_date']?.toString(),
      actualDate: json['actual_date']?.toString(),
      status: (json['status'] ?? 'scheduled').toString().toLowerCase(),
      verifiedAcres: json['verified_acres']?.toString(),
      report: json['report']?.toString(),
    );
  }

  /// Create a copy with enriched display metadata
  FarmVisitItem copyWithEnrichment({
    String? farmerName,
    String? farmerPhone,
    String? farmerVillage,
    String? cropName,
    String? cropAcres,
    String? staffName,
  }) {
    return FarmVisitItem(
      id: id,
      cropId: cropId,
      farmerId: farmerId,
      staffId: staffId,
      visitMonth: visitMonth,
      scheduledDate: scheduledDate,
      actualDate: actualDate,
      status: status,
      verifiedAcres: verifiedAcres,
      report: report,
      enrichedFarmerName: farmerName ?? enrichedFarmerName,
      enrichedFarmerPhone: farmerPhone ?? enrichedFarmerPhone,
      enrichedFarmerVillage: farmerVillage ?? enrichedFarmerVillage,
      enrichedCropName: cropName ?? enrichedCropName,
      enrichedCropAcres: cropAcres ?? enrichedCropAcres,
      enrichedStaffName: staffName ?? enrichedStaffName,
    );
  }

  /// Display farmer name with fallback to short ID
  String get displayFarmerName {
    if (enrichedFarmerName != null && enrichedFarmerName!.trim().isNotEmpty) {
      return enrichedFarmerName!;
    }
    final shortId = farmerId.length > 8 ? farmerId.substring(0, 8) : farmerId;
    return 'Farmer #$shortId';
  }

  /// Display crop name with fallback
  String get displayCropName {
    if (enrichedCropName != null && enrichedCropName!.trim().isNotEmpty) {
      return enrichedCropName!;
    }
    final shortId = cropId.length > 8 ? cropId.substring(0, 8) : cropId;
    return 'Crop #$shortId';
  }

  /// Display officer/staff name with fallback
  String get displayStaffName {
    if (enrichedStaffName != null && enrichedStaffName!.trim().isNotEmpty) {
      return enrichedStaffName!;
    }
    return staffId != null && staffId!.isNotEmpty ? 'Officer Assigned' : 'Unassigned';
  }

  /// Display location/village with fallback
  String get displayVillage {
    if (enrichedFarmerVillage != null && enrichedFarmerVillage!.trim().isNotEmpty) {
      return enrichedFarmerVillage!;
    }
    return 'Main Village';
  }

  /// Farmers initials for avatar
  String get farmerInitials => AppInitials.of(enrichedFarmerName);

  /// Whether this visit is currently editable (scheduled or pending_review)
  bool get isEditable => status == 'scheduled' || status == 'pending_review';

  /// Whether this visit is completed
  bool get isCompleted => status == 'completed';

  /// Whether this visit is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Extracts the field photo URL from report string if present
  String? get fieldPhotoUrl {
    if (report == null || report!.trim().isEmpty) return null;
    final photoRegex = RegExp(r'\[Field Photo\]:\s*(https?://[^\s]+)', caseSensitive: false);
    final match = photoRegex.firstMatch(report!);
    if (match != null) {
      return match.group(1)?.trim();
    }
    // Direct standalone URL check
    final standaloneUrlRegex = RegExp(r'^https?://[^\s]+$', caseSensitive: false);
    if (standaloneUrlRegex.hasMatch(report!.trim())) {
      return report!.trim();
    }
    return null;
  }

  /// Cleaned report text excluding the internal [Field Photo]: ... marker
  String? get cleanReportNotes {
    if (report == null || report!.trim().isEmpty) return null;
    final photoRegex = RegExp(r'\[Field Photo\]:\s*https?://[^\s]+', caseSensitive: false);
    final cleaned = report!.replaceAll(photoRegex, '').trim();
    if (cleaned.isEmpty) return null;
    final standaloneUrlRegex = RegExp(r'^https?://[^\s]+$', caseSensitive: false);
    if (standaloneUrlRegex.hasMatch(cleaned)) return null;
    return cleaned;
  }
}
