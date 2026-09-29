import '../entities/farm_visit_item.dart';
import '../entities/farm_visit_pagination.dart';

abstract class FarmVisitRepository {
  /// Fetch a paginated list of farm visits with optional search and status filtering
  Future<({List<FarmVisitItem> items, FarmVisitPagination pagination})> getVisits({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  });

  /// Schedule / reschedule visit date or assign staff
  Future<FarmVisitItem> scheduleVisit({
    required String accessToken,
    required String visitId,
    String? scheduledDate,
    String? staffId,
  });

  /// Complete a farm visit with verified acres and report notes
  Future<FarmVisitItem> completeVisit({
    required String accessToken,
    required String visitId,
    required String verifiedAcres,
    required String report,
    String? diagnosis,
    String? recommendation,
  });

  /// Create a new farm visit for a crop
  Future<FarmVisitItem> createVisit({
    required String accessToken,
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  });

  /// Send visit reminders via POST /farm-visits/reminders?days_ahead=N
  Future<String> sendVisitReminders({
    required String accessToken,
    int daysAhead = 2,
  });

  /// Crop lookup for the schedule-visit form
  Future<Map<String, ({String cropType, String acres})>> getCropOptions({
    required String accessToken,
  });

  /// Staff (manager) lookup for optional visit assignment
  Future<Map<String, ({String name, String phone})>> getStaffOptions({
    required String accessToken,
  });

  /// Upload field photo captured via camera/gallery for the visit
  Future<String> uploadVisitPhoto({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  });
}
