import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/features/managers/data/datasources/fast_api_manager_remote_data_source.dart';
import 'package:agriflow_admin/features/managers/data/datasources/manager_remote_data_source.dart';
import 'package:agriflow_admin/features/managers/data/repositories/manager_repository_impl.dart';
import 'package:agriflow_admin/features/managers/domain/entities/manager_item.dart';
import 'package:agriflow_admin/features/managers/domain/entities/manager_pagination.dart';
import 'package:agriflow_admin/features/managers/domain/entities/managers_exception.dart';
import 'package:agriflow_admin/features/managers/domain/repositories/manager_repository.dart';
import 'package:agriflow_admin/features/managers/presentation/controllers/manager_controller.dart';
import 'package:agriflow_admin/features/managers/presentation/screens/manager_screen.dart';
import 'package:agriflow_admin/features/managers/presentation/widgets/create_manager_sheet.dart';
import 'package:agriflow_admin/features/managers/presentation/widgets/manager_card.dart';
import 'package:agriflow_admin/features/managers/presentation/widgets/reset_password_sheet.dart';

// ---------------------------------------------------------------------------
// Mock Remote Data Source for Controller / Widget Testing
// ---------------------------------------------------------------------------

class _MockManagerRemoteDataSource implements ManagerRemoteDataSource {
  List<ManagerItem> managersToReturn = [];
  ManagerPagination paginationToReturn = ManagerPagination.empty();
  List<ManagerItem> page2Items = [];
  Exception? errorToThrow;
  String resetMessageToReturn = 'Password reset successfully.';

  int getManagersCallCount = 0;
  int createCallCount = 0;
  int statusCallCount = 0;
  int resetCallCount = 0;
  String? lastSearch;
  String? lastStatus;

