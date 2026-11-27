import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/features/event_logs/data/datasources/event_log_remote_data_source.dart';
import 'package:agriflow_admin/features/event_logs/data/datasources/fast_api_event_log_remote_data_source.dart';
import 'package:agriflow_admin/features/event_logs/data/repositories/event_log_repository_impl.dart';
import 'package:agriflow_admin/features/event_logs/domain/entities/audit_log_item.dart';
import 'package:agriflow_admin/features/event_logs/domain/entities/audit_log_pagination.dart';
import 'package:agriflow_admin/features/event_logs/domain/entities/event_logs_exception.dart';
import 'package:agriflow_admin/features/event_logs/domain/repositories/event_log_repository.dart';
import 'package:agriflow_admin/features/event_logs/presentation/controllers/event_log_controller.dart';
import 'package:agriflow_admin/features/event_logs/presentation/screens/event_log_screen.dart';

// ---------------------------------------------------------------------------
// Mock Remote Data Source for Controller / Widget Testing
// ---------------------------------------------------------------------------

class _MockEventLogRemoteDataSource implements EventLogRemoteDataSource {
  List<AuditLogItem> logsToReturn = [];
  AuditLogPagination paginationToReturn = AuditLogPagination.empty();
  List<AuditLogItem> page2Items = [];
  Exception? errorToThrow;

  int getAuditLogsCallCount = 0;
  String? lastSearch;
  String? lastRole;

