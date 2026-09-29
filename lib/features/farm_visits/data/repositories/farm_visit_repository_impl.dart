import '../datasources/farm_visit_remote_data_source.dart';
import '../../domain/entities/farm_visit_item.dart';
import '../../domain/entities/farm_visit_pagination.dart';
import '../../domain/repositories/farm_visit_repository.dart';

class FarmVisitRepositoryImpl implements FarmVisitRepository {
  final FarmVisitRemoteDataSource remoteDataSource;

  // In-memory cache for relationship enrichment
  final Map<String, ({String name, String phone, String? village})> _farmersCache = {};
  final Map<String, ({String cropType, String acres})> _cropsCache = {};
  final Map<String, ({String name, String phone})> _staffCache = {};
  bool _catalogsLoaded = false;

  FarmVisitRepositoryImpl({required this.remoteDataSource});

  Future<void> _ensureCatalogsLoaded(String accessToken) async {
    if (_catalogsLoaded) return;
    try {
      final farmersFuture = remoteDataSource.getFarmerLookup(accessToken: accessToken);
      final cropsFuture = remoteDataSource.getCropLookup(accessToken: accessToken);
      final staffFuture = remoteDataSource.getStaffLookup(accessToken: accessToken);

      final results = await Future.wait([farmersFuture, cropsFuture, staffFuture]);
      final farmersMap = results[0] as Map<String, ({String name, String phone, String? village})>;
      final cropsMap = results[1] as Map<String, ({String cropType, String acres})>;
      final staffMap = results[2] as Map<String, ({String name, String phone})>;

      _farmersCache.addAll(farmersMap);
      _cropsCache.addAll(cropsMap);
      _staffCache.addAll(staffMap);
      _catalogsLoaded = true;
    } catch (_) {
      // Enrichment failure must not crash or block visit display
    }
  }

  FarmVisitItem _enrichItem(FarmVisitItem item) {
    final farmer = _farmersCache[item.farmerId];
    final crop = _cropsCache[item.cropId];
    final staff = item.staffId != null ? _staffCache[item.staffId] : null;

    return item.copyWithEnrichment(
      farmerName: farmer?.name,
      farmerPhone: farmer?.phone,
      farmerVillage: farmer?.village,
      cropName: crop?.cropType,
      cropAcres: crop?.acres,
      staffName: staff?.name,
    );
  }

  @override
  Future<({List<FarmVisitItem> items, FarmVisitPagination pagination})> getVisits({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    // 1. Fetch raw visits from backend
    final result = await remoteDataSource.getVisits(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );

    // 2. Ensure relationship lookup catalogs are warm
    await _ensureCatalogsLoaded(accessToken);

    // 3. Enrich items with farmer, crop & staff metadata
    final enrichedItems = result.items.map(_enrichItem).toList();

    return (items: enrichedItems, pagination: result.pagination);
  }

  @override
  Future<FarmVisitItem> scheduleVisit({
    required String accessToken,
    required String visitId,
    String? scheduledDate,
    String? staffId,
  }) async {
    final item = await remoteDataSource.scheduleVisit(
      accessToken: accessToken,
      visitId: visitId,
      scheduledDate: scheduledDate,
      staffId: staffId,
    );
    await _ensureCatalogsLoaded(accessToken);
    return _enrichItem(item);
  }

  @override
  Future<FarmVisitItem> completeVisit({
    required String accessToken,
    required String visitId,
    required String verifiedAcres,
    required String report,
    String? diagnosis,
    String? recommendation,
  }) async {
    final item = await remoteDataSource.completeVisit(
      accessToken: accessToken,
      visitId: visitId,
      verifiedAcres: verifiedAcres,
      report: report,
      diagnosis: diagnosis,
      recommendation: recommendation,
    );
    await _ensureCatalogsLoaded(accessToken);
    return _enrichItem(item);
  }

  @override
  Future<FarmVisitItem> createVisit({
    required String accessToken,
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  }) async {
    final item = await remoteDataSource.createVisit(
      accessToken: accessToken,
      cropId: cropId,
      visitMonth: visitMonth,
      scheduledDate: scheduledDate,
      staffId: staffId,
    );
    await _ensureCatalogsLoaded(accessToken);
    return _enrichItem(item);
  }

  @override
  Future<String> sendVisitReminders({
    required String accessToken,
    int daysAhead = 2,
  }) {
    return remoteDataSource.sendReminders(
      accessToken: accessToken,
      daysAhead: daysAhead,
    );
  }

  @override
  Future<Map<String, ({String cropType, String acres})>> getCropOptions({
    required String accessToken,
  }) async {
    await _ensureCatalogsLoaded(accessToken);
    return Map<String, ({String cropType, String acres})>.unmodifiable(_cropsCache);
  }

  @override
  Future<Map<String, ({String name, String phone})>> getStaffOptions({
    required String accessToken,
  }) async {
    await _ensureCatalogsLoaded(accessToken);
    return Map<String, ({String name, String phone})>.unmodifiable(_staffCache);
  }

  @override
  Future<String> uploadVisitPhoto({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) {
    return remoteDataSource.uploadVisitPhoto(
      accessToken: accessToken,
      fileBytes: fileBytes,
      fileName: fileName,
      contentType: contentType,
    );
  }
}
