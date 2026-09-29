import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/features/farmers/data/datasources/farmer_remote_data_source.dart';
import 'package:agriflow_admin/features/farmers/data/repositories/farmer_repository_impl.dart';
import 'package:agriflow_admin/features/farmers/domain/entities/bank_change_request_item.dart';
import 'package:agriflow_admin/features/farmers/domain/entities/farmer_exception.dart';
import 'package:agriflow_admin/features/farmers/domain/entities/farmer_item.dart';
import 'package:agriflow_admin/features/farmers/domain/entities/farmer_pagination.dart';
import 'package:agriflow_admin/features/farmers/domain/entities/farmer_profile_item.dart';
import 'package:agriflow_admin/features/farmers/domain/repositories/farmer_repository.dart';
import 'package:agriflow_admin/features/farmers/presentation/controllers/farmer_controller.dart';
import 'package:agriflow_admin/features/farmers/presentation/screens/farmer_screen.dart';
import 'package:agriflow_admin/features/farmers/presentation/widgets/add_farmer_sheet.dart';
import 'package:agriflow_admin/features/farmers/presentation/widgets/bank_change_requests_sheet.dart';
import 'package:agriflow_admin/features/farmers/presentation/widgets/edit_farmer_profile_sheet.dart';
import 'package:agriflow_admin/features/farmers/presentation/widgets/farmer_card.dart';
import 'package:agriflow_admin/features/farmers/presentation/widgets/farmer_detail_sheet.dart';

// ---------------------------------------------------------------------------
// Mock Remote Data Source & Repository for Unit / Widget Testing
// ---------------------------------------------------------------------------

class _MockFarmerRemoteDataSource implements FarmerRemoteDataSource {
  List<FarmerItem> farmersToReturn = [];
  FarmerPagination paginationToReturn = const FarmerPagination(
    page: 1,
    pageSize: 20,
    totalRecords: 0,
    totalPages: 1,
    hasNext: false,
    hasPrevious: false,
  );
  List<BankChangeRequestItem> bankRequestsToReturn = [];
  List<BankChangeRequestItem> bankPage2Items = [];
  Exception? errorToThrow;

  int getFarmersCallCount = 0;
  int getDetailCallCount = 0;
  int approvalCallCount = 0;
  int createCallCount = 0;
  int getBankRequestsCallCount = 0;
  int reviewBankRequestCallCount = 0;
  int updateProfileCallCount = 0;
  String? lastUpdatedName;
  String? lastUpdatedPhone;
  List<FarmerItem> page2Items = [];

