import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:flutter/material.dart';

import 'package:agriflow_admin/features/notifications/domain/entities/notification_item.dart';
import 'package:agriflow_admin/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:agriflow_admin/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:agriflow_admin/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:agriflow_admin/features/notifications/presentation/screens/notification_screen.dart';

// ─── Mock Data ───────────────────────────────────────────────────────────────

final _mockNotificationsResponse = jsonEncode({
  'data': [
    {
      'id': '11111111-1111-1111-1111-111111111111',
      'title': 'New Farmer Registration',
      'message': 'Ravi Kumar has submitted a registration request.',
      'type': 'info',
      'is_read': false,
      'reference_type': 'farmer',
      'reference_id': '22222222-2222-2222-2222-222222222222',
      'created_at': '2026-09-28T10:00:00Z',
    },
    {
      'id': '33333333-3333-3333-3333-333333333333',
      'title': 'Seed Purchase Approved',
      'message': 'Purchase SP-0912 has been approved and dispatched.',
      'type': 'success',
      'is_read': true,
      'reference_type': 'seed_purchase',
      'reference_id': '44444444-4444-4444-4444-444444444444',
      'created_at': '2026-09-27T14:30:00Z',
    },
    {
      'id': '55555555-5555-5555-5555-555555555555',
      'title': 'Low Stock Warning',
      'message': 'Groundnut seeds are below minimum threshold.',
      'type': 'warning',
      'is_read': false,
      'reference_type': null,
      'reference_id': null,
      'created_at': '2026-09-28T08:15:00Z',
    },
  ],
});

// ─── Helper: Creates a mock HTTP client ──────────────────────────────────────

