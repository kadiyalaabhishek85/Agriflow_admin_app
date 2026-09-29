import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/core/navigation/nav_destination.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/admin/presentation/admin_shell.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/screens/booking_slot_screen.dart';
import 'package:agriflow_admin/features/manager/presentation/manager_shell.dart';
import 'package:agriflow_admin/features/notifications/domain/entities/notification_item.dart';
import 'package:agriflow_admin/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:agriflow_admin/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:agriflow_admin/features/notifications/data/sse/notification_event_stream.dart';
import 'package:agriflow_admin/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:agriflow_admin/features/notifications/presentation/screens/notification_screen.dart';
import 'package:agriflow_admin/features/notifications/presentation/services/system_notification_service.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/screens/seed_purchase_screen.dart';

/// Root-cause tests for the Android system-popup notification layer:
/// popup invocation (foreground SSE), duplicate suppression across
/// SSE/polling/resume, permission-safe behavior, tap deep-link routing
/// (Admin + Manager), cold-start launch resolution, fallback behavior,
/// and detail-sheet module open.

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _RecordingSystemNotificationService
    implements SystemNotificationService {
  bool initialized = false;
  bool permissionEnsured = false;
  bool enabled = true;
  String? launchId;
  void Function(String)? tapHandler;
  final List<NotificationItem> shown = [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> show({required NotificationItem item}) async {
    shown.add(item);
  }

  @override
  Future<bool> areNotificationsEnabled() async => enabled;

  @override
  Future<void> ensurePermissionRequested() async {
    permissionEnsured = true;
  }

  @override
  void setTapHandler(void Function(String notificationId) handler) {
    tapHandler = handler;
  }

  @override
  Future<String?> pendingLaunchNotificationId() async => launchId;
}

const _seedItemJson = {
  'id': 'notif-seed-1',
  'title': 'Seed purchase submitted',
  'message': 'Your purchase of 5 kg is pending confirmation.',
  'type': 'info',
  'is_read': false,
  'reference_type': 'seed_purchase',
  'reference_id': '67712172-a679-41e1-be34-c5b9db8cd4b0',
  'created_at': '2026-09-28T10:00:00Z',
};

const _bookingItemJson = {
  'id': 'notif-booking-1',
  'title': 'New warehouse booking',
  'message': 'Asha booked 250 kg at a warehouse slot.',
  'type': 'info',
  'is_read': false,
  'reference_type': 'booking_slot',
  'reference_id': '05e44876-2bc9-49c3-b875-595038e81939',
  'created_at': '2026-09-28T09:10:46Z',
};

http_testing.MockClient _listMockClient(List<Map<String, dynamic>> items) {
  return http_testing.MockClient((request) async {
    if (request.method == 'GET' &&
        request.url.path.endsWith('/notifications')) {
      return http.Response(
        jsonEncode({'data': items}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.method == 'PATCH') {
      return http.Response('{"message":"ok"}', 200,
          headers: {'content-type': 'application/json'});
    }
    return http.Response('{}', 404);
  });
}

NotificationController _controllerWithItems(
  List<Map<String, dynamic>> items, {
  SystemNotificationService? popup,
}) {
  return NotificationController(
    repository: NotificationRepository(
      remoteDataSource: FastApiNotificationRemoteDataSource(
        client: _listMockClient(items),
      ),
    ),
    accessToken: 'test-token',
    systemNotifications: popup,
  );
}

AuthSession _session(UserRole role) {
  return AuthSession(
    accessToken: 'test_access_token',
    refreshToken: 'test_refresh_token',
    user: AuthUser(
      id: 'usr_1',
      name: role.isAdmin ? 'Admin User' : 'Manager User',
      phone: '9876543210',
      role: role,
      email: role.isAdmin ? 'admin@x.in' : 'manager@x.in',
    ),
  );
}

/// Same viewport as the existing shell tests (412x860) — screens are
/// designed for phone dimensions.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 860);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationTapBridge.pendingNotificationId.value = null;
  });

  tearDown(() {
    NotificationTapBridge.pendingNotificationId.value = null;
  });

  // -------------------------------------------------------------------------
  // Destination resolver (Phase 15 — verified live reference types only)
  // -------------------------------------------------------------------------

  group('destination resolver (audit-backed reference types)', () {
    test('maps every live reference_type to its module route', () {
      expect(NotificationDestinationResolver.routeFor('seed_purchase'),
          'seed-purchase');
      expect(NotificationDestinationResolver.routeFor('booking_slot'),
          'booking-slot');
      expect(NotificationDestinationResolver.routeFor('farm_visit'),
          'farm-visits');
      expect(NotificationDestinationResolver.routeFor('grain_sale'),
          'grain-sales');
      expect(NotificationDestinationResolver.routeFor('transaction'),
          'billing');
      expect(NotificationDestinationResolver.routeFor('bank_change_request'),
          'all-farmers');
    });

    test('unknown or missing reference falls back to Notifications screen',
        () {
      expect(NotificationDestinationResolver.routeFor('not_a_real_type'),
          isNull);
      expect(NotificationDestinationResolver.routeFor(null), isNull);
      expect(NotificationDestinationResolver.routeFor(''), isNull);

      final unknown = NotificationItem.fromJson({
        ..._seedItemJson,
        'reference_type': 'not_a_real_type',
      });
      expect(
        NotificationDestinationResolver.resolveRoute(unknown, isAdmin: true),
        NavDestination.notifications.id,
      );
      final noRef = NotificationItem.fromJson({
        ..._seedItemJson,
        'reference_type': null,
      });
      expect(
        NotificationDestinationResolver.resolveRoute(noRef, isAdmin: false),
        NavDestination.notifications.id,
      );
    });

    test('no mapped destination is admin-only (role safety for both roles)',
        () {
      const types = [
        'seed_purchase',
        'booking_slot',
        'farm_visit',
        'grain_sale',
        'transaction',
        'bank_change_request',
      ];
      for (final type in types) {
        final route = NotificationDestinationResolver.routeFor(type)!;
        expect(NavDestination.fromId(route).adminOnly, isFalse,
            reason: '$type → $route must be accessible to Managers');
        final item = NotificationItem.fromJson({..._seedItemJson, 'reference_type': type});
        expect(
          NotificationDestinationResolver.resolveRoute(item, isAdmin: true),
          route,
        );
        expect(
          NotificationDestinationResolver.resolveRoute(item, isAdmin: false),
          route,
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // Popup invocation + duplicate suppression (Phase 5 / Phase 11)
  // -------------------------------------------------------------------------

  group('system popup from SSE (foreground path)', () {
    test(
        'notification.created shows exactly one popup with the real backend '
        'payload; polling/resume/duplicate frames never re-show',
        () async {
      final popup = _RecordingSystemNotificationService();
      final httpMock = http_testing.MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/notifications')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  ..._seedItemJson,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PATCH') {
          return http.Response('{"message":"ok"}', 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 404);
      });

      final controller = NotificationController(
        repository: NotificationRepository(
          remoteDataSource:
              FastApiNotificationRemoteDataSource(client: httpMock),
        ),
        accessToken: 'test-token',
        systemNotifications: popup,
      );
      await controller.refresh();
      expect(popup.shown, isEmpty); // polling refresh must NOT pop up

      controller.debugOnStreamEvent(const NotificationStreamEvent(
        type: 'notification.created',
        data: {
          'id': 'sse-1',
          'title': 'Payment processed',
          'message': 'A payment of 310.00 has been processed.',
          'type': 'success',
        },
      ));

      expect(popup.shown, hasLength(1));
      final shown = popup.shown.single;
      expect(shown.id, 'sse-1');
      expect(shown.title, 'Payment processed');
      expect(shown.message, 'A payment of 310.00 has been processed.');
      expect(shown.type, NotificationType.success);
      // Badge state updated alongside the popup.
      expect(controller.notifications.any((n) => n.id == 'sse-1'), isTrue);
      expect(controller.unreadCount, 2);

      // Duplicate SSE frame → no second popup.
      controller.debugOnStreamEvent(const NotificationStreamEvent(
        type: 'notification.created',
        data: {
          'id': 'sse-1',
          'title': 'Payment processed',
          'message': 'A payment of 310.00 has been processed.',
          'type': 'success',
        },
      ));
      expect(popup.shown, hasLength(1));

      // Polling refresh + resume refresh → no popup.
      await controller.refresh();
      controller.handleAppResumed();
      await pumpEventQueue();
      expect(popup.shown, hasLength(1));

      // dashboard.changed → refresh only, no popup.
      controller.debugOnStreamEvent(const NotificationStreamEvent(
        type: 'dashboard.changed',
        data: {'reason': 'seed_purchase.create'},
      ));
      await pumpEventQueue();
      expect(popup.shown, hasLength(1));

      controller.dispose();
    });

    test(
        'permission-denied / unsupported platform: real local service never '
        'throws and the in-app feed keeps working', () async {
      final service = LocalSystemNotificationService();
      await service.initialize();
      await service.ensurePermissionRequested();
      expect(await service.areNotificationsEnabled(), isFalse);
      expect(await service.pendingLaunchNotificationId(), isNull);
      service.setTapHandler((_) {});

      // Real service wired into the controller: ingestion unaffected even
      // when the platform channel is unavailable (permission off / no OS).
      final controller = _controllerWithItems(
        const [
          _seedItemJson,
        ],
        popup: service,
      );
      await controller.refresh();
      expect(controller.notifications, hasLength(1));

      controller.debugOnStreamEvent(const NotificationStreamEvent(
        type: 'notification.created',
        data: {
          'id': 'sse-perm-1',
          'title': 'Booking status updated',
          'message': 'Slot confirmed.',
          'type': 'success',
        },
      ));
      expect(controller.notifications.any((n) => n.id == 'sse-perm-1'), isTrue);
      expect(controller.unreadCount, 2);

      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Tap → module navigation, Admin + Manager (Phase 15)
  // -------------------------------------------------------------------------

  group('notification tap deep-link', () {
    testWidgets(
        'Admin: system-notification tap opens the Seed Purchase module '
        'and clears the pending id', (tester) async {
      _usePhoneViewport(tester);
      final popup = _RecordingSystemNotificationService();
      final controller =
          _controllerWithItems(const [_seedItemJson], popup: popup);

      await tester.pumpWidget(MaterialApp(
        home: AdminShell(
          session: _session(UserRole.admin),
          onLogout: () {},
          notificationController: controller,
          systemNotifications: popup,
        ),
      ));
      await tester.pumpAndSettle();

      expect(popup.initialized, isTrue);
      expect(popup.permissionEnsured, isTrue);
      expect(popup.tapHandler, isNotNull);

      NotificationTapBridge.pendingNotificationId.value = 'notif-seed-1';
      await tester.pumpAndSettle();

      expect(find.byType(SeedPurchaseScreen), findsOneWidget);
      expect(NotificationTapBridge.pendingNotificationId.value, isNull);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets(
        'Manager: system-notification tap opens the Booking Slot module '
        '(role-allowed destination)', (tester) async {
      _usePhoneViewport(tester);
      final popup = _RecordingSystemNotificationService();
      final controller =
          _controllerWithItems(const [_bookingItemJson], popup: popup);

      await tester.pumpWidget(MaterialApp(
        home: ManagerShell(
          session: _session(UserRole.manager),
          onLogout: () {},
          notificationController: controller,
          systemNotifications: popup,
        ),
      ));
      await tester.pumpAndSettle();

      expect(popup.permissionEnsured, isTrue);

      NotificationTapBridge.pendingNotificationId.value = 'notif-booking-1';
      await tester.pumpAndSettle();

      expect(find.byType(BookingSlotScreen), findsOneWidget);
      expect(NotificationTapBridge.pendingNotificationId.value, isNull);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets(
        'fallback: unknown/deleted notification id opens the '
        'Notifications screen (never an arbitrary record)', (tester) async {
      _usePhoneViewport(tester);
      final popup = _RecordingSystemNotificationService()
        ..launchId = 'ghost-notification-id';
      final controller =
          _controllerWithItems(const [_seedItemJson], popup: popup);

      await tester.pumpWidget(MaterialApp(
        home: AdminShell(
          session: _session(UserRole.admin),
          onLogout: () {},
          notificationController: controller,
          systemNotifications: popup,
        ),
      ));
      await tester.pumpAndSettle();

      // Cold-start launch id resolves: item not in canonical list →
      // Notifications screen fallback.
      expect(find.byType(NotificationScreen), findsOneWidget);
      expect(NotificationTapBridge.pendingNotificationId.value, isNull);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets(
        'cold-start: launch notification id resolves to its module after '
        'session/shell restoration', (tester) async {
      _usePhoneViewport(tester);
      final popup = _RecordingSystemNotificationService()
        ..launchId = 'notif-seed-1';
      final controller =
          _controllerWithItems(const [_seedItemJson], popup: popup);

      await tester.pumpWidget(MaterialApp(
        home: AdminShell(
          session: _session(UserRole.admin),
          onLogout: () {},
          notificationController: controller,
          systemNotifications: popup,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SeedPurchaseScreen), findsOneWidget);
      expect(NotificationTapBridge.pendingNotificationId.value, isNull);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets(
        'detail sheet: mapped reference shows Open action that routes '
        'through the tap bridge; unmapped reference shows none', (tester) async {
      _usePhoneViewport(tester);
      final controller = _controllerWithItems(const [_seedItemJson]);
      await controller.refresh();

      await tester.pumpWidget(MaterialApp(
        home: NotificationScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seed purchase submitted'));
      await tester.pumpAndSettle();

      expect(find.text('Open Seed Purchase'), findsOneWidget);
      await tester.tap(find.text('Open Seed Purchase'));
      await tester.pumpAndSettle();
      expect(NotificationTapBridge.pendingNotificationId.value,
          'notif-seed-1');
      NotificationTapBridge.pendingNotificationId.value = null;

      // Unmapped reference → no misleading Open action.
      final unmappedController = _controllerWithItems(const [
        {
          'id': 'notif-unmapped-1',
          'title': 'New warehouse booking',
          'message': 'Asha booked 250 kg at a warehouse slot.',
          'type': 'info',
          'is_read': false,
          'reference_type': 'warehouse_slot_of_mystery',
          'reference_id': '05e44876-2bc9-49c3-b875-595038e81939',
          'created_at': '2026-09-28T09:10:46Z',
        },
      ]);
      await unmappedController.refresh();
      await tester.pumpWidget(MaterialApp(
        home: NotificationScreen(controller: unmappedController),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New warehouse booking'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsOneWidget);
      expect(find.textContaining('Open '), findsNothing);
      expect(NotificationTapBridge.pendingNotificationId.value, isNull);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      unmappedController.dispose();
    });
  });
}