  @override
  Future<({List<FarmerItem> items, FarmerPagination pagination})> getFarmers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) async {
    getFarmersCallCount++;
    if (errorToThrow != null) throw errorToThrow!;

    if (page >= 2 && page2Items.isNotEmpty) {
      return (
        items: page2Items,
        pagination: paginationToReturn.copyWith(page: page, hasNext: false),
      );
    }

    var filtered = List<FarmerItem>.from(farmersToReturn);
    if (status != null && status != 'all') {
      filtered = filtered.where((f) => f.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where((f) => f.name.toLowerCase().contains(q) || f.phone.contains(q))
          .toList();
    }

    return (
      items: filtered,
      pagination: paginationToReturn.copyWith(totalRecords: filtered.length),
    );
  }

  @override
  Future<FarmerItem> getFarmerDetail({
    required String accessToken,
    required String farmerId,
  }) async {
    getDetailCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return farmersToReturn.firstWhere(
      (f) => f.id == farmerId,
      orElse: () => FarmerItem(
        id: farmerId,
        name: 'Loaded Farmer',
        phone: '9876543210',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  Future<FarmerItem> setFarmerApproval({
    required String accessToken,
    required String farmerId,
    required String status,
  }) async {
    approvalCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    final index = farmersToReturn.indexWhere((f) => f.id == farmerId);
    if (index != -1) {
      final updated = farmersToReturn[index].copyWith(status: status);
      farmersToReturn[index] = updated;
      return updated;
    }
    return FarmerItem(
      id: farmerId,
      name: 'Approved Farmer',
      phone: '9876543210',
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<FarmerItem> updateFarmerProfile({
    required String accessToken,
    required String farmerId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? acresOfLand,
    String? soilType,
    String? irrigationType,
    String? primaryCrop,
    String? secondaryCrop,
  }) async {
    updateProfileCallCount++;
    lastUpdatedName = name;
    lastUpdatedPhone = phone;
    if (errorToThrow != null) throw errorToThrow!;

    final index = farmersToReturn.indexWhere((f) => f.id == farmerId);
    if (index != -1) {
      final existing = farmersToReturn[index];
      final updated = existing.copyWith(
        name: name ?? existing.name,
        phone: phone ?? existing.phone,
        email: email ?? existing.email,
      );
      farmersToReturn[index] = updated;
      return updated;
    }
    return FarmerItem(
      id: farmerId,
      name: name ?? 'Updated Farmer',
      phone: phone ?? '9876543210',
      email: email,
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<FarmerItem> createFarmer({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? address,
    double? acresOfLand,
    String? cropAddress,
  }) async {
    createCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    final created = FarmerItem(
      id: 'f-new-1',
      name: name,
      phone: phone,
      email: email,
      status: 'pending',
      createdAt: DateTime.now(),
      profile: FarmerProfileItem(
        id: 'p-new-1',
        userId: 'f-new-1',
        address: address,
        acresOfLand: acresOfLand?.toString() ?? '0',
        bankStatus: 'pending',
      ),
    );
    farmersToReturn.insert(0, created);
    return created;
  }

  @override
  Future<({List<BankChangeRequestItem> items, FarmerPagination pagination})> getBankChangeRequests({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) async {
    getBankRequestsCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    if (page >= 2 && bankPage2Items.isNotEmpty) {
      return (
        items: bankPage2Items,
        pagination: paginationToReturn.copyWith(page: page, hasNext: false),
      );
    }
    return (items: bankRequestsToReturn, pagination: paginationToReturn);
  }

  @override
  Future<void> reviewBankChangeRequest({
    required String accessToken,
    required String requestId,
    required bool approve,
    String? adminNotes,
  }) async {
    reviewBankRequestCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
  }
}

// Helper to wrap test widgets
Widget _buildTestApp(Widget child, {Size? mediaSize}) {
  return MaterialApp(
    home: mediaSize != null
        ? MediaQuery(
            data: MediaQueryData(size: mediaSize),
            child: child,
          )
        : child,
  );
}

// ---------------------------------------------------------------------------
// Main Test Suite
// ---------------------------------------------------------------------------

void main() {
  group('Farmer Domain Entity Tests', () {
    test('FarmerItem.fromJson parses full JSON with profile correctly', () {
      final json = {
        'id': 'f-uuid-1',
        'name': 'Ramulu Naik',
        'phone': '9876543210',
        'email': 'ramulu@example.com',
        'status': 'active',
        'created_at': '2026-05-15T10:30:00Z',
        'farmer_profile': {
          'id': 'p-uuid-1',
          'user_id': 'f-uuid-1',
          'address': 'Mothkur Village',
          'acres_of_land': '5.5',
          'bank_name': 'State Bank of India',
          'account_number': '1234567890',
          'ifsc_code': 'SBIN0001234',
          'upi_id': 'ramulu@upi',
          'bank_status': 'approved',
          'soil_type': 'Black Cotton',
          'irrigation_type': 'Borewell',
          'primary_crop': 'Cotton',
          'secondary_crop': 'Soybean',
        },
      };

      final item = FarmerItem.fromJson(json);

      expect(item.id, 'f-uuid-1');
      expect(item.name, 'Ramulu Naik');
      expect(item.phone, '9876543210');
      expect(item.email, 'ramulu@example.com');
      expect(item.status, 'active');
      expect(item.isActive, isTrue);
      expect(item.isPending, isFalse);
      expect(item.initials, 'RN');
      expect(item.landAcres, '5.5');
      expect(item.landAcresDisplay, '5.5 acres');
      expect(item.villageOrAddress, 'Mothkur Village');

      final profile = item.profile;
      expect(profile, isNotNull);
      expect(profile!.bankName, 'State Bank of India');
      expect(profile.accountNumber, '1234567890');
      expect(profile.ifscCode, 'SBIN0001234');
      expect(profile.acresNumeric, 5.5);
    });

    test('FarmerItem.fromJson handles null profile and optional values', () {
      final json = {
        'id': 'f-uuid-2',
        'name': 'Suresh',
        'phone': '9123456789',
        'status': 'pending',
        'created_at': '2026-06-01T00:00:00Z',
      };

      final item = FarmerItem.fromJson(json);

      expect(item.id, 'f-uuid-2');
      expect(item.name, 'Suresh');
      expect(item.email, isNull);
      expect(item.profile, isNull);
      expect(item.isPending, isTrue);
      expect(item.initials, 'S');
      expect(item.landAcres, '0');
      expect(item.landAcresDisplay, '0 acres');
      expect(item.villageOrAddress, '');
    });

    test('FarmerPagination.fromJson and empty() factory operate correctly', () {
      final empty = FarmerPagination.empty();
      expect(empty.page, 1);
      expect(empty.totalRecords, 0);
      expect(empty.hasNext, isFalse);

      final json = {
        'page': 2,
        'page_size': 10,
        'total': 35,
        'total_pages': 4,
      };

      final pag = FarmerPagination.fromJson(json);
      expect(pag.page, 2);
      expect(pag.pageSize, 10);
      expect(pag.totalRecords, 35);
      expect(pag.totalPages, 4);
      expect(pag.hasNext, isTrue);
      expect(pag.hasPrevious, isTrue);

      // Last page: hasNext must derive false even without a has_next key
      final lastPage = FarmerPagination.fromJson({
        'page': 4,
        'page_size': 10,
        'total': 35,
        'total_pages': 4,
      });
      expect(lastPage.hasNext, isFalse);
      expect(lastPage.hasPrevious, isTrue);
    });

    test('BankChangeRequestItem.fromJson parses fields and displays name fallback', () {
      final json = {
        'id': 'bcr-uuid-1',
        'farmer_id': 'f-uuid-12345678',
        'bank_name': 'HDFC Bank',
        'account_number': '987654321',
        'ifsc_code': 'HDFC0001234',
        'upi_id': 'user@hdfc',
        'status': 'pending',
        'admin_notes': null,
        'requested_at': '2026-07-10T12:00:00Z',
      };

      final req = BankChangeRequestItem.fromJson(json);
      expect(req.id, 'bcr-uuid-1');
      expect(req.bankName, 'HDFC Bank');
      expect(req.isPending, isTrue);
      expect(req.displayFarmerName, 'Farmer #f-uuid-1');

      final enriched = req.copyWithEnrichment(farmerName: 'Kavitha');
      expect(enriched.displayFarmerName, 'Kavitha');
    });
  });

  group('FastApiFarmerRemoteDataSource HTTP Tests', () {
    test('getFarmers returns parsed list on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/farmers');
        expect(request.url.queryParameters['page'], '1');
        expect(request.headers['Authorization'], 'Bearer test-token');

        final responseBody = jsonEncode({
          'data': [
            {
              'id': 'f-1',
              'name': 'Test Farmer',
              'phone': '9876543210',
              'status': 'active',
              'created_at': '2026-01-01T00:00:00Z',
            }
          ],
          'pagination': {
            'page': 1,
            'page_size': 20,
            'total': 1,
            'total_pages': 1,
          }
        });
        return http.Response(responseBody, 200);
      });

      final dataSource = FastApiFarmerRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final result = await dataSource.getFarmers(accessToken: 'test-token');
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Test Farmer');
      expect(result.pagination.totalRecords, 1);
    });

    test('getFarmerDetail returns item on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/farmers/f-100');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'f-100',
              'name': 'Detail Farmer',
              'phone': '9998887776',
              'status': 'active',
              'created_at': '2026-01-01T00:00:00Z',
            }
          }),
          200,
        );
      });

      final dataSource = FastApiFarmerRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final farmer = await dataSource.getFarmerDetail(
        accessToken: 'token',
        farmerId: 'f-100',
      );
      expect(farmer.id, 'f-100');
      expect(farmer.name, 'Detail Farmer');
    });

    test('setFarmerApproval sends PATCH and returns updated item', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/farmers/f-100/approval');
        final body = jsonDecode(request.body);
        expect(body['status'], 'active');

        return http.Response(
          jsonEncode({
            'data': {
              'id': 'f-100',
              'name': 'Approved Farmer',
              'phone': '9998887776',
              'status': 'active',
              'created_at': '2026-01-01T00:00:00Z',
            }
          }),
          200,
        );
      });

      final dataSource = FastApiFarmerRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final updated = await dataSource.setFarmerApproval(
        accessToken: 'token',
        farmerId: 'f-100',
        status: 'active',
      );
      expect(updated.status, 'active');
    });

    test('createFarmer sends POST and returns 201 created item', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/farmers');
        final body = jsonDecode(request.body);
        expect(body['name'], 'New Farmer');
        expect(body['phone'], '9876543210');
        expect(body['password'], 'Password123');

        return http.Response(
          jsonEncode({
            'data': {
              'id': 'f-created',
              'name': 'New Farmer',
              'phone': '9876543210',
              'status': 'pending',
              'created_at': '2026-01-01T00:00:00Z',
            }
          }),
          201,
        );
      });

      final dataSource = FastApiFarmerRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final created = await dataSource.createFarmer(
        accessToken: 'token',
        name: 'New Farmer',
        phone: '9876543210',
        password: 'Password123',
      );
      expect(created.id, 'f-created');
      expect(created.name, 'New Farmer');
    });

    test('HTTP Error Statuses throw appropriate FarmerException subclasses', () async {
      for (final code in [401, 403, 404, 409, 422, 500]) {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Error $code occurred'}),
            code,
          );
        });

        final dataSource = FastApiFarmerRemoteDataSource(
          baseUrl: 'https://test-api.agriflow.com',
          client: mockClient,
        );

        expect(
          () => dataSource.getFarmers(accessToken: 'test-token'),
          throwsA(predicate((e) {
            if (code == 401) return e is FarmerUnauthorizedException;
            if (code == 403) return e is FarmerForbiddenException;
            if (code == 404) return e is FarmerNotFoundException;
            if (code == 409) return e is FarmerConflictException;
            if (code == 422) return e is FarmerValidationException;
            return e is FarmerServerException;
          })),
        );
      }
    });
  });

  group('FarmerRepositoryImpl Tests', () {
    test('getFarmers updates farmer cache for lookup enrichment', () async {
      final mockDs = _MockFarmerRemoteDataSource();
      mockDs.farmersToReturn = [
        FarmerItem(
          id: 'f-1',
          name: 'Cached Ramulu',
          phone: '9876543210',
          status: 'active',
          createdAt: DateTime.now(),
          profile: const FarmerProfileItem(
            id: 'p-1',
            userId: 'f-1',
            address: 'Mothkur',
            acresOfLand: '5',
            bankStatus: 'approved',
          ),
        ),
      ];

      final repo = FarmerRepositoryImpl(remoteDataSource: mockDs);
      await repo.getFarmers(accessToken: 'token');

      final lookup = await repo.getFarmerLookup(accessToken: 'token');
      expect(lookup.containsKey('f-1'), isTrue);
      expect(lookup['f-1']!.name, 'Cached Ramulu');
      expect(lookup['f-1']!.village, 'Mothkur');
    });
  });

  group('FarmerController State Tests', () {
    late _MockFarmerRemoteDataSource mockDs;
    late FarmerRepository repo;
    late FarmerController controller;

    final sampleFarmer1 = FarmerItem(
      id: 'f-1',
      name: 'Farmer Active',
      phone: '9876543210',
      status: 'active',
      createdAt: DateTime.now(),
    );

    final sampleFarmer2 = FarmerItem(
      id: 'f-2',
      name: 'Farmer Pending',
      phone: '9123456780',
      status: 'pending',
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockDs = _MockFarmerRemoteDataSource();
      mockDs.farmersToReturn = [sampleFarmer1, sampleFarmer2];
      mockDs.paginationToReturn = const FarmerPagination(
        page: 1,
        pageSize: 20,
        totalRecords: 2,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      );
      repo = FarmerRepositoryImpl(remoteDataSource: mockDs);
      controller = FarmerController(repository: repo, accessToken: 'token');
    });

    test('loadFarmers sets state and calculates active/pending counts', () async {
      expect(controller.isLoading, isFalse);
      expect(controller.farmers, isEmpty);

      final loadFuture = controller.loadFarmers();
      expect(controller.isLoading, isTrue);

      await loadFuture;

      expect(controller.isLoading, isFalse);
      expect(controller.farmers.length, 2);
      expect(controller.activeCount, 1);
      expect(controller.pendingCount, 1);
      expect(controller.totalRecords, 2);
    });

    test('approveFarmer updates status in controller list', () async {
      await controller.loadFarmers();

      final success = await controller.approveFarmer('f-2');
      expect(success, isTrue);

      final f2 = controller.farmers.firstWhere((f) => f.id == 'f-2');
      expect(f2.status, 'active');
      expect(controller.activeCount, 2);
      expect(controller.pendingCount, 0);
    });

    test('rejectFarmer updates status to rejected', () async {
      await controller.loadFarmers();

      final success = await controller.rejectFarmer('f-2');
      expect(success, isTrue);

      final f2 = controller.farmers.firstWhere((f) => f.id == 'f-2');
      expect(f2.status, 'rejected');
    });

    test('suspendFarmer updates status to suspended', () async {
      await controller.loadFarmers();

      final success = await controller.suspendFarmer('f-1');
      expect(success, isTrue);

      final f1 = controller.farmers.firstWhere((f) => f.id == 'f-1');
      expect(f1.status, 'suspended');
    });

    test('createFarmer prepends newly created farmer to list', () async {
      await controller.loadFarmers();
      expect(controller.farmers.length, 2);

      final created = await controller.createFarmer(
        name: 'Brand New',
        phone: '9988776655',
        password: 'Password123',
      );

      expect(created, isNotNull);
      expect(controller.farmers.length, 3);
      expect(controller.farmers.first.name, 'Brand New');
      expect(controller.totalRecords, 3);
    });

    test('loadFarmers handles error correctly', () async {
      mockDs.errorToThrow = const FarmerServerException(message: 'Server error 500');

      await controller.loadFarmers();

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, 'Server error 500');
    });
  });

  group('Farmer Widget & Screen Tests', () {
    late _MockFarmerRemoteDataSource mockDs;
    late FarmerRepository repo;
    late FarmerController controller;

    final testFarmer = FarmerItem(
      id: 'f-test-1',
      name: 'Ramesh Patel',
      phone: '9876543210',
      status: 'pending',
      createdAt: DateTime(2026, 3, 20),
      profile: const FarmerProfileItem(
        id: 'p-1',
        userId: 'f-test-1',
        address: 'Adilabad Town',
        acresOfLand: '12.5',
        bankName: 'SBI',
        accountNumber: '999888',
        bankStatus: 'pending',
      ),
    );

    setUp(() {
      mockDs = _MockFarmerRemoteDataSource();
      mockDs.farmersToReturn = [testFarmer];
      repo = FarmerRepositoryImpl(remoteDataSource: mockDs);
      controller = FarmerController(repository: repo, accessToken: 'token');
    });

    testWidgets('FarmerCard renders farmer details and triggers tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: FarmerCard(
              farmer: testFarmer,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.textContaining('9876543210'), findsOneWidget);
      expect(find.textContaining('12.5 acres'), findsOneWidget);
      expect(find.text('RP'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      await tester.tap(find.byType(FarmerCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('FarmerDetailSheet renders correctly and invokes dialer & approval', (tester) async {
      String? dialedPhone;
      bool approved = false;

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: FarmerDetailSheet(
              farmer: testFarmer,
              isAdmin: true,
              onCallFarmer: (phone) => dialedPhone = phone,
              onApprove: () => approved = true,
              onReject: () {},
            ),
          ),
        ),
      );

      expect(find.text('FARMER PROFILE'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('12.5 acres'), findsOneWidget);

      // Call button
      final callBtn = find.textContaining('Call Ramesh');
      expect(callBtn, findsOneWidget);
      await tester.tap(callBtn);
      await tester.pump();
      expect(dialedPhone, '9876543210');

      // Approve button
      final approveBtn = find.text('Approve');
      expect(approveBtn, findsOneWidget);
      await tester.tap(approveBtn);
      await tester.pump();
      expect(approved, isTrue);
    });

    testWidgets('Manager does not see Suspend Farmer action in Detail Sheet', (tester) async {
      final activeFarmer = testFarmer.copyWith(status: 'active');

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: FarmerDetailSheet(
              farmer: activeFarmer,
              isAdmin: false, // Manager Role
              onSuspend: () {},
            ),
          ),
        ),
      );

      expect(find.text('Suspend Farmer Account'), findsNothing);
    });

    testWidgets('Admin sees Suspend Farmer action for Active Farmer in Detail Sheet', (tester) async {
      final activeFarmer = testFarmer.copyWith(status: 'active');
      bool suspended = false;

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: FarmerDetailSheet(
              farmer: activeFarmer,
              isAdmin: true, // Admin Role
              onSuspend: () => suspended = true,
            ),
          ),
        ),
      );

      final suspendBtn = find.text('Suspend Farmer Account');
      expect(suspendBtn, findsOneWidget);
      await tester.tap(suspendBtn);
      await tester.pump();
      expect(suspended, isTrue);
    });

    testWidgets('AddFarmerSheet validates required fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: AddFarmerSheet(
              onSubmit: ({
                required String name,
                required String phone,
                required String password,
                String? email,
                String? address,
                double? acresOfLand,
                String? cropAddress,
              }) async =>
                  true,
            ),
          ),
        ),
      );

      expect(find.text('REGISTER NEW FARMER'), findsOneWidget);

      await tester.tap(find.text('Register Farmer'));
      await tester.pump();

      expect(find.text('Please enter farmer full name'), findsOneWidget);
    });

    testWidgets('FarmerScreen renders Admin view with bank requests icon', (tester) async {
      await controller.loadFarmers();

      await tester.pumpWidget(
        _buildTestApp(
          FarmerScreen(
            controller: controller,
            onBack: () {},
            isManagerRole: false, // Admin
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GLOBAL FARMER DIRECTORY'), findsOneWidget);
      expect(find.text('All Farmers'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
    });

    testWidgets('FarmerScreen renders Manager view without bank requests icon', (tester) async {
      await controller.loadFarmers();

      await tester.pumpWidget(
        _buildTestApp(
          FarmerScreen(
            controller: controller,
            onBack: () {},
            isManagerRole: true, // Manager
          ),
        ),
      );
      await tester.pump();

      expect(find.text('FARMER DIRECTORY'), findsOneWidget);
      expect(find.text('All Farmers'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsNothing);
    });
  });

  group('Responsive Layout Tests (320x600, 360x800, 412x915)', () {
    late _MockFarmerRemoteDataSource mockDs;
    late FarmerRepository repo;
    late FarmerController controller;

    setUp(() {
      mockDs = _MockFarmerRemoteDataSource();
      mockDs.farmersToReturn = [
        FarmerItem(
          id: 'f-resp-1',
          name: 'Chandra Shekar Rao Very Long Farmer Name Test',
          phone: '9876543210',
          status: 'active',
          createdAt: DateTime.now(),
          profile: const FarmerProfileItem(
            id: 'p-1',
            userId: 'f-resp-1',
            acresOfLand: '15.5',
            bankStatus: 'approved',
          ),
        )
      ];
      repo = FarmerRepositoryImpl(remoteDataSource: mockDs);
      controller = FarmerController(repository: repo, accessToken: 'token');
    });

    for (final size in [
      const Size(320, 600), // Small Android
      const Size(360, 800), // Standard Android
      const Size(412, 915), // Large Android
    ]) {
      testWidgets('FarmerScreen renders at ${size.width}x${size.height} without overflow',
          (tester) async {
        await controller.loadFarmers();

        await tester.pumpWidget(
          _buildTestApp(
            FarmerScreen(
              controller: controller,
              onBack: () {},
            ),
            mediaSize: size,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('All Farmers'), findsOneWidget);
      });
    }
  });

  group('M6-D Farmer Fixes & FEAT-04 Profile Edit', () {
    late _MockFarmerRemoteDataSource mockDs;
    late FarmerRepositoryImpl repo;
    late FarmerController controller;

    final sampleBankJson = {
      'id': 'bcr-1',
      'farmer_id': 'f-1',
      'bank_name': 'HDFC Bank',
      'account_number': '987654321',
      'ifsc_code': 'HDFC0001234',
      'upi_id': null,
      'status': 'pending',
      'admin_notes': null,
      'requested_at': '2026-07-10T12:00:00Z',
    };

    setUp(() {
      mockDs = _MockFarmerRemoteDataSource();
      mockDs.farmersToReturn = [
        FarmerItem(
          id: 'f-1',
          name: 'Ramulu Naik',
          phone: '9876543210',
          status: 'pending',
          createdAt: DateTime(2026, 1, 1),
          profile: const FarmerProfileItem(
            id: 'p-1',
            userId: 'f-1',
            address: 'Warangal',
            acresOfLand: '5.0',
            bankStatus: 'pending',
            soilType: 'Red Loam',
          ),
        ),
      ];
      mockDs.paginationToReturn = const FarmerPagination(
        page: 1,
        pageSize: 20,
        totalRecords: 1,
        totalPages: 2,
        hasNext: true,
        hasPrevious: false,
      );
      repo = FarmerRepositoryImpl(remoteDataSource: mockDs);
      controller = FarmerController(repository: repo, accessToken: 'token');
    });

    test('loadMoreFarmers fetches page 2 and appends (rec 1 P0)', () async {
      mockDs.page2Items = [
        FarmerItem(
          id: 'f-2',
          name: 'Page Two Farmer',
          phone: '9111111111',
          status: 'active',
          createdAt: DateTime(2026, 1, 2),
        ),
      ];

      await controller.loadFarmers();
      expect(controller.farmers.length, 1);
      expect(controller.pagination.hasNext, isTrue);

      await controller.loadMoreFarmers();

      expect(controller.farmers.length, 2);
      expect(controller.farmers.last.id, 'f-2');
      expect(mockDs.getFarmersCallCount, 2);
      expect(controller.pagination.hasNext, isFalse);
    });

    test('loadFarmerDetail fetches detail and updates selection (rec 7)', () async {
      await controller.loadFarmers();
      controller.selectFarmer(controller.farmers.first);

      final detail = await controller.loadFarmerDetail('f-1');

      expect(detail, isNotNull);
      expect(mockDs.getDetailCallCount, 1);
      expect(controller.selectedFarmer?.id, 'f-1');
      expect(controller.isLoadingDetail, isFalse);
    });

    test('updateFarmerProfile succeeds and refreshes cached farmer (FEAT-04)',
        () async {
      await controller.loadFarmers();

      final ok = await controller.updateFarmerProfile(
        farmerId: 'f-1',
        name: 'Ramulu N',
        phone: '9876543211',
        acresOfLand: 7.5,
        soilType: 'Black Soil',
      );

      expect(ok, isTrue);
      expect(mockDs.updateProfileCallCount, 1);
      expect(mockDs.lastUpdatedName, 'Ramulu N');
      expect(mockDs.lastUpdatedPhone, '9876543211');
      expect(controller.farmers.first.name, 'Ramulu N');
      expect(controller.errorMessage, isNull);
      expect(controller.isSubmitting, isFalse);
    });

    test('updateFarmerProfile failure returns false and sets errorMessage',
        () async {
      await controller.loadFarmers();
      mockDs.errorToThrow = const FarmerServerException(message: 'Patch failed');

      final ok = await controller.updateFarmerProfile(farmerId: 'f-1', name: 'X Y');

      expect(ok, isFalse);
      expect(controller.errorMessage, 'Patch failed');
      expect(controller.isSubmitting, isFalse);
    });

    test('bank change requests paginate via loadMoreBankRequests (rec 9)',
        () async {
      mockDs.bankRequestsToReturn = [BankChangeRequestItem.fromJson(sampleBankJson)];
      mockDs.bankPage2Items = [
        BankChangeRequestItem.fromJson({...sampleBankJson, 'id': 'bcr-2'}),
      ];

      await controller.loadBankChangeRequests();
      expect(controller.bankRequests.length, 1);
      expect(controller.bankRequestsHasMore, isTrue);

      await controller.loadMoreBankRequests();

      expect(controller.bankRequests.length, 2);
      expect(controller.bankRequests.map((r) => r.id), contains('bcr-2'));
      expect(controller.bankRequestsHasMore, isFalse);
      expect(controller.isLoadingMoreBankRequests, isFalse);
    });

    test('getBankChangeRequests warms farmer lookup before enriching (rec 8)',
        () async {
      mockDs.bankRequestsToReturn = [BankChangeRequestItem.fromJson(sampleBankJson)];

      final result = await repo.getBankChangeRequests(accessToken: 'token');

      expect(mockDs.getFarmersCallCount, greaterThanOrEqualTo(1));
      expect(result.items.single.displayFarmerName, 'Ramulu Naik');
    });

    testWidgets('FarmerDetailSheet shows Edit Profile for admin and invokes callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: FarmerDetailSheet(
              farmer: FarmerItem(
                id: 'f-1',
                name: 'Ramulu Naik',
                phone: '9876543210',
                status: 'active',
                createdAt: DateTime(2026, 1, 1),
              ),
              isAdmin: true,
              onEdit: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('farmer_edit_profile_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('farmer_edit_profile_btn')));
      expect(tapped, isTrue);
    });

    testWidgets('FarmerDetailSheet hides Edit Profile in manager view',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: FarmerDetailSheet(
              farmer: FarmerItem(
                id: 'f-1',
                name: 'Ramulu Naik',
                phone: '9876543210',
                status: 'active',
                createdAt: DateTime(2026, 1, 1),
              ),
              isAdmin: false,
              onEdit: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('farmer_edit_profile_btn')), findsNothing);
    });

    testWidgets('BankChangeRequestsSheet renders errorMessage (rec 4)',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: BankChangeRequestsSheet(
              requests: const [],
              isLoading: false,
              errorMessage: 'Failed to load bank requests',
              onRefresh: () async {},
              onReview: ({
                required String requestId,
                required bool approve,
                String? adminNotes,
              }) async =>
                  true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('bank_requests_error')), findsOneWidget);
      expect(find.text('Failed to load bank requests'), findsOneWidget);
    });

    testWidgets(
        'EditFarmerProfileSheet validates phone, submits values and pops (FEAT-04)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? lastName;
      String? lastPhone;
      double? lastAcres;

      final farmer = FarmerItem(
        id: 'f-1',
        name: 'Ramulu Naik',
        phone: '9876543210',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        profile: const FarmerProfileItem(
          id: 'p-1',
          userId: 'f-1',
          address: 'Warangal',
          acresOfLand: '5.0',
          bankStatus: 'approved',
          soilType: 'Red Loam',
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open_edit_sheet'),
                onPressed: () => EditFarmerProfileSheet.show(
                  context: context,
                  farmer: farmer,
                  isSubmitting: false,
                  onSubmit: ({
                    required String name,
                    required String phone,
                    String? email,
                    String? address,
                    double? acresOfLand,
                    String? soilType,
                    String? irrigationType,
                    String? primaryCrop,
                    String? secondaryCrop,
                  }) async {
                    lastName = name;
                    lastPhone = phone;
                    lastAcres = acresOfLand;
                    return true;
                  },
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_edit_sheet')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_farmer_sheet')), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Ramulu Naik'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Warangal'), findsOneWidget);

      // Invalid phone blocks submission
      await tester.enterText(
        find.byKey(const Key('edit_farmer_phone_field')),
        '123',
      );
      await tester.ensureVisible(find.byKey(const Key('edit_farmer_submit_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_farmer_submit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid phone (8-20 digits)'), findsOneWidget);
      expect(find.byKey(const Key('edit_farmer_sheet')), findsOneWidget);

      // Valid phone submits and pops
      await tester.enterText(
        find.byKey(const Key('edit_farmer_phone_field')),
        '9123456789',
      );
      await tester.ensureVisible(find.byKey(const Key('edit_farmer_submit_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_farmer_submit_btn')));
      await tester.pumpAndSettle();

      expect(lastName, 'Ramulu Naik');
      expect(lastPhone, '9123456789');
      expect(lastAcres, 5.0);
      expect(find.byKey(const Key('edit_farmer_sheet')), findsNothing);
    });

    testWidgets('EditFarmerProfileSheet surfaces backend failure inline (rec 4)',
        (tester) async {
      final farmer = FarmerItem(
        id: 'f-1',
        name: 'Ramulu Naik',
        phone: '9876543210',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(
          mediaSize: const Size(800, 1000),
          Scaffold(
            body: EditFarmerProfileSheet(
              farmer: farmer,
              isSubmitting: false,
              onSubmit: ({
                required String name,
                required String phone,
                String? email,
                String? address,
                double? acresOfLand,
                String? soilType,
                String? irrigationType,
                String? primaryCrop,
                String? secondaryCrop,
              }) async =>
                  false,
              errorMessage: () => 'Phone already in use',
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('edit_farmer_submit_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_farmer_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_farmer_error')), findsOneWidget);
      expect(find.text('Phone already in use'), findsOneWidget);
    });

    testWidgets('Opening detail exercises GET /farmers/{id} and shows Edit (rec 7)',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          mediaSize: const Size(412, 915),
          FarmerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FarmerCard));
      await tester.pumpAndSettle();

      expect(mockDs.getDetailCallCount, greaterThanOrEqualTo(1));
      expect(find.byType(FarmerDetailSheet), findsOneWidget);
      expect(find.byKey(const Key('farmer_edit_profile_btn')), findsOneWidget);
    });

    testWidgets('Tapping Edit Profile opens the edit sheet (FEAT-04)',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          mediaSize: const Size(412, 915),
          FarmerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FarmerCard));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('farmer_edit_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('farmer_edit_profile_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_farmer_sheet')), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Tapping Call PM button or Phone card invokes phone handler with valid phone',
        (tester) async {
      String? calledPhone;
      final farmer = FarmerItem(
        id: 'f-1',
        name: 'PM Farmer 5029069',
        phone: '9895029069',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(
          mediaSize: const Size(412, 915),
          Scaffold(
            body: FarmerDetailSheet(
              farmer: farmer,
              isAdmin: true,
              onCallFarmer: (phone) => calledPhone = phone,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('farmer_call_btn')), findsOneWidget);
      expect(find.text('Call PM (9895029069)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('farmer_call_btn')));
      await tester.pumpAndSettle();
      expect(calledPhone, '9895029069');

      calledPhone = null;
      await tester.tap(find.text('PHONE'));
      await tester.pumpAndSettle();
      expect(calledPhone, '9895029069');
    });

    testWidgets('Farmer with empty phone disables call button safely',
        (tester) async {
      final farmer = FarmerItem(
        id: 'f-2',
        name: 'No Phone Farmer',
        phone: '',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(
          mediaSize: const Size(412, 915),
          Scaffold(
            body: FarmerDetailSheet(
              farmer: farmer,
              isAdmin: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(find.byKey(const Key('farmer_call_btn')));
      expect(btn.onPressed, isNull);
    });
  });
}
