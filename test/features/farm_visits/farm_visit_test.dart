import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/features/farm_visits/data/datasources/farm_visit_remote_data_source.dart';
import 'package:agriflow_admin/features/farm_visits/data/repositories/farm_visit_repository_impl.dart';
import 'package:agriflow_admin/features/farm_visits/domain/entities/farm_visit_exception.dart';
import 'package:agriflow_admin/features/farm_visits/domain/entities/farm_visit_item.dart';
import 'package:agriflow_admin/features/farm_visits/domain/entities/farm_visit_pagination.dart';
import 'package:agriflow_admin/features/farm_visits/domain/repositories/farm_visit_repository.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/controllers/farm_visit_controller.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/screens/farm_visit_screen.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/widgets/farm_visit_card.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/widgets/farm_visit_detail_sheet.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/widgets/reschedule_visit_dialog.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/widgets/complete_visit_dialog.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/widgets/schedule_visit_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agriflow_admin/features/farm_visits/domain/services/farm_visit_geo_service.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/widgets/visit_camera_picker.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';

// -------------------------------------------------------------
// Test Helpers & Mocks
// -------------------------------------------------------------

class _MockFarmVisitRemoteDataSource implements FarmVisitRemoteDataSource {
  List<FarmVisitItem> visitsToReturn = [];
  FarmVisitPagination paginationToReturn = const FarmVisitPagination(
    page: 1,
    pageSize: 20,
    total: 0,
    totalPages: 1,
  );
  Map<String, ({String name, String phone, String? village})> farmersToReturn = {};
  Map<String, ({String cropType, String acres})> cropsToReturn = {};
  Map<String, ({String name, String phone})> staffToReturn = {};
  Exception? errorToThrow;
  bool failCatalog = false;
  String? remindersMessage;
  int sendRemindersCallCount = 0;
  int? lastDaysAhead;

  int getVisitsCallCount = 0;
  int scheduleVisitCallCount = 0;
  int completeVisitCallCount = 0;
  String? lastScheduledDate;
  String? lastVerifiedAcres;
  String? lastReport;