  @override
  Future<({List<ManagerItem> items, ManagerPagination pagination})>
      getManagers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) async {
    getManagersCallCount++;
    lastSearch = search;
    lastStatus = status;
    if (errorToThrow != null) throw errorToThrow!;

    if (page >= 2 && page2Items.isNotEmpty) {
      return (
        items: page2Items,
        pagination: paginationToReturn.copyWith(page: page, hasNext: false),
      );
    }

    var filtered = List<ManagerItem>.from(managersToReturn);
    if (status != null && status != 'all') {
      filtered = filtered
          .where((m) => m.status.toLowerCase() == status.toLowerCase())
          .toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where(
              (m) => m.name.toLowerCase().contains(q) || m.phone.contains(q))
          .toList();
    }

    return (
      items: filtered,
      pagination: paginationToReturn.copyWith(totalRecords: filtered.length),
    );
  }

  @override
  Future<ManagerItem> createManager({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? assignedRegion,
    String? department,
  }) async {
    createCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    final created = ManagerItem(
      id: 'm-new-1',
      name: name,
      phone: phone,
      email: email,
      role: 'manager',
      status: 'active',
      assignedRegion: assignedRegion,
      department: department,
      createdAt: DateTime.now(),
    );
    managersToReturn.insert(0, created);
    return created;
  }

  @override
  Future<ManagerItem> updateManagerStatus({
    required String accessToken,
    required String managerId,
    required String status,
  }) async {
    statusCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    final index = managersToReturn.indexWhere((m) => m.id == managerId);
    if (index != -1) {
      final updated = managersToReturn[index].copyWith(status: status);
      managersToReturn[index] = updated;
      return updated;
    }
    return ManagerItem(
      id: managerId,
      name: 'Manager',
      phone: '9876543210',
      email: null,
      role: 'manager',
      status: status,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String> resetManagerPassword({
    required String accessToken,
    required String managerId,
    required String newPassword,
  }) async {
    resetCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return resetMessageToReturn;
  }
}

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

void main() {
  final sampleManager = ManagerItem(
    id: 'm-1',
    name: 'Anil Kumar',
    phone: '9876543210',
    email: 'anil@example.com',
    role: 'manager',
    status: 'active',
    assignedRegion: 'Kurnool',
    department: 'Procurement',
    createdAt: DateTime(2026, 1, 1),
  );

  final suspendedManager = ManagerItem(
    id: 'm-2',
    name: 'Sunita Devi',
    phone: '9123456780',
    email: null,
    role: 'manager',
    status: 'suspended',
    createdAt: DateTime(2026, 1, 2),
  );

  group('Manager Domain Entity Tests', () {
    test('ManagerItem.fromJson parses contract fields', () {
      final item = ManagerItem.fromJson({
        'id': 'm-9',
        'name': 'Ravi Singh',
        'phone': '9000000001',
        'email': 'ravi@example.com',
        'role': 'manager',
        'status': 'active',
        'assigned_region': 'Guntur',
        'department': 'Logistics',
        'created_at': '2026-03-05T10:00:00Z',
      });

      expect(item.id, 'm-9');
      expect(item.name, 'Ravi Singh');
      expect(item.role, 'manager');
      expect(item.status, 'active');
      expect(item.assignedRegion, 'Guntur');
      expect(item.department, 'Logistics');
      expect(item.isActive, isTrue);
      expect(item.isSuperAdmin, isFalse);
    });

    test('ManagerItem.fromJson defaults role/status and tolerates nulls', () {
      final item = ManagerItem.fromJson({
        'id': 'm-10',
        'name': 'No Mail',
        'phone': '9000000002',
        'created_at': 'bad-date',
      });

      expect(item.role, 'manager');
      expect(item.status, 'active');
      expect(item.email, isNull);
      expect(item.assignedRegion, isNull);
      expect(item.createdAt, DateTime(2026, 1, 1));
    });

    test('initials derives from name', () {
      expect(
        ManagerItem(
          id: 'x',
          name: 'Anil Kumar',
          phone: '1',
          email: null,
          role: 'manager',
          status: 'active',
          createdAt: DateTime(2026),
        ).initials,
        'AK',
      );
      expect(
        ManagerItem(
          id: 'x',
          name: 'Ravi',
          phone: '1',
          email: null,
          role: 'manager',
          status: 'active',
          createdAt: DateTime(2026),
        ).initials,
        'R',
      );
    });

    test('copyWith updates status without touching id', () {
      final updated = sampleManager.copyWith(status: 'suspended');
      expect(updated.id, sampleManager.id);
      expect(updated.status, 'suspended');
      expect(updated.isSuspended, isTrue);
    });

    test('ManagerPagination.fromJson derives hasNext from total_pages', () {
      final pagination = ManagerPagination.fromJson({
        'page': 1,
        'page_size': 20,
        'total': 35,
        'total_pages': 2,
      });

      expect(pagination.totalRecords, 35);
      expect(pagination.hasNext, isTrue);
      expect(pagination.hasPrevious, isFalse);
    });
  });

  group('FastApiManagerRemoteDataSource HTTP Tests', () {
    test('getManagers sends list contract query params and parses', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/managers');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['page_size'], '20');
        expect(request.url.queryParameters['sort'], 'created_at');
        expect(request.url.queryParameters['order'], 'desc');
        expect(request.url.queryParameters['search'], 'anil');
        expect(request.url.queryParameters['status'], 'active');
        expect(request.headers['Authorization'], 'Bearer test-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'm-1',
                'name': 'Anil Kumar',
                'phone': '9876543210',
                'email': null,
                'role': 'manager',
                'status': 'active',
                'assigned_region': null,
                'department': null,
                'created_at': '2026-01-01T00:00:00Z',
              }
            ],
            'pagination': {
              'page': 1,
              'page_size': 20,
              'total': 1,
              'total_pages': 1,
            },
          }),
          200,
        );
      });

      final ds = FastApiManagerRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final result = await ds.getManagers(
        accessToken: 'test-token',
        search: 'anil',
        status: 'active',
      );

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Anil Kumar');
      expect(result.pagination.totalRecords, 1);
    });

    test('createManager sends POST with role manager and parses 201',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/managers');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'New Manager');
        expect(body['phone'], '9876543210');
        expect(body['password'], 'Password123');
        expect(body['role'], 'manager');
        expect(body['email'], 'new@example.com');
        expect(body['assigned_region'], 'Kurnool');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'm-created',
              'name': 'New Manager',
              'phone': '9876543210',
              'email': 'new@example.com',
              'role': 'manager',
              'status': 'active',
              'assigned_region': 'Kurnool',
              'department': null,
              'created_at': '2026-01-01T00:00:00Z',
            },
          }),
          201,
        );
      });

      final ds = FastApiManagerRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final created = await ds.createManager(
        accessToken: 'token',
        name: 'New Manager',
        phone: '9876543210',
        password: 'Password123',
        email: 'new@example.com',
        assignedRegion: 'Kurnool',
      );

      expect(created.id, 'm-created');
      expect(created.role, 'manager');
    });

    test('updateManagerStatus sends PATCH to /status with body', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/managers/m-1/status');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], 'suspended');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'm-1',
              'name': 'Anil Kumar',
              'phone': '9876543210',
              'email': null,
              'role': 'manager',
              'status': 'suspended',
              'assigned_region': null,
              'department': null,
              'created_at': '2026-01-01T00:00:00Z',
            },
          }),
          200,
        );
      });

      final ds = FastApiManagerRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final updated = await ds.updateManagerStatus(
        accessToken: 'token',
        managerId: 'm-1',
        status: 'suspended',
      );

      expect(updated.status, 'suspended');
    });

    test('resetManagerPassword sends new_password and returns message',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/managers/m-1/reset-password');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['new_password'], 'NewPass123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Password reset successfully.',
          }),
          200,
        );
      });

      final ds = FastApiManagerRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final message = await ds.resetManagerPassword(
        accessToken: 'token',
        managerId: 'm-1',
        newPassword: 'NewPass123',
      );

      expect(message, 'Password reset successfully.');
    });

    test('HTTP error statuses throw typed ManagersException subclasses',
        () async {
      for (final code in [401, 403, 404, 422, 500]) {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'detail': 'Error $code'}), code);
        });

        final ds = FastApiManagerRemoteDataSource(
          baseUrl: 'https://test-api.agriflow.com',
          client: mockClient,
        );

        expect(
          () => ds.getManagers(accessToken: 'token'),
          throwsA(predicate((e) {
            if (code == 401) return e is ManagersUnauthorizedException;
            if (code == 403) return e is ManagersForbiddenException;
            if (code == 404) return e is ManagersNotFoundException;
            if (code == 422) return e is ManagersValidationException;
            return e is ManagersServerException;
          })),
        );
      }
    });
  });

  group('ManagerController State Tests', () {
    late _MockManagerRemoteDataSource mockDs;
    late ManagerRepository repo;
    late ManagerController controller;

    setUp(() {
      mockDs = _MockManagerRemoteDataSource();
      mockDs.managersToReturn = [sampleManager, suspendedManager];
      mockDs.paginationToReturn = const ManagerPagination(
        page: 1,
        pageSize: 20,
        totalRecords: 2,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      );
      repo = ManagerRepositoryImpl(remoteDataSource: mockDs);
      controller = ManagerController(repository: repo, accessToken: 'token');
    });

    test('loadManagers sets list and active/suspended counts', () async {
      expect(controller.isLoading, isFalse);

      final future = controller.loadManagers();
      expect(controller.isLoading, isTrue);
      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.managers.length, 2);
      expect(controller.activeCount, 1);
      expect(controller.suspendedCount, 1);
      expect(controller.totalRecords, 2);
    });

    test('loadMoreManagers appends page 2', () async {
      mockDs.paginationToReturn = const ManagerPagination(
        page: 1,
        pageSize: 20,
        totalRecords: 3,
        totalPages: 2,
        hasNext: true,
        hasPrevious: false,
      );
      mockDs.page2Items = [
        ManagerItem(
          id: 'm-3',
          name: 'Page Two Manager',
          phone: '9111111111',
          email: null,
          role: 'manager',
          status: 'active',
          createdAt: DateTime(2026, 1, 3),
        ),
      ];

      await controller.loadManagers();
      expect(controller.managers.length, 2);
      expect(controller.pagination.hasNext, isTrue);

      await controller.loadMoreManagers();

      expect(controller.managers.length, 3);
      expect(controller.managers.last.id, 'm-3');
      expect(mockDs.getManagersCallCount, 2);
      expect(controller.pagination.hasNext, isFalse);
    });

    test('setSearchQuery reloads page 1 with the search term', () async {
      await controller.setSearchQuery('anil');

      expect(controller.searchQuery, 'anil');
      expect(mockDs.lastSearch, 'anil');
      expect(controller.managers.length, 1);
      expect(controller.managers.first.name, 'Anil Kumar');
    });

    test('setStatusFilter reloads with status param', () async {
      await controller.setStatusFilter('suspended');

      expect(controller.statusFilter, 'suspended');
      expect(mockDs.lastStatus, 'suspended');
      expect(controller.managers.length, 1);
      expect(controller.managers.first.id, 'm-2');
    });

    test('createManager prepends and increments total', () async {
      await controller.loadManagers();
      expect(controller.managers.length, 2);

      final ok = await controller.createManager(
        name: 'Brand New',
        phone: '9988776655',
        password: 'Password123',
      );

      expect(ok, isTrue);
      expect(mockDs.createCallCount, 1);
      expect(controller.managers.length, 3);
      expect(controller.managers.first.name, 'Brand New');
      expect(controller.totalRecords, 3);
      expect(controller.errorMessage, isNull);
    });

    test('createManager failure returns false and sets errorMessage',
        () async {
      await controller.loadManagers();
      mockDs.errorToThrow =
          const ManagersServerException(message: 'Create failed');

      final ok = await controller.createManager(
        name: 'Doomed',
        phone: '9000000000',
        password: 'Password123',
      );

      expect(ok, isFalse);
      expect(controller.errorMessage, 'Create failed');
      expect(controller.isSubmitting, isFalse);
      expect(controller.managers.length, 2);
    });

    test('setManagerStatus updates the manager in the list', () async {
      await controller.loadManagers();

      final ok = await controller.setManagerStatus(
        managerId: 'm-1',
        status: 'suspended',
      );

      expect(ok, isTrue);
      expect(mockDs.statusCallCount, 1);
      final m1 = controller.managers.firstWhere((m) => m.id == 'm-1');
      expect(m1.status, 'suspended');
      expect(controller.suspendedCount, 2);
    });

    test('setManagerStatus failure keeps old state and sets errorMessage',
        () async {
      await controller.loadManagers();
      mockDs.errorToThrow =
          const ManagersForbiddenException(message: 'Not allowed');

      final ok = await controller.setManagerStatus(
        managerId: 'm-1',
        status: 'suspended',
      );

      expect(ok, isFalse);
      expect(controller.errorMessage, 'Not allowed');
      final m1 = controller.managers.firstWhere((m) => m.id == 'm-1');
      expect(m1.status, 'active');
    });

    test('resetManagerPassword returns backend message on success', () async {
      mockDs.resetMessageToReturn = 'Password reset successfully.';

      final message = await controller.resetManagerPassword(
        managerId: 'm-1',
        newPassword: 'NewPass123',
      );

      expect(message, 'Password reset successfully.');
      expect(mockDs.resetCallCount, 1);
      expect(controller.errorMessage, isNull);
      expect(controller.isSubmitting, isFalse);
    });

    test('resetManagerPassword failure returns null and sets errorMessage',
        () async {
      mockDs.errorToThrow = const ManagersServerException(message: 'Reset failed');

      final message = await controller.resetManagerPassword(
        managerId: 'm-1',
        newPassword: 'NewPass123',
      );

      expect(message, isNull);
      expect(controller.errorMessage, 'Reset failed');
    });

    test('loadManagers handles error correctly', () async {
      mockDs.errorToThrow =
          const ManagersServerException(message: 'Server error 500');

      await controller.loadManagers();

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, 'Server error 500');
      expect(controller.managers, isEmpty);
    });
  });

  group('Manager Widget Tests', () {
    late _MockManagerRemoteDataSource mockDs;
    late ManagerController controller;

    setUp(() {
      mockDs = _MockManagerRemoteDataSource();
      mockDs.managersToReturn = [sampleManager, suspendedManager];
      mockDs.paginationToReturn = const ManagerPagination(
        page: 1,
        pageSize: 20,
        totalRecords: 2,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      );
      controller = ManagerController(
        repository: ManagerRepositoryImpl(remoteDataSource: mockDs),
        accessToken: 'token',
      );
    });

    testWidgets('ManagerScreen renders cards, counters and filter chips',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          ManagerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manager_screen')), findsOneWidget);
      expect(find.byType(ManagerCard), findsNWidgets(2));
      expect(find.byKey(const Key('manager_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('manager_card_m-1')), findsOneWidget);
      expect(find.byKey(const Key('manager_card_m-2')), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('SUSPENDED'), findsOneWidget);
      expect(find.text('Anil Kumar'), findsOneWidget);
      expect(find.text('Sunita Devi'), findsOneWidget);
    });

    testWidgets('ManagerScreen shows empty state when no managers',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockDs.managersToReturn = [];

      await tester.pumpWidget(
        _buildTestApp(
          ManagerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No managers found'), findsOneWidget);
      expect(find.byType(ManagerCard), findsNothing);
    });

    testWidgets('Status chip filter triggers filtered reload', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          ManagerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ManagerCard), findsNWidgets(2));

      await tester.tap(find.byKey(const Key('manager_chip_suspended')));
      await tester.pumpAndSettle();

      expect(mockDs.lastStatus, 'suspended');
      expect(find.byType(ManagerCard), findsOneWidget);
      expect(find.text('Sunita Devi'), findsOneWidget);
    });

    testWidgets('Suspending a manager asks for confirmation and updates',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          ManagerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manager_status_btn_m-1')));
      await tester.pumpAndSettle();

      expect(find.text('Suspend manager'), findsOneWidget);
      expect(find.byKey(const Key('manager_status_confirm_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('manager_status_cancel_btn')));
      await tester.pumpAndSettle();
      expect(mockDs.statusCallCount, 0);

      await tester.tap(find.byKey(const Key('manager_status_btn_m-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manager_status_confirm_btn')));
      await tester.pumpAndSettle();

      expect(mockDs.statusCallCount, 1);
      expect(controller.managers.firstWhere((m) => m.id == 'm-1').status,
          'suspended');
      expect(find.text('Anil Kumar suspended.'), findsOneWidget);
    });

    testWidgets('Reset password sheet validates then succeeds',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          ManagerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manager_reset_pwd_btn_m-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reset_password_sheet')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('reset_password_sheet')),
          matching: find.text('Anil Kumar'),
        ),
        findsOneWidget,
      );

      // Short password + mismatch block submission
      await tester.enterText(
        find.byKey(const Key('reset_password_field')),
        'short',
      );
      await tester.enterText(
        find.byKey(const Key('reset_password_confirm_field')),
        'different',
      );
      await tester.ensureVisible(
          find.byKey(const Key('reset_password_submit_btn')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('reset_password_submit_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(find.byKey(const Key('reset_password_sheet')), findsOneWidget);

      // Valid matching passwords submit and pop with success snackbar
      await tester.enterText(
        find.byKey(const Key('reset_password_field')),
        'NewPass123',
      );
      await tester.enterText(
        find.byKey(const Key('reset_password_confirm_field')),
        'NewPass123',
      );
      await tester.ensureVisible(
          find.byKey(const Key('reset_password_submit_btn')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('reset_password_submit_btn')));
      await tester.pumpAndSettle();

      expect(mockDs.resetCallCount, 1);
      expect(find.byKey(const Key('reset_password_sheet')), findsNothing);
      expect(find.text('Password reset successfully.'), findsOneWidget);
    });

    testWidgets('Create manager sheet validates and creates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          ManagerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manager_create_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_manager_sheet')), findsOneWidget);

      // Empty submit shows all three validation messages
      await tester.ensureVisible(
          find.byKey(const Key('create_manager_submit_btn')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('create_manager_submit_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter manager full name'),
        findsOneWidget,
      );
      expect(find.text('Please enter mobile number'), findsOneWidget);
      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      expect(mockDs.createCallCount, 0);

      // Fill valid values and submit
      await tester.enterText(
        find.byKey(const Key('create_manager_name_field')),
        'Fresh Manager',
      );
      await tester.enterText(
        find.byKey(const Key('create_manager_phone_field')),
        '9876500001',
      );
      await tester.enterText(
        find.byKey(const Key('create_manager_password_field')),
        'Password123',
      );
      await tester.ensureVisible(
          find.byKey(const Key('create_manager_submit_btn')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('create_manager_submit_btn')));
      await tester.pumpAndSettle();

      expect(mockDs.createCallCount, 1);
      expect(find.byKey(const Key('create_manager_sheet')), findsNothing);
      expect(
        find.text('Manager account created successfully.'),
        findsOneWidget,
      );
      expect(controller.managers.first.name, 'Fresh Manager');
    });

    testWidgets('Create manager sheet surfaces backend failure inline',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          ManagerScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manager_create_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('create_manager_name_field')),
        'Fresh Manager',
      );
      await tester.enterText(
        find.byKey(const Key('create_manager_phone_field')),
        '9876500001',
      );
      await tester.enterText(
        find.byKey(const Key('create_manager_password_field')),
        'Password123',
      );

      mockDs.errorToThrow = const ManagersValidationException(
        message: 'Phone number already registered',
      );

      await tester.ensureVisible(
          find.byKey(const Key('create_manager_submit_btn')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('create_manager_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_manager_error')), findsOneWidget);
      // The same message also appears in the screen's error banner — assert
      // the inline copy inside the sheet specifically.
      expect(
        find.descendant(
          of: find.byKey(const Key('create_manager_sheet')),
          matching: find.text('Phone number already registered'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('create_manager_sheet')), findsOneWidget);
    });

    testWidgets('Sheet widgets render standalone for wiring sanity',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          mediaSize: const Size(800, 1000),
          Scaffold(
            body: CreateManagerSheet(
              onSubmit: ({
                required String name,
                required String phone,
                required String password,
                String? email,
                String? assignedRegion,
                String? department,
              }) async =>
                  false,
              errorMessage: () => 'Boom',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('create_manager_sheet')), findsOneWidget);

      // Fill valid values first — empty-field validation would otherwise
      // block submission before onSubmit can surface the getter message.
      await tester.enterText(
        find.byKey(const Key('create_manager_name_field')),
        'Wired Manager',
      );
      await tester.enterText(
        find.byKey(const Key('create_manager_phone_field')),
        '9876500002',
      );
      await tester.enterText(
        find.byKey(const Key('create_manager_password_field')),
        'Password123',
      );

      await tester.ensureVisible(
          find.byKey(const Key('create_manager_submit_btn')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('create_manager_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_manager_error')), findsOneWidget);
      expect(find.text('Boom'), findsOneWidget);
    });

    testWidgets('ResetPasswordSheet surfaces backend failure inline',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          mediaSize: const Size(800, 1000),
          Scaffold(
            body: ResetPasswordSheet(
              managerName: 'Test Manager',
              onSubmit: ({required String newPassword}) async => null,
              errorMessage: () => 'Reset rejected by backend',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('reset_password_sheet')), findsOneWidget);
      expect(find.text('Test Manager'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('reset_password_field')),
        'Password123',
      );
      await tester.enterText(
        find.byKey(const Key('reset_password_confirm_field')),
        'Password123',
      );
      await tester.ensureVisible(
          find.byKey(const Key('reset_password_submit_btn')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('reset_password_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reset_password_error')), findsOneWidget);
      expect(find.text('Reset rejected by backend'), findsOneWidget);
      expect(find.byKey(const Key('reset_password_sheet')), findsOneWidget);
    });
  });
}