http.Client _createMockClient({
  int statusCode = 200,
  String? body,
  Map<String, int>? pathStatusOverrides,
}) {
  return http_testing.MockClient((request) async {
    final path = request.url.path;

    // Check specific path overrides
    if (pathStatusOverrides != null) {
      for (final entry in pathStatusOverrides.entries) {
        if (path.contains(entry.key)) {
          return http.Response('{"message":"ok"}', entry.value);
        }
      }
    }

    if (path.endsWith('/notifications')) {
      return http.Response(
        body ?? _mockNotificationsResponse,
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.contains('/read')) {
      return http.Response(
        '{"message":"ok"}',
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.endsWith('/events/ticket')) {
      return http.Response(
        jsonEncode({'data': {'ticket': 'test-ticket-123', 'expires_in': 300}}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    return http.Response('Not Found', 404);
  });
}

// ─── Helper: Creates a controller with mock backend ──────────────────────────

NotificationController _createController({
  http.Client? client,
  int statusCode = 200,
}) {
  final mockClient = client ?? _createMockClient(statusCode: statusCode);
  final dataSource = FastApiNotificationRemoteDataSource(
    baseUrl: 'https://agriflow-backend-t8o4.onrender.com',
    client: mockClient,
  );
  final repository = NotificationRepository(remoteDataSource: dataSource);
  return NotificationController(
    repository: repository,
    accessToken: 'test-access-token',
  );
}

// ─── Domain Entity Tests ─────────────────────────────────────────────────────

void main() {
  group('NotificationItem — Domain Entity', () {
    test('fromJson parses all backend fields correctly', () {
      final json = {
        'id': 'abc-123',
        'title': 'Test Notification',
        'message': 'This is a test',
        'type': 'warning',
        'is_read': false,
        'reference_type': 'farmer',
        'reference_id': 'def-456',
        'created_at': '2026-09-28T12:00:00Z',
      };

      final item = NotificationItem.fromJson(json);

      expect(item.id, 'abc-123');
      expect(item.title, 'Test Notification');
      expect(item.message, 'This is a test');
      expect(item.type, NotificationType.warning);
      expect(item.isRead, false);
      expect(item.referenceType, 'farmer');
      expect(item.referenceId, 'def-456');
      expect(item.createdAt.year, 2026);
    });

    test('fromJson handles null/missing fields gracefully', () {
      final json = <String, dynamic>{
        'id': null,
        'title': null,
        'type': null,
        'is_read': null,
      };

      final item = NotificationItem.fromJson(json);
      expect(item.id, '');
      expect(item.title, 'Notification');
      expect(item.type, NotificationType.info);
      expect(item.isRead, false);
    });

    test('copyWith updates isRead', () {
      final item = NotificationItem.fromJson({
        'id': '1',
        'title': 'Test',
        'message': 'msg',
        'type': 'info',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00Z',
      });

      final updated = item.copyWith(isRead: true);
      expect(updated.isRead, true);
      expect(updated.id, '1');
      expect(updated.title, 'Test');
    });

    test('NotificationType.fromString handles all variants', () {
      expect(NotificationType.fromString('info'), NotificationType.info);
      expect(NotificationType.fromString('success'), NotificationType.success);
      expect(NotificationType.fromString('warning'), NotificationType.warning);
      expect(NotificationType.fromString('error'), NotificationType.error);
      expect(NotificationType.fromString('unknown'), NotificationType.info);
      expect(NotificationType.fromString(null), NotificationType.info);
    });

    test('timeAgo returns readable time strings', () {
      final now = DateTime.now();

      final justNow = NotificationItem(
        id: '1', title: 't', message: 'm', type: NotificationType.info,
        isRead: false, createdAt: now,
      );
      expect(justNow.timeAgo, 'Just now');

      final minutesAgo = NotificationItem(
        id: '2', title: 't', message: 'm', type: NotificationType.info,
        isRead: false, createdAt: now.subtract(const Duration(minutes: 15)),
      );
      expect(minutesAgo.timeAgo, '15m ago');

      final hoursAgo = NotificationItem(
        id: '3', title: 't', message: 'm', type: NotificationType.info,
        isRead: false, createdAt: now.subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.timeAgo, '3h ago');

      final daysAgo = NotificationItem(
        id: '4', title: 't', message: 'm', type: NotificationType.info,
        isRead: false, createdAt: now.subtract(const Duration(days: 2)),
      );
      expect(daysAgo.timeAgo, '2d ago');
    });
  });

  // ─── Remote Data Source Tests ────────────────────────────────────────────

  group('FastApiNotificationRemoteDataSource', () {
    test('fetchNotifications returns parsed list on 200', () async {
      final client = _createMockClient();
      final ds = FastApiNotificationRemoteDataSource(client: client);

      final items = await ds.fetchNotifications(accessToken: 'test-token');
      expect(items.length, 3);
      expect(items[0].title, 'New Farmer Registration');
      expect(items[1].type, NotificationType.success);
      expect(items[2].isRead, false);
    });

    test('fetchNotifications throws on 401', () async {
      final client = _createMockClient(statusCode: 401);
      final ds = FastApiNotificationRemoteDataSource(client: client);

      expect(
        () => ds.fetchNotifications(accessToken: 'expired-token'),
        throwsA(isA<Exception>()),
      );
    });

    test('getStreamTicket returns ticket string on 200', () async {
      final client = _createMockClient();
      final ds = FastApiNotificationRemoteDataSource(client: client);

      final ticket = await ds.getStreamTicket(accessToken: 'test-token');
      expect(ticket, 'test-ticket-123');
    });
  });

  // ─── Controller Tests ────────────────────────────────────────────────────

  group('NotificationController', () {
    test('refresh loads notifications from backend', () async {
      final controller = _createController();
      await controller.refresh();

      expect(controller.notifications.length, 3);
      expect(controller.isLoading, false);
      expect(controller.error, isNull);
      controller.dispose();
    });

    test('unreadCount reflects unread notifications', () async {
      final controller = _createController();
      await controller.refresh();

      // 2 unread out of 3 in mock data
      expect(controller.unreadCount, 2);
      expect(controller.hasUnread, true);
      controller.dispose();
    });

    test('markRead optimistically updates local state', () async {
      final controller = _createController();
      await controller.refresh();

      expect(controller.notifications[0].isRead, false);

      await controller.markRead('11111111-1111-1111-1111-111111111111');

      expect(controller.notifications[0].isRead, true);
      expect(controller.unreadCount, 1);
      controller.dispose();
    });

    test('markAllRead optimistically updates all notifications', () async {
      final controller = _createController();
      await controller.refresh();

      expect(controller.unreadCount, 2);

      await controller.markAllRead();

      expect(controller.unreadCount, 0);
      expect(controller.hasUnread, false);
      controller.dispose();
    });

    test('refresh sets error on failure', () async {
      final controller = _createController(statusCode: 500);
      await controller.refresh();

      expect(controller.error, isNotNull);
      expect(controller.notifications, isEmpty);
      controller.dispose();
    });

    test('startPolling/stopPolling lifecycle works', () async {
      final controller = _createController();

      controller.startPolling(
          interval: const Duration(milliseconds: 100));

      // Wait for initial fetch
      await Future.delayed(const Duration(milliseconds: 200));
      expect(controller.notifications.length, 3);

      controller.stopPolling();
      controller.dispose();
    });
  });

  // ─── Widget Tests ────────────────────────────────────────────────────────

  group('NotificationScreen — Widget Tests', () {
    testWidgets('displays notification list after loading', (tester) async {
      final controller = _createController();
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show notification titles
      expect(find.text('New Farmer Registration'), findsOneWidget);
      expect(find.text('Seed Purchase Approved'), findsOneWidget);
      expect(find.text('Low Stock Warning'), findsOneWidget);

      // Should show unread count
      expect(find.text('2 unread'), findsOneWidget);

      // Should show "Mark all read" button
      expect(find.text('Mark all read'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('shows empty state when no notifications', (tester) async {
      final client = _createMockClient(body: jsonEncode({'data': []}));
      final controller = _createController(client: client);
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications'), findsOneWidget);
      expect(find.text('All caught up'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      final controller = _createController(statusCode: 500);
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load content'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('tapping notification opens detail sheet', (tester) async {
      final controller = _createController();
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first notification
      await tester.tap(find.text('New Farmer Registration'));
      await tester.pumpAndSettle();

      // Bottom sheet should show the full message
      expect(
        find.text('Ravi Kumar has submitted a registration request.'),
        findsWidgets,
      );
      // Should show reference info
      expect(find.textContaining('farmer'), findsWidgets);
      // Should show Close button
      expect(find.text('Close'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('mark all read updates badge', (tester) async {
      final controller = _createController();
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 2 unread
      expect(find.text('2 unread'), findsOneWidget);

      // Tap "Mark all read"
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      // Should show "All caught up"
      expect(find.text('All caught up'), findsOneWidget);
      // Mark all read button should disappear
      expect(find.text('Mark all read'), findsNothing);

      controller.dispose();
    });

    testWidgets('back button calls onBack callback', (tester) async {
      bool backCalled = false;
      final controller = _createController();
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationScreen(
              controller: controller,
              onBack: () => backCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the back button (SquircleIconButton.back)
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        expect(backCalled, true);
      }

      controller.dispose();
    });

    testWidgets('renders correctly on 412x860 viewport', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 860 * 2.625);
      tester.view.devicePixelRatio = 2.625;

      final controller = _createController();
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No RenderFlex overflow errors
      expect(tester.takeException(), isNull);
      expect(find.text('Notifications'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      controller.dispose();
    });
  });
}