  @override
  Future<({List<FarmVisitItem> items, FarmVisitPagination pagination})> getVisits({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    getVisitsCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return (items: visitsToReturn, pagination: paginationToReturn);
  }

  @override
  Future<FarmVisitItem> scheduleVisit({
    required String accessToken,
    required String visitId,
    String? scheduledDate,
    String? staffId,
  }) async {
    scheduleVisitCallCount++;
    lastScheduledDate = scheduledDate;
    if (errorToThrow != null) throw errorToThrow!;

    final existing = visitsToReturn.firstWhere(
      (v) => v.id == visitId,
      orElse: () => FarmVisitItem(
        id: visitId,
        cropId: 'crop-1',
        farmerId: 'farmer-1',
        visitMonth: 1,
        status: 'scheduled',
      ),
    );

    return FarmVisitItem(
      id: existing.id,
      cropId: existing.cropId,
      farmerId: existing.farmerId,
      staffId: staffId ?? existing.staffId,
      visitMonth: existing.visitMonth,
      scheduledDate: scheduledDate ?? existing.scheduledDate,
      actualDate: existing.actualDate,
      status: existing.status,
      verifiedAcres: existing.verifiedAcres,
      report: existing.report,
    );
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
    completeVisitCallCount++;
    lastVerifiedAcres = verifiedAcres;
    lastReport = report;
    if (errorToThrow != null) throw errorToThrow!;

    final existing = visitsToReturn.firstWhere(
      (v) => v.id == visitId,
      orElse: () => FarmVisitItem(
        id: visitId,
        cropId: 'crop-1',
        farmerId: 'farmer-1',
        visitMonth: 1,
        status: 'scheduled',
      ),
    );

    return FarmVisitItem(
      id: existing.id,
      cropId: existing.cropId,
      farmerId: existing.farmerId,
      staffId: existing.staffId,
      visitMonth: existing.visitMonth,
      scheduledDate: existing.scheduledDate,
      actualDate: '2026-09-24',
      status: 'completed',
      verifiedAcres: verifiedAcres,
      report: report,
    );
  }

  @override
  Future<FarmVisitItem> createVisit({
    required String accessToken,
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return FarmVisitItem(
      id: 'new-visit-1',
      cropId: cropId,
      farmerId: 'farmer-1',
      staffId: staffId,
      visitMonth: visitMonth,
      scheduledDate: scheduledDate,
      status: 'scheduled',
    );
  }

  @override
  Future<String> sendReminders({
    required String accessToken,
    int daysAhead = 2,
  }) async {
    sendRemindersCallCount++;
    lastDaysAhead = daysAhead;
    if (errorToThrow != null) throw errorToThrow!;
    return remindersMessage ?? 'Visit reminders sent.';
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
    required String accessToken,
  }) async {
    if (failCatalog) throw Exception('Failed to load farmers');
    return farmersToReturn;
  }

  @override
  Future<Map<String, ({String cropType, String acres})>> getCropLookup({
    required String accessToken,
  }) async {
    if (failCatalog) throw Exception('Failed to load crops');
    return cropsToReturn;
  }

  @override
  Future<Map<String, ({String name, String phone})>> getStaffLookup({
    required String accessToken,
  }) async {
    if (failCatalog) throw Exception('Failed to load staff');
    return staffToReturn;
  }

  @override
  Future<String> uploadVisitPhoto({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return 'https://agriflow-backend-t8o4.onrender.com/static/visits/$fileName';
  }
}

class _MockFarmVisitRepository implements FarmVisitRepository {
  List<FarmVisitItem> itemsToReturn = [];
  FarmVisitPagination paginationToReturn = const FarmVisitPagination(
    page: 1,
    pageSize: 20,
    total: 0,
    totalPages: 1,
  );
  Exception? errorToThrow;
  Map<String, ({String cropType, String acres})> cropsToReturn = {};
  Map<String, ({String name, String phone})> staffToReturn = {};
  int getVisitsCallCount = 0;
  int scheduleVisitCallCount = 0;
  int completeVisitCallCount = 0;
  int sendVisitRemindersCallCount = 0;
  int? lastDaysAhead;
  String? lastFilter;
  String? lastSearch;
  int? lastPage;
  String? lastScheduledDate;
  String? lastVerifiedAcres;
  String? lastReport;

  @override
  Future<({List<FarmVisitItem> items, FarmVisitPagination pagination})> getVisits({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    getVisitsCallCount++;
    lastPage = page;
    lastFilter = status;
    lastSearch = search;
    if (errorToThrow != null) throw errorToThrow!;
    return (items: itemsToReturn, pagination: paginationToReturn);
  }

  @override
  Future<FarmVisitItem> scheduleVisit({
    required String accessToken,
    required String visitId,
    String? scheduledDate,
    String? staffId,
  }) async {
    scheduleVisitCallCount++;
    lastScheduledDate = scheduledDate;
    if (errorToThrow != null) throw errorToThrow!;
    final item = itemsToReturn.firstWhere((v) => v.id == visitId);
    return FarmVisitItem(
      id: item.id,
      cropId: item.cropId,
      farmerId: item.farmerId,
      staffId: staffId ?? item.staffId,
      visitMonth: item.visitMonth,
      scheduledDate: scheduledDate ?? item.scheduledDate,
      actualDate: item.actualDate,
      status: item.status,
      verifiedAcres: item.verifiedAcres,
      report: item.report,
      enrichedFarmerName: item.enrichedFarmerName,
      enrichedFarmerPhone: item.enrichedFarmerPhone,
      enrichedFarmerVillage: item.enrichedFarmerVillage,
      enrichedCropName: item.enrichedCropName,
      enrichedCropAcres: item.enrichedCropAcres,
      enrichedStaffName: item.enrichedStaffName,
    );
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
    completeVisitCallCount++;
    lastVerifiedAcres = verifiedAcres;
    lastReport = report;
    if (errorToThrow != null) throw errorToThrow!;
    final item = itemsToReturn.firstWhere((v) => v.id == visitId);
    return FarmVisitItem(
      id: item.id,
      cropId: item.cropId,
      farmerId: item.farmerId,
      staffId: item.staffId,
      visitMonth: item.visitMonth,
      scheduledDate: item.scheduledDate,
      actualDate: '2026-09-24',
      status: 'completed',
      verifiedAcres: verifiedAcres,
      report: report,
      enrichedFarmerName: item.enrichedFarmerName,
      enrichedFarmerPhone: item.enrichedFarmerPhone,
      enrichedFarmerVillage: item.enrichedFarmerVillage,
      enrichedCropName: item.enrichedCropName,
      enrichedCropAcres: item.enrichedCropAcres,
      enrichedStaffName: item.enrichedStaffName,
    );
  }

  @override
  Future<FarmVisitItem> createVisit({
    required String accessToken,
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return FarmVisitItem(
      id: 'created-visit-1',
      cropId: cropId,
      farmerId: 'farmer-1',
      visitMonth: visitMonth,
      scheduledDate: scheduledDate,
      status: 'scheduled',
    );
  }

  @override
  Future<String> sendVisitReminders({
    required String accessToken,
    int daysAhead = 2,
  }) async {
    sendVisitRemindersCallCount++;
    lastDaysAhead = daysAhead;
    if (errorToThrow != null) throw errorToThrow!;
    return 'Reminders queued for upcoming visits';
  }

  @override
  Future<Map<String, ({String cropType, String acres})>> getCropOptions({
    required String accessToken,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return cropsToReturn;
  }

  @override
  Future<Map<String, ({String name, String phone})>> getStaffOptions({
    required String accessToken,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return staffToReturn;
  }

  @override
  Future<String> uploadVisitPhoto({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return 'https://agriflow-backend-t8o4.onrender.com/static/visits/$fileName';
  }
}

// -------------------------------------------------------------
// Tests Suite
// -------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleVisitJson = {
    'id': '93fb433b-af5e-4f19-8627-3e9a240e4c69',
    'crop_id': '06af9739-122c-505b-99b1-83234e035895',
    'farmer_id': '63acc13e-0eab-5cfd-b777-7c4ce6a3a72b',
    'staff_id': 'staff-uuid-1234',
    'visit_month': 1,
    'scheduled_date': '2026-09-29',
    'actual_date': null,
    'status': 'scheduled',
    'verified_acres': null,
    'report': null,
  };

  group('FarmVisitItem & Pagination Unit Tests', () {
    test('FarmVisitItem.fromJson correctly parses backend contract', () {
      final item = FarmVisitItem.fromJson(sampleVisitJson);

      expect(item.id, '93fb433b-af5e-4f19-8627-3e9a240e4c69');
      expect(item.cropId, '06af9739-122c-505b-99b1-83234e035895');
      expect(item.farmerId, '63acc13e-0eab-5cfd-b777-7c4ce6a3a72b');
      expect(item.staffId, 'staff-uuid-1234');
      expect(item.visitMonth, 1);
      expect(item.scheduledDate, '2026-09-29');
      expect(item.actualDate, isNull);
      expect(item.status, 'scheduled');
      expect(item.verifiedAcres, isNull);
      expect(item.report, isNull);
      expect(item.isEditable, isTrue);
      expect(item.isCompleted, isFalse);
    });

    test('FarmVisitItem fallback fields display safely with short IDs', () {
      final item = FarmVisitItem.fromJson(sampleVisitJson);

      expect(item.displayFarmerName, 'Farmer #63acc13e');
      expect(item.displayCropName, 'Crop #06af9739');
      expect(item.displayStaffName, 'Officer Assigned');
      expect(item.displayVillage, 'Main Village');
      expect(item.farmerInitials, 'F');
    });

    test('FarmVisitItem copyWithEnrichment correctly overrides display fields', () {
      final item = FarmVisitItem.fromJson(sampleVisitJson);
      final enriched = item.copyWithEnrichment(
        farmerName: 'Ramesh Patel',
        farmerPhone: '9876543210',
        farmerVillage: 'Kandukur',
        cropName: 'Cotton',
        cropAcres: '5.0',
        staffName: 'Suresh Field Officer',
      );

      expect(enriched.displayFarmerName, 'Ramesh Patel');
      expect(enriched.farmerInitials, 'RP');
      expect(enriched.enrichedFarmerPhone, '9876543210');
      expect(enriched.displayVillage, 'Kandukur');
      expect(enriched.displayCropName, 'Cotton');
      expect(enriched.enrichedCropAcres, '5.0');
      expect(enriched.displayStaffName, 'Suresh Field Officer');
    });

    test('FarmVisitPagination parses correctly and determines hasMore', () {
      final p1 = FarmVisitPagination.fromJson({
        'page': 1,
        'page_size': 20,
        'total': 45,
        'total_pages': 3,
      });
      expect(p1.page, 1);
      expect(p1.pageSize, 20);
      expect(p1.total, 45);
      expect(p1.totalPages, 3);
      expect(p1.hasMore, isTrue);

      final pLast = FarmVisitPagination.fromJson({
        'page': 3,
        'page_size': 20,
        'total': 45,
        'total_pages': 3,
      });
      expect(pLast.hasMore, isFalse);
    });

    test('FarmVisitException hierarchy provides clean typed errors', () {
      expect(const FarmVisitNetworkException().statusCode, 0);
      expect(const FarmVisitAuthException().statusCode, 401);
      expect(const FarmVisitPermissionException().statusCode, 403);
      expect(const FarmVisitNotFoundException().statusCode, 404);
      expect(const FarmVisitValidationException('Bad Acres').statusCode, 422);
      expect(const FarmVisitServerException().statusCode, 500);
    });
  });

  group('FarmVisitRepositoryImpl Tests', () {
    late _MockFarmVisitRemoteDataSource mockRemoteDataSource;
    late FarmVisitRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockFarmVisitRemoteDataSource();
      repository = FarmVisitRepositoryImpl(remoteDataSource: mockRemoteDataSource);

      mockRemoteDataSource.visitsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson),
      ];
      mockRemoteDataSource.farmersToReturn = {
        '63acc13e-0eab-5cfd-b777-7c4ce6a3a72b': (name: 'Kiran Kumar', phone: '9988776655', village: 'Medak'),
      };
      mockRemoteDataSource.cropsToReturn = {
        '06af9739-122c-505b-99b1-83234e035895': (cropType: 'Groundnut', acres: '4.5'),
      };
      mockRemoteDataSource.staffToReturn = {
        'staff-uuid-1234': (name: 'Anil Officer', phone: '5555555555'),
      };
    });

    test('getVisits enriches visits using catalogs', () async {
      final result = await repository.getVisits(accessToken: 'token');

      expect(result.items.length, 1);
      final item = result.items.first;
      expect(item.displayFarmerName, 'Kiran Kumar');
      expect(item.displayCropName, 'Groundnut');
      expect(item.displayStaffName, 'Anil Officer');
      expect(item.displayVillage, 'Medak');
    });

    test('getVisits gracefully falls back if catalogs fail to load', () async {
      mockRemoteDataSource.failCatalog = true;
      final result = await repository.getVisits(accessToken: 'token');

      expect(result.items.length, 1);
      final item = result.items.first;
      expect(item.displayFarmerName, 'Farmer #63acc13e');
      expect(item.displayCropName, 'Crop #06af9739');
      expect(item.displayVillage, 'Main Village');
    });

    test('scheduleVisit updates scheduled date on remote data source', () async {
      final updated = await repository.scheduleVisit(
        accessToken: 'token',
        visitId: '93fb433b-af5e-4f19-8627-3e9a240e4c69',
        scheduledDate: '2026-10-15',
      );

      expect(mockRemoteDataSource.scheduleVisitCallCount, 1);
      expect(mockRemoteDataSource.lastScheduledDate, '2026-10-15');
      expect(updated.scheduledDate, '2026-10-15');
    });

    test('completeVisit updates verified acres and report', () async {
      final completed = await repository.completeVisit(
        accessToken: 'token',
        visitId: '93fb433b-af5e-4f19-8627-3e9a240e4c69',
        verifiedAcres: '4.2',
        report: 'Good growth, no pest infestation observed.',
      );

      expect(mockRemoteDataSource.completeVisitCallCount, 1);
      expect(mockRemoteDataSource.lastVerifiedAcres, '4.2');
      expect(mockRemoteDataSource.lastReport, 'Good growth, no pest infestation observed.');
      expect(completed.status, 'completed');
      expect(completed.isCompleted, isTrue);
    });
  });

  group('FarmVisitController State & Mutation Tests', () {
    late _MockFarmVisitRepository mockRepository;
    late FarmVisitController controller;

    setUp(() {
      mockRepository = _MockFarmVisitRepository();
      controller = FarmVisitController(
        repository: mockRepository,
        accessToken: 'test-token',
      );

      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
          farmerName: 'Venkat Rao',
          cropName: 'Cotton',
        ),
      ];
      mockRepository.paginationToReturn = const FarmVisitPagination(
        page: 1,
        pageSize: 20,
        total: 1,
        totalPages: 1,
      );
    });

    test('Initial state is clean', () {
      expect(controller.status, FarmVisitViewStatus.initial);
      expect(controller.visits, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.isSuccess, isFalse);
      expect(controller.isError, isFalse);
    });

    test('loadVisits successfully populates visits', () async {
      await controller.loadVisits();

      expect(controller.status, FarmVisitViewStatus.success);
      expect(controller.visits.length, 1);
      expect(controller.visits.first.displayFarmerName, 'Venkat Rao');
      expect(mockRepository.getVisitsCallCount, 1);
    });

    test('loadVisits transitions to error on failure', () async {
      mockRepository.errorToThrow = const FarmVisitNetworkException('Connection timeout');

      await controller.loadVisits();

      expect(controller.status, FarmVisitViewStatus.error);
      expect(controller.errorMessage, 'Connection timeout');
      expect(controller.visits, isEmpty);
    });

    test('refreshVisits replaces dataset without losing UI stability', () async {
      await controller.loadVisits();
      expect(controller.visits.length, 1);

      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(farmerName: 'New Farmer 1'),
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(farmerName: 'New Farmer 2'),
      ];

      await controller.refreshVisits();

      expect(controller.visits.length, 2);
      expect(controller.visits[0].displayFarmerName, 'New Farmer 1');
      expect(controller.visits[1].displayFarmerName, 'New Farmer 2');
    });