  @override
  Future<({
    List<AuditLogItem> items,
    AuditLogPagination pagination,
  })> getAuditLogs({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? role,
    String? sort,
    String? order,
  }) async {
    getAuditLogsCallCount++;
    lastSearch = search;
    lastRole = role;
    if (errorToThrow != null) throw errorToThrow!;

    if (page >= 2 && page2Items.isNotEmpty) {
      return (
        items: page2Items,
        pagination: paginationToReturn.copyWith(page: page, totalPages: 2),
      );
    }

    var filtered = List<AuditLogItem>.from(logsToReturn);
    if (role != null && role.isNotEmpty && role != 'all') {
      filtered = filtered
          .where((l) => (l.actorRole ?? '').toLowerCase() == role.toLowerCase())
          .toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where((l) =>
              l.action.toLowerCase().contains(q) ||
              (l.details ?? '').toLowerCase().contains(q) ||
              (l.entityType ?? '').toLowerCase().contains(q))
          .toList();
    }

    return (
      items: filtered,
      pagination: paginationToReturn.copyWith(total: filtered.length),
    );
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
  final sampleJson = {
    'id': 'log-1',
    'user_id': 'u-1',
    'action': 'manager.created',
    'entity_type': 'manager',
    'entity_id': 'm-1',
    'old_value': null,
    'new_value': {'name': 'Anil Kumar'},
    'details': 'Created manager Anil Kumar',
    'created_at': '2026-09-28T10:32:11Z',
  };

  final sampleLog = AuditLogItem.fromJson(sampleJson);

  group('AuditLog Domain Entity Tests', () {
    test('fromJson parses contract fields including object diffs', () {
      final item = AuditLogItem.fromJson(sampleJson);

      expect(item.id, 'log-1');
      expect(item.userId, 'u-1');
      expect(item.action, 'manager.created');
      expect(item.entityType, 'manager');
      expect(item.entityId, 'm-1');
      expect(item.oldValue, isNull);
      expect(item.newValue, {'name': 'Anil Kumar'});
      expect(item.details, 'Created manager Anil Kumar');
      expect(item.createdAt, '2026-09-28T10:32:11Z');
    });

    test('fromJson tolerates nulls and non-object diffs', () {
      final item = AuditLogItem.fromJson({
        'id': 'log-2',
        'user_id': null,
        'action': 'login',
        'entity_type': null,
        'entity_id': null,
        'old_value': 'not-an-object',
        'new_value': null,
        'details': null,
        'created_at': null,
      });

      expect(item.userId, isNull);
      expect(item.entityType, isNull);
      expect(item.oldValue, isNull);
      expect(item.details, isNull);
      expect(item.createdAt, '');
    });

    test('createdLabel formats ISO timestamps for display', () {
      expect(sampleLog.createdLabel, '28 Sep 2026, 10:32');
      expect(
        AuditLogItem.fromJson({
          ...sampleJson,
          'created_at': '2026-01-05T08:05:00Z',
        }).createdLabel,
        '05 Jan 2026, 08:05',
      );
    });

    test('AuditLogPagination.fromJson derives hasNext', () {
      final pagination = AuditLogPagination.fromJson({
        'page': 1,
        'page_size': 20,
        'total': 45,
        'total_pages': 3,
      });

      expect(pagination.total, 45);
      expect(pagination.hasNext, isTrue);
      expect(pagination.hasPrevious, isFalse);
    });
  });

  group('FastApiEventLogRemoteDataSource HTTP Tests', () {
    test('getAuditLogs sends list contract query params and parses',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/admin/audit-logs');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['page_size'], '20');
        expect(request.url.queryParameters['sort'], 'created_at');
        expect(request.url.queryParameters['order'], 'desc');
        expect(request.url.queryParameters['search'], 'manager');
        expect(request.headers['Authorization'], 'Bearer test-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [sampleJson],
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

      final ds = FastApiEventLogRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final result = await ds.getAuditLogs(
        accessToken: 'test-token',
        search: 'manager',
      );

      expect(result.items.length, 1);
      expect(result.items.first.action, 'manager.created');
      expect(result.pagination.total, 1);
    });

    test('HTTP error statuses throw typed EventLogsException subclasses',
        () async {
      for (final code in [401, 403, 500]) {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'detail': 'Error $code'}), code);
        });

        final ds = FastApiEventLogRemoteDataSource(
          baseUrl: 'https://test-api.agriflow.com',
          client: mockClient,
        );

        expect(
          () => ds.getAuditLogs(accessToken: 'token'),
          throwsA(predicate((e) {
            if (code == 401) return e is EventLogsUnauthorizedException;
            if (code == 403) return e is EventLogsForbiddenException;
            return e is EventLogsServerException;
          })),
        );
      }
    });
  });

  group('EventLogController State Tests', () {
    late _MockEventLogRemoteDataSource mockDs;
    late EventLogRepository repo;
    late EventLogController controller;

    setUp(() {
      mockDs = _MockEventLogRemoteDataSource();
      mockDs.logsToReturn = [
        sampleLog,
        AuditLogItem.fromJson({...sampleJson, 'id': 'log-2', 'action': 'login'}),
      ];
      mockDs.paginationToReturn = const AuditLogPagination(
        page: 1,
        pageSize: 20,
        total: 2,
        totalPages: 1,
      );
      repo = EventLogRepositoryImpl(remoteDataSource: mockDs);
      controller =
          EventLogController(repository: repo, accessToken: 'token');
    });

    test('loadLogs sets list and totalRecords', () async {
      expect(controller.isLoading, isFalse);

      final future = controller.loadLogs();
      expect(controller.isLoading, isTrue);
      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.logs.length, 2);
      expect(controller.totalRecords, 2);
      expect(controller.errorMessage, isNull);
    });

    test('loadMoreLogs appends page 2', () async {
      mockDs.paginationToReturn = const AuditLogPagination(
        page: 1,
        pageSize: 20,
        total: 3,
        totalPages: 2,
      );
      mockDs.page2Items = [
        AuditLogItem.fromJson({
          ...sampleJson,
          'id': 'log-3',
          'action': 'manager.suspended',
        }),
      ];

      await controller.loadLogs();
      expect(controller.logs.length, 2);
      expect(controller.pagination.hasNext, isTrue);

      await controller.loadMoreLogs();

      expect(controller.logs.length, 3);
      expect(controller.logs.last.id, 'log-3');
      expect(mockDs.getAuditLogsCallCount, 2);
      expect(controller.pagination.hasNext, isFalse);
    });

    test('setSearchQuery reloads page 1 with search term', () async {
      mockDs.logsToReturn = [
        sampleLog,
        AuditLogItem.fromJson({
          ...sampleJson,
          'id': 'log-2',
          'action': 'login',
          'entity_type': 'session',
          'details': 'User logged in',
        }),
      ];

      await controller.setSearchQuery('manager');

      expect(controller.searchQuery, 'manager');
      expect(mockDs.lastSearch, 'manager');
      expect(controller.logs.length, 1);
      expect(controller.logs.first.id, 'log-1');
    });

    test('loadLogs handles error correctly', () async {
      mockDs.errorToThrow =
          const EventLogsServerException(message: 'Log unavailable');

      await controller.loadLogs();

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, 'Log unavailable');
      expect(controller.logs, isEmpty);
    });
  });

  group('EventLog Widget Tests', () {
    late _MockEventLogRemoteDataSource mockDs;
    late EventLogRepository repo;
    late EventLogController controller;

    setUp(() {
      mockDs = _MockEventLogRemoteDataSource();
      mockDs.logsToReturn = [sampleLog];
      mockDs.paginationToReturn = const AuditLogPagination(
        page: 1,
        pageSize: 20,
        total: 1,
        totalPages: 1,
      );
      repo = EventLogRepositoryImpl(remoteDataSource: mockDs);
      controller =
          EventLogController(repository: repo, accessToken: 'token');
    });

    testWidgets('EventLogScreen renders audit entries', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          EventLogScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_log_screen')), findsOneWidget);
      expect(
        find.byKey(const Key('event_log_tile_log-1')),
        findsOneWidget,
      );
      expect(find.text('manager.created'), findsOneWidget);
      expect(find.text('Created manager Anil Kumar'), findsOneWidget);
      expect(find.text('manager'), findsOneWidget);
      expect(find.text('28 Sep 2026, 10:32'), findsOneWidget);
      expect(find.text('Event Logs · 1'), findsOneWidget);
    });

    testWidgets('EventLogScreen shows empty state when no logs',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockDs.logsToReturn = [];

      await tester.pumpWidget(
        _buildTestApp(
          EventLogScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No events found'), findsOneWidget);
      expect(
        find.byKey(const Key('event_log_tile_log-1')),
        findsNothing,
      );
    });

    testWidgets('Search field filters entries server-side', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockDs.logsToReturn = [
        sampleLog,
        AuditLogItem.fromJson({
          ...sampleJson,
          'id': 'log-9',
          'action': 'farmer.approved',
          'details': 'Approved farmer',
        }),
      ];
      mockDs.paginationToReturn = const AuditLogPagination(
        page: 1,
        pageSize: 20,
        total: 2,
        totalPages: 1,
      );

      await tester.pumpWidget(
        _buildTestApp(
          EventLogScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event_log_tile_log-1')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('event_log_search_field')),
        'farmer',
      );
      await tester.pumpAndSettle();

      expect(mockDs.lastSearch, 'farmer');
      expect(find.byKey(const Key('event_log_tile_log-1')), findsNothing);
      expect(find.byKey(const Key('event_log_tile_log-9')), findsOneWidget);

      // Clear returns to full list
      await tester.tap(find.byKey(const Key('event_log_search_clear_btn')));
      await tester.pumpAndSettle();

      expect(controller.searchQuery, '');
      expect(find.byKey(const Key('event_log_tile_log-1')), findsOneWidget);
    });

    testWidgets('Error state shows message and retry button', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockDs.errorToThrow =
          const EventLogsServerException(message: 'Log unavailable');

      await tester.pumpWidget(
        _buildTestApp(
          EventLogScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Log unavailable'), findsOneWidget);
      expect(find.byKey(const Key('event_log_retry_btn')), findsOneWidget);

      mockDs.errorToThrow = null;
      await tester.tap(find.byKey(const Key('event_log_retry_btn')));
      await tester.pumpAndSettle();

      expect(controller.logs.length, 1);
      expect(find.byKey(const Key('event_log_tile_log-1')), findsOneWidget);
    });

    testWidgets('EventLogScreen displays actor role chip and filters by manager/farmer',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize);

      mockDs.logsToReturn = [
        AuditLogItem.fromJson({
          ...sampleJson,
          'id': 'log-mgr',
          'actor_name': 'Suresh Manager',
          'actor_role': 'manager',
          'action': 'visit.create',
        }),
        AuditLogItem.fromJson({
          ...sampleJson,
          'id': 'log-frm',
          'actor_name': 'Ramesh Farmer',
          'actor_role': 'farmer',
          'action': 'seed_purchase.create',
        }),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          EventLogScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suresh Manager'), findsOneWidget);
      expect(find.text('Ramesh Farmer'), findsOneWidget);

      await tester.tap(find.byKey(const Key('event_log_role_farmer')));
      await tester.pumpAndSettle();

      expect(mockDs.lastRole, 'farmer');
      expect(find.text('Ramesh Farmer'), findsOneWidget);
      expect(find.text('Suresh Manager'), findsNothing);
    });
  });
}