    test('loadMoreVisits appends subsequent page without replacing existing items', () async {
      mockRepository.paginationToReturn = const FarmVisitPagination(
        page: 1,
        pageSize: 1,
        total: 2,
        totalPages: 2,
      );
      await controller.loadVisits();
      expect(controller.visits.length, 1);

      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(farmerName: 'Page 2 Farmer'),
      ];
      mockRepository.paginationToReturn = const FarmVisitPagination(
        page: 2,
        pageSize: 1,
        total: 2,
        totalPages: 2,
      );

      await controller.loadMoreVisits();

      expect(controller.visits.length, 2);
      expect(controller.visits[1].displayFarmerName, 'Page 2 Farmer');
    });

    test('setFilter triggers reload with updated status filter', () async {
      controller.setFilter('completed');

      expect(controller.activeFilter, 'completed');
      expect(mockRepository.lastFilter, 'completed');
    });

    test('setSearchQuery triggers reload with query', () async {
      controller.setSearchQuery('Cotton');

      expect(controller.searchQuery, 'Cotton');
      expect(mockRepository.lastSearch, 'Cotton');
    });

    test('scheduleVisit authoritatively mutates date and updates list', () async {
      await controller.loadVisits();
      expect(controller.visits.first.scheduledDate, '2026-09-29');

      final success = await controller.scheduleVisit(
        visitId: '93fb433b-af5e-4f19-8627-3e9a240e4c69',
        scheduledDate: '2026-10-05',
      );

      expect(success, isTrue);
      expect(controller.visits.first.scheduledDate, '2026-10-05');
      expect(mockRepository.scheduleVisitCallCount, 1);
    });

    test('completeVisit authoritatively updates status to completed', () async {
      await controller.loadVisits();
      expect(controller.visits.first.status, 'scheduled');

      final success = await controller.completeVisit(
        visitId: '93fb433b-af5e-4f19-8627-3e9a240e4c69',
        verifiedAcres: '5.0',
        report: 'Inspection verified.',
      );

      expect(success, isTrue);
      expect(controller.visits.first.status, 'completed');
      expect(mockRepository.completeVisitCallCount, 1);
    });
  });

  group('FarmVisitScreen UI & Widget Tests', () {
    late _MockFarmVisitRepository mockRepository;
    late FarmVisitController controller;

    setUp(() {
      mockRepository = _MockFarmVisitRepository();
      controller = FarmVisitController(
        repository: mockRepository,
        accessToken: 'test-token',
      );
    });

    Widget createScreen() {
      return MaterialApp(
        home: FarmVisitScreen(
          controller: controller,
          onBack: () {},
        ),
      );
    }

    testWidgets('Renders header, eyebrow, search bar, and filter chips', (tester) async {
      mockRepository.itemsToReturn = [];
      await tester.pumpWidget(createScreen());
      await tester.pump();

      expect(find.text('Field team schedule'), findsOneWidget);
      expect(find.text('Farm Visits'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('Renders loading view when controller is loading', (tester) async {
      mockRepository.itemsToReturn = [];
      await tester.pumpWidget(createScreen());

      // While initial load is in progress
      expect(find.byType(DashboardLoadingView), findsOneWidget);
    });

    testWidgets('Renders error view with retry button on error', (tester) async {
      mockRepository.errorToThrow = const FarmVisitServerException('Server failure');
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardErrorView), findsOneWidget);
      expect(find.text('Server failure'), findsOneWidget);
    });

    testWidgets('Renders empty state when 0 visits match', (tester) async {
      mockRepository.itemsToReturn = [];
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('No visits here'), findsOneWidget);
      expect(find.text('No farm visits match this filter.'), findsOneWidget);
    });

    testWidgets('Renders populated visit card matching HTML UX', (tester) async {
      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
          farmerName: 'Balaji Farmer',
          cropName: 'Chilli',
          cropAcres: '3.0',
          staffName: 'Officer Ravi',
          farmerVillage: 'Warangal',
        ),
      ];

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FarmVisitCard), findsOneWidget);
      expect(find.text('Balaji Farmer'), findsOneWidget);
      expect(find.text('Chilli'), findsOneWidget);
      expect(find.text('BF'), findsOneWidget);
      expect(find.text('Officer Ravi · Warangal'), findsOneWidget);
    });

    testWidgets('Tapping visit card opens FarmVisitDetailSheet with actions', (tester) async {
      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
          farmerName: 'Balaji Farmer',
          cropName: 'Chilli',
          cropAcres: '3.0',
          staffName: 'Officer Ravi',
          farmerVillage: 'Warangal',
        ),
      ];

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FarmVisitCard));
      await tester.pumpAndSettle();

      expect(find.byType(FarmVisitDetailSheet), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      // Confirmed: Cancel action is NOT present
      expect(find.text('Cancel visit'), findsNothing);
    });

    testWidgets('Tapping Reschedule opens RescheduleVisitDialog', (tester) async {
      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
          farmerName: 'Balaji Farmer',
        ),
      ];

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FarmVisitCard));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reschedule'));
      await tester.pumpAndSettle();

      expect(find.byType(RescheduleVisitDialog), findsOneWidget);
      expect(find.text('Reschedule Visit'), findsOneWidget);
      expect(find.text('Save Date'), findsOneWidget);
    });

    testWidgets('Tapping Complete opens CompleteVisitDialog', (tester) async {
      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
          farmerName: 'Balaji Farmer',
        ),
      ];

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FarmVisitCard));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      expect(find.byType(CompleteVisitDialog), findsOneWidget);
      expect(find.text('Complete Farm Visit'), findsOneWidget);
      expect(find.text('Mark Complete'), findsOneWidget);
    });

    testWidgets('Zero RenderFlex overflow across various mobile screen sizes', (tester) async {
      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
          farmerName: 'Sri Venkata Satyanarayana Murthy Senior Farmer Long Name',
          cropName: 'Cotton Premium Long Staple Variety',
          cropAcres: '125.50',
          staffName: 'Senior Assistant Field Investigation Officer Ravi Kiran',
          farmerVillage: 'Chintapalli Mandal Pedda Gudem Village Sector 4',
        ),
      ];

      const testSizes = [
        Size(320, 568), // iPhone SE / small Android
        Size(360, 640), // Standard Android compact
        Size(412, 860), // Pixel standard
        Size(412, 960), // Pixel tall
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createScreen());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow occurred at $size');
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('M6-A Reminders, Schedule Sheet & Pending Review', () {
    late _MockFarmVisitRepository mockRepository;
    late FarmVisitController controller;

    setUp(() {
      mockRepository = _MockFarmVisitRepository();
      controller = FarmVisitController(
        repository: mockRepository,
        accessToken: 'test-token',
      );
    });

    Widget createScreen() => MaterialApp(
          home: FarmVisitScreen(controller: controller, onBack: () {}),
        );

    test('sendVisitReminders returns backend message with default daysAhead=2',
        () async {
      final message = await controller.sendVisitReminders();

      expect(message, 'Reminders queued for upcoming visits');
      expect(mockRepository.sendVisitRemindersCallCount, 1);
      expect(mockRepository.lastDaysAhead, 2);
      expect(controller.errorMessage, isNull);
    });

    test('sendVisitReminders forwards a custom daysAhead', () async {
      final message = await controller.sendVisitReminders(daysAhead: 5);

      expect(message, isNotNull);
      expect(mockRepository.lastDaysAhead, 5);
    });

    test('sendVisitReminders returns null and sets errorMessage on failure',
        () async {
      mockRepository.errorToThrow = const FarmVisitServerException('Reminder outage');

      final message = await controller.sendVisitReminders();

      expect(message, isNull);
      expect(controller.errorMessage, 'Reminder outage');
    });

    test('getCropOptions and getStaffOptions delegate to repository catalogs',
        () async {
      mockRepository.cropsToReturn = {
        'crop-1': (cropType: 'Chilli', acres: '3.0'),
      };
      mockRepository.staffToReturn = {
        'staff-1': (name: 'Ravi', phone: '7777777799'),
      };

      final crops = await controller.getCropOptions();
      final staff = await controller.getStaffOptions();

      expect(crops.keys, contains('crop-1'));
      expect(staff.keys, contains('staff-1'));
    });

    testWidgets('Header exposes reminders & schedule buttons and Pending Review chip',
        (tester) async {
      mockRepository.itemsToReturn = [];
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('farm_visit_reminders_btn')), findsOneWidget);
      expect(find.byKey(const Key('farm_visit_create_btn')), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
    });

    testWidgets('Tapping reminders shows the backend message in a snackbar',
        (tester) async {
      mockRepository.itemsToReturn = [];
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('farm_visit_reminders_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Reminders queued for upcoming visits'), findsOneWidget);
    });

    testWidgets('Reminders failure shows the error message in a snackbar',
        (tester) async {
      mockRepository.itemsToReturn = [];
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();
      mockRepository.errorToThrow = const FarmVisitServerException('Reminder outage');

      await tester.tap(find.byKey(const Key('farm_visit_reminders_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Reminder outage'), findsOneWidget);
    });

    testWidgets('Schedule button opens the schedule-visit sheet with lookups',
        (tester) async {
      mockRepository.itemsToReturn = [];
      mockRepository.cropsToReturn = {
        'crop-1': (cropType: 'Chilli', acres: '3.0'),
      };
      mockRepository.staffToReturn = {
        'staff-1': (name: 'Ravi', phone: '7777777799'),
      };

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('farm_visit_create_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('schedule_visit_sheet')), findsOneWidget);
      expect(find.text('Schedule a Visit'), findsOneWidget);
      expect(find.text('Select crop'), findsOneWidget);
    });

    testWidgets('Schedule sheet enforces crop, month and date as required',
        (tester) async {
      mockRepository.itemsToReturn = [];
      mockRepository.cropsToReturn = {
        'crop-1': (cropType: 'Chilli', acres: '3.0'),
      };

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('farm_visit_create_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('schedule_visit_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Please select a crop'), findsOneWidget);
      expect(find.text('Date is required'), findsOneWidget);
      expect(find.byKey(const Key('schedule_visit_error')), findsNothing);
    });

    testWidgets('Schedule sheet happy path calls createVisit and confirms',
        (tester) async {
      mockRepository.itemsToReturn = [FarmVisitItem.fromJson(sampleVisitJson)];
      mockRepository.cropsToReturn = {
        'crop-1': (cropType: 'Chilli', acres: '3.0'),
      };

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('farm_visit_create_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('schedule_visit_crop_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chilli (3.0 ac)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('schedule_visit_month_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('schedule_visit_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('schedule_visit_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Visit scheduled successfully.'), findsOneWidget);
      expect(find.byKey(const Key('schedule_visit_sheet')), findsNothing);
    });

    testWidgets('Schedule sheet surfaces createVisit failure inline', (tester) async {
      mockRepository.itemsToReturn = [];
      mockRepository.cropsToReturn = {
        'crop-1': (cropType: 'Chilli', acres: '3.0'),
      };

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('farm_visit_create_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('schedule_visit_crop_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chilli (3.0 ac)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('schedule_visit_month_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('schedule_visit_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      mockRepository.errorToThrow = const FarmVisitServerException('Schedule failed');

      await tester.tap(find.byKey(const Key('schedule_visit_submit_btn')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('schedule_visit_sheet')),
          matching: find.byKey(const Key('schedule_visit_error')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('schedule_visit_sheet')),
          matching: find.text('Schedule failed'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('schedule_visit_sheet')), findsOneWidget);
    });

    testWidgets('Reschedule failure shows inline error and keeps dialog open',
        (tester) async {
      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
          farmerName: 'Balaji Farmer',
        ),
      ];
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();
      mockRepository.errorToThrow = const FarmVisitServerException('Reschedule failed');

      await tester.tap(find.byType(FarmVisitCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reschedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Date'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reschedule_visit_error')), findsOneWidget);
      expect(find.text('Reschedule failed'), findsOneWidget);
      expect(find.byType(RescheduleVisitDialog), findsOneWidget);
    });

    testWidgets('Complete failure shows inline error and keeps dialog open',
        (tester) async {
      mockRepository.itemsToReturn = [
        FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
          farmerName: 'Balaji Farmer',
        ),
      ];
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FarmVisitCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      final dialogFields = find.descendant(
        of: find.byType(CompleteVisitDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogFields.at(0), '2.5');
      await tester.enterText(dialogFields.at(1), 'Crop looks healthy.');
      mockRepository.errorToThrow = const FarmVisitServerException('Complete failed');

      await tester.tap(find.text('Mark Complete'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('complete_visit_error')), findsOneWidget);
      expect(find.text('Complete failed'), findsOneWidget);
      expect(find.byType(CompleteVisitDialog), findsOneWidget);
    });

    testWidgets('Schedule Visit sheet does NOT contain photo capture or geo-fence fields',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleVisitSheet(
              loadCrops: () async => {'c1': (cropType: 'Cotton', acres: '4.0')},
              loadStaff: () async => {'s1': (name: 'Manager Ravi', phone: '9876543210')},
              onSubmit: ({
                required cropId,
                required visitMonth,
                required scheduledDate,
                staffId,
              }) async =>
                  true,
              isSubmitting: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Capture Field Photo'), findsNothing);
      expect(find.text('Field Photo & Geo-Fence (optional)'), findsNothing);
      expect(find.text('Field Photo & Geo-Fence'), findsNothing);
      expect(find.byKey(const Key('schedule_visit_sheet')), findsOneWidget);
      expect(find.byKey(const Key('schedule_visit_crop_field')), findsOneWidget);
      expect(find.byKey(const Key('schedule_visit_month_field')), findsOneWidget);
      expect(find.byKey(const Key('schedule_visit_date_field')), findsOneWidget);
      expect(find.byKey(const Key('schedule_visit_staff_field')), findsOneWidget);
    });

    testWidgets('Complete Farm Visit dialog DOES contain Capture Field Photo',
        (tester) async {
      final item = FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
        farmerName: 'Balaji Farmer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompleteVisitDialog(
              item: item,
              onConfirm: ({
                required verifiedAcres,
                required report,
                diagnosis,
                recommendation,
              }) async =>
                  true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Capture Field Photo'), findsOneWidget);
      expect(find.text('Field Photo (Optional)'), findsOneWidget);
      expect(find.byKey(const Key('complete_visit_camera_btn')), findsOneWidget);
    });

    testWidgets('Complete Farm Visit captures photo, previews, retakes and attaches to completion',
        (tester) async {
      final item = FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
        farmerName: 'Balaji Farmer',
      );

      String? uploadedFileName;
      String? completedAcres;
      String? completedReport;

      final testPhoto = VisitPickedPhoto(
        bytes: const [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
          0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
          0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
          0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
        ],
        fileName: 'field_test.png',
        mimeType: 'image/png',
        gpsCoordinates: FarmGpsCoordinates(
          latitude: 15.8281,
          longitude: 78.0373,
          accuracy: 4.5,
          timestamp: DateTime(2026, 9, 29),
        ),
      );

      final mockPicker = VisitCameraPicker(
        pickFn: ({
          required source,
          gpsCoordinates,
          farmName,
          farmAddress,
        }) async =>
            testPhoto,
      );

      final mockGeo = FarmVisitGeoService(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.always,
        getCurrentPosition: ({locationSettings}) async => Position(
          latitude: 15.8281,
          longitude: 78.0373,
          timestamp: DateTime(2026, 9, 29),
          accuracy: 4.5,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompleteVisitDialog(
              item: item,
              cameraPicker: mockPicker,
              geoService: mockGeo,
              onUploadPhoto: ({
                required fileBytes,
                required fileName,
                required contentType,
              }) async {
                uploadedFileName = fileName;
                return 'https://oeniehldcnxevjkjlzh.storage.supabase.co/storage/v1/s3/farm-visits/$fileName';
              },
              onConfirm: ({
                required verifiedAcres,
                required report,
                diagnosis,
                recommendation,
              }) async {
                completedAcres = verifiedAcres;
                completedReport = report;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap capture photo
      await tester.tap(find.byKey(const Key('complete_visit_camera_btn')));
      await tester.pumpAndSettle();

      // Verify preview
      expect(find.byKey(const Key('complete_visit_photo_preview')), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.textContaining('15.828100'), findsOneWidget);

      // Fill in required acres and report
      final dialogFields = find.byType(TextField);
      await tester.enterText(dialogFields.at(0), '5.0');
      await tester.enterText(dialogFields.at(1), 'Good vegetative growth.');

      // Mark complete
      await tester.tap(find.text('Mark Complete'));
      await tester.pumpAndSettle();

      expect(uploadedFileName, 'field_test.png');
      expect(completedAcres, '5.0');
      expect(
        completedReport,
        contains('[Field Photo]: https://oeniehldcnxevjkjlzh.storage.supabase.co/storage/v1/s3/farm-visits/field_test.png'),
      );
    });

    testWidgets('Complete Farm Visit completes normally when photo is skipped (optional)',
        (tester) async {
      final item = FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
        farmerName: 'Balaji Farmer',
      );

      String? completedAcres;
      String? completedReport;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompleteVisitDialog(
              item: item,
              onConfirm: ({
                required verifiedAcres,
                required report,
                diagnosis,
                recommendation,
              }) async {
                completedAcres = verifiedAcres;
                completedReport = report;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dialogFields = find.byType(TextField);
      await tester.enterText(dialogFields.at(0), '4.5');
      await tester.enterText(dialogFields.at(1), 'No pest issues found.');

      await tester.tap(find.text('Mark Complete'));
      await tester.pumpAndSettle();

      expect(completedAcres, '4.5');
      expect(completedReport, 'No pest issues found.');
    });

    testWidgets('FarmVisitDetailSheet renders Field Photo image card and clean report text without raw URL',
        (tester) async {
      const photoUrl =
          'https://oeniehldcnxevjkjlzh.storage.supabase.co/storage/v1/s3/farm-visits/bb28b2e0.jpg';
      final item = FarmVisitItem.fromJson(sampleVisitJson).copyWithEnrichment(
        farmerName: 'Mehbooba',
      );
      final itemWithPhoto = FarmVisitItem(
        id: item.id,
        cropId: item.cropId,
        farmerId: item.farmerId,
        visitMonth: item.visitMonth,
        status: 'completed',
        report: 'All crops inspected and free of disease.\n[Field Photo]: $photoUrl',
        enrichedFarmerName: item.enrichedFarmerName,
      );

      expect(itemWithPhoto.fieldPhotoUrl, photoUrl);
      expect(itemWithPhoto.cleanReportNotes, 'All crops inspected and free of disease.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FarmVisitDetailSheet(
              item: itemWithPhoto,
              onReschedule: () {},
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT display raw URL as text anywhere
      expect(find.textContaining('[Field Photo]:'), findsNothing);
      expect(find.text(photoUrl), findsNothing);

      // Must display clean report text
      expect(find.text('All crops inspected and free of disease.'), findsOneWidget);

      // Must display Field Photo section with image container
      expect(find.text('Field Photo'), findsOneWidget);
      expect(find.byKey(const Key('farm_visit_detail_field_photo')), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    test('FarmVisitGeoService validates distance and geofence correctly', () {
      const geo = FarmVisitGeoService();

      // Inside 500m (e.g. ~100m away)
      final inside = geo.validateGeofence(
        currentLat: 15.828100,
        currentLng: 78.037300,
        farmLat: 15.828500,
        farmLng: 78.037500,
        radiusMeters: 500.0,
      );
      expect(inside.isInside, isTrue);

      // Outside 500m (e.g. ~1.5km away)
      final outside = geo.validateGeofence(
        currentLat: 15.828100,
        currentLng: 78.037300,
        farmLat: 15.842000,
        farmLng: 78.045000,
        radiusMeters: 500.0,
      );
      expect(outside.isInside, isFalse);
      expect(outside.distanceMeters, greaterThan(1000.0));
    });
  });
}
