import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/admin/presentation/admin_shell.dart';
import 'package:agriflow_admin/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/manager/presentation/manager_shell.dart';
import 'package:agriflow_admin/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:agriflow_admin/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:agriflow_admin/features/notifications/data/sse/notification_event_stream.dart';
import 'package:agriflow_admin/features/notifications/presentation/controllers/notification_controller.dart';

/// Root-cause fix tests for the Admin/Manager notification investigation:
/// - Group "token freshness" proves the D/H fix (static token captured at
///   shell startup is no longer used; 401 triggers a silent refresh + retry).
/// - Group "SSE frame parser" proves the M fix input contract.
/// - Group "event stream" proves the app now consumes GET /events/stream.
/// - Group "controller realtime" proves pushed frames reach badge state.
/// - Group "lifecycle" proves resume triggers an immediate refresh.

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeLocalDataSource implements AuthLocalDataSource {
  String? access;
  String? refresh;
  bool remember = true;
  bool cleared = false;

  _FakeLocalDataSource({this.access, this.refresh});

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<bool> isRemembered() async => remember;

  @override
  Future<void> saveSession(AuthSession session, {bool rememberMe = true}) async {
    access = session.accessToken;
    refresh = session.refreshToken;
    remember = rememberMe;
  }

  @override
  Future<AuthSession?> getSession() async => null;

  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> updateUser(AuthUser user) async {}

  @override
  Future<void> clearSession() async {
    cleared = true;
    access = null;
    refresh = null;
  }
}

const _oneNotificationJson = '{"data":['
    '{"id":"n-1","title":"Seed purchase submitted","message":"New request",'
    '"type":"info","is_read":false,"created_at":"2026-09-28T10:00:00Z"}]}';

http.Client _notificationsMockClient({
  required List<String> recordedAuthHeaders,
  int Function()? refreshResponderStatus,
  void Function()? onRefreshCalled,
}) {
  return http_testing.MockClient((request) async {
    final path = request.url.path;

    if (path.endsWith('/auth/refresh')) {
      onRefreshCalled?.call();
      final status = refreshResponderStatus?.call() ?? 200;
      if (status != 200) {
        return http.Response('{"detail":"invalid refresh token"}', status,
            headers: {'content-type': 'application/json'});
      }
      return http.Response(
        jsonEncode({
          'data': {
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
            'token_type': 'bearer',
            'expires_in': 900,
            'user': {
              'id': 'u1',
              'name': 'Super Admin',
              'phone': '9999900000',
              'role': 'super_admin',
              'status': 'active',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.endsWith('/notifications')) {
      final auth = request.headers['authorization'] ?? '';
      recordedAuthHeaders.add(auth);
      // The stored token is EXPIRED — only the freshly rotated one works.
      if (auth == 'Bearer new-access') {
        return http.Response(_oneNotificationJson, 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('{"detail":"Invalid or expired token"}', 401,
          headers: {'content-type': 'application/json'});
    }

    if (path.endsWith('/events/ticket')) {
      final auth = request.headers['authorization'] ?? '';
      recordedAuthHeaders.add(auth);
      if (auth == 'Bearer new-access' || auth == 'Bearer stored-access') {
        return http.Response(
          jsonEncode({
            'data': {'ticket': 'tk-1', 'expires_in': 30},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"detail":"Invalid or expired token"}', 401,
          headers: {'content-type': 'application/json'});
    }

    return http.Response('{}', 404);
  });
}

// ---------------------------------------------------------------------------
// Group 1 — SSE frame parser (M-fix input contract)
// ---------------------------------------------------------------------------

void main() {
  group('SSE frame parser (live contract)', () {
    test('parses notification.created frame with JSON payload', () {
      final parser = SseFrameParser();
      final events = parser.feed(
        'event: notification.created\n'
        'data: {"id":"n1","title":"T","message":"M","type":"info"}\n\n',
      );
      expect(events, hasLength(1));
      expect(events.first.type, 'notification.created');
      expect(events.first.data?['id'], 'n1');
    });

    test('ignores :connected and :keepalive comment frames', () {
      final parser = SseFrameParser();
      final events = parser.feed(': connected\n\n: keepalive\n\n');
      expect(events, isEmpty);
    });

    test('emits nothing until the frame boundary arrives (split chunks)', () {
      final parser = SseFrameParser();
      expect(parser.feed('event: notification.created\ndata: {"id":'),
          isEmpty);
      expect(parser.feed('"n2"}\n'), isEmpty);
      final events = parser.feed('\n');
      expect(events, hasLength(1));
      expect(events.first.data?['id'], 'n2');
    });

    test('parses dashboard.changed frame (reason field)', () {
      final parser = SseFrameParser();
      final events = parser.feed(
        'event: dashboard.changed\n'
        'data: {"reason": "seed_purchase.create"}\n\n',
      );
      expect(events, hasLength(1));
      expect(events.first.type, 'dashboard.changed');
      expect(events.first.data?['reason'], 'seed_purchase.create');
    });

    test('processes multiple frames and keeps only named events', () {
      final parser = SseFrameParser();
      final events = parser.feed(
        ': keepalive\n\n'
        'event: notification.created\ndata: {"id":"a"}\n\n'
        'data: orphan-without-event\n\n'
        'event: dashboard.changed\ndata: {"reason":"x"}\n\n',
      );
      expect(events.map((e) => e.type), [
        'notification.created',
        'dashboard.changed',
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // Group 2 — Token freshness (D/H fix: fresh token + 401 refresh + retry)
  // -------------------------------------------------------------------------

  group('token freshness (root cause D/H fix)', () {
    test(
        'notification GET reads token from storage at request time, '
        'refreshes on 401 and retries once', () async {
      final local = _FakeLocalDataSource(
        access: 'stored-access',
        refresh: 'stored-refresh',
      );
      final recorded = <String>[];
      var refreshCalls = 0;
      final httpMock = _notificationsMockClient(
        recordedAuthHeaders: recorded,
        onRefreshCalled: () => refreshCalls++,
      );

      final ds = FastApiNotificationRemoteDataSource(
        apiClient: ApiClient(localDataSource: local, httpClient: httpMock),
      );

      // Pass a deliberately STALE startup-captured token — it must be ignored.
      final items =
          await ds.fetchNotifications(accessToken: 'stale-startup-token');

      expect(items, hasLength(1));
      expect(items.first.id, 'n-1');
      // First attempt: token freshly read from storage (not the stale arg),
      // 401 → refresh → second attempt with the rotated token.
      expect(recorded, ['Bearer stored-access', 'Bearer new-access']);
      expect(refreshCalls, 1);
      expect(local.access, 'new-access');
      expect(local.refresh, 'new-refresh');
    });

    test('stream ticket request also uses the freshly stored token', () async {
      final local = _FakeLocalDataSource(
        access: 'stored-access',
        refresh: 'stored-refresh',
      );
      final recorded = <String>[];
      final httpMock = _notificationsMockClient(
        recordedAuthHeaders: recorded,
      );
      final ds = FastApiNotificationRemoteDataSource(
        apiClient: ApiClient(localDataSource: local, httpClient: httpMock),
      );

      final ticket = await ds.getStreamTicket(accessToken: 'stale-token');
      expect(ticket, 'tk-1');
      expect(recorded, ['Bearer stored-access']);
    });

    test(
        'expired refresh token clears storage, fires onSessionExpired '
        'and surfaces AuthException', () async {
      final local = _FakeLocalDataSource(
        access: 'expired-access',
        refresh: 'expired-refresh',
      );
      final recorded = <String>[];
      var sessionExpired = false;
      final httpMock = _notificationsMockClient(
        recordedAuthHeaders: recorded,
        refreshResponderStatus: () => 401,
      );

      final ds = FastApiNotificationRemoteDataSource(
        apiClient: ApiClient(
          localDataSource: local,
          httpClient: httpMock,
          onSessionExpired: () => sessionExpired = true,
        ),
      );

      await expectLater(
        ds.fetchNotifications(accessToken: 'anything'),
        throwsA(isA<AuthException>()),
      );
      expect(sessionExpired, isTrue);
      expect(local.cleared, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Group 3 — Event stream consumption (M fix)
  // -------------------------------------------------------------------------

  group('event stream (root cause M fix)', () {
    test(
        'obtains a ticket, opens GET /events/stream and emits only '
        'real events (keepalives ignored); stop() ends it cleanly', () async {
      var streamGets = 0;
      String? ticketAuthHeader;
      String? streamTicketParam;
      var streamHadAuthHeader = false;
      final httpMock = http_testing.MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path.endsWith('/events/ticket')) {
          ticketAuthHeader = request.headers['authorization'];
          return http.Response(
            jsonEncode({
              'data': {'ticket': 'tk-9', 'expires_in': 30},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.endsWith('/events/stream')) {
          streamGets++;
          streamTicketParam = request.url.queryParameters['ticket'];
          streamHadAuthHeader = request.headers.containsKey('authorization');
          if (streamGets == 1) {
            return http.Response(
              ': connected\n\n'
              ': keepalive\n\n'
              'event: notification.created\n'
              'data: {"id":"n-live","title":"Seed purchase submitted",'
              '"message":"m","type":"info"}\n\n'
              'event: dashboard.changed\n'
              'data: {"reason": "seed_purchase.create"}\n\n',
              200,
              headers: {'content-type': 'text/event-stream'},
            );
          }
          return http.Response('closed', 500);
        }
        return http.Response('{}', 404);
      });

      final ds = FastApiNotificationRemoteDataSource(client: httpMock);
      final stream = NotificationEventStream(
        dataSource: ds,
        accessToken: 'static-token',
        client: httpMock,
        reconnectDelay: const Duration(seconds: 1),
      );

      final received = <NotificationStreamEvent>[];
      final sub = stream.events.listen(received.add);
      stream.start();
      expect(stream.isActive, isTrue);

      await pumpEventQueue();
      await pumpEventQueue();

      // Ticket was fetched with the static token (legacy data-source path).
      expect(ticketAuthHeader, 'Bearer static-token');
      // The stream itself carries the ticket, not an Authorization header
      // (verified live against the backend).
      expect(streamTicketParam, 'tk-9');
      expect(streamHadAuthHeader, isFalse);

      final created =
          received.where((e) => e.type == 'notification.created').toList();
      expect(created, hasLength(1));
      expect(created.first.data?['id'], 'n-live');
      expect(received.where((e) => e.type == 'dashboard.changed'), hasLength(1));

      stream.stop();
      expect(stream.isActive, isFalse);
      await stream.dispose();
      await sub.cancel();
    });

    test('repeated start/stop cycles never leave the stream active', () async {
      final httpMock = http_testing.MockClient((request) async {
        if (request.url.path.endsWith('/events/ticket')) {
          return http.Response(
            jsonEncode({
              'data': {'ticket': 't', 'expires_in': 30},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('down', 503);
      });

      final stream = NotificationEventStream(
        dataSource: FastApiNotificationRemoteDataSource(client: httpMock),
        accessToken: 'tok',
        client: httpMock,
      );
      stream.start();
      stream.stop();
      stream.start();
      stream.stop();
      expect(stream.isActive, isFalse);
      await stream.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Group 4 — Controller realtime + resume
  // -------------------------------------------------------------------------

  group('controller realtime (pushed frames reach badge state)', () {
    test(
        'notification.created inserts the item, dedupes repeats, '
        'then reconciles with a canonical refresh', () async {
      var getCount = 0;
      final httpMock = http_testing.MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/notifications')) {
          getCount++;
          // Canonical list before the push lacks the pushed row; the
          // post-push reconcile includes it (backend persisted it).
          final data = getCount == 1
              ? [
                  {
                    'id': 'n-old',
                    'title': 'Old',
                    'message': 'm',
                    'type': 'info',
                    'is_read': false,
                    'created_at': '2026-09-28T09:00:00Z',
                  },
                ]
              : [
                  {
                    'id': 'n-live',
                    'title': 'Seed purchase submitted',
                    'message': 'm',
                    'type': 'info',
                    'is_read': false,
                    'created_at': '2026-09-28T10:05:00Z',
                  },
                  {
                    'id': 'n-old',
                    'title': 'Old',
                    'message': 'm',
                    'type': 'info',
                    'is_read': false,
                    'created_at': '2026-09-28T09:00:00Z',
                  },
                ];
          return http.Response(
            jsonEncode({'data': data}),
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
          remoteDataSource: FastApiNotificationRemoteDataSource(client: httpMock),
        ),
        accessToken: 'static-token',
      );

      await controller.refresh();
      expect(controller.notifications, hasLength(1)); // pre-push canonical list
      expect(controller.unreadCount, 1);

      var notified = 0;
      controller.addListener(() => notified++);

      // Pushed SSE frame — payload has NO is_read/created_at (verified live).
      controller.debugOnStreamEvent(const NotificationStreamEvent(
        type: 'notification.created',
        data: {'id': 'n-live', 'title': 'Seed purchase submitted', 'message': 'm', 'type': 'info'},
      ));
      expect(controller.notifications, hasLength(2));
      expect(controller.notifications.first.id, 'n-live');
      expect(controller.notifications.first.isRead, isFalse);
      expect(controller.unreadCount, 2);
      expect(notified, 1);

      // Duplicate push must not duplicate the row.
      controller.debugOnStreamEvent(const NotificationStreamEvent(
        type: 'notification.created',
        data: {'id': 'n-live', 'title': 'Seed purchase submitted', 'message': 'm', 'type': 'info'},
      ));
      expect(controller.notifications, hasLength(2));

      // Canonical refresh reconciles (no phantom rows after it lands).
      final getBefore = getCount;
      await pumpEventQueue();
      expect(getCount, getBefore + 1);
      expect(controller.notifications, hasLength(2));
      expect(controller.unreadCount, 2);

      // Frames without an id are ignored.
      controller.debugOnStreamEvent(const NotificationStreamEvent(
        type: 'notification.created',
        data: {'title': 'no id'},
      ));
      expect(controller.notifications, hasLength(2));

      await controller.markAllRead();
      expect(controller.unreadCount, 0);

      controller.dispose();
    });

    test('dashboard.changed frame triggers a refresh', () async {
      var getCount = 0;
      final httpMock = http_testing.MockClient((request) async {
        if (request.url.path.endsWith('/notifications')) {
          getCount++;
          return http.Response('{"data":[]}', 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 404);
      });

      final controller = NotificationController(
        repository: NotificationRepository(
          remoteDataSource: FastApiNotificationRemoteDataSource(client: httpMock),
        ),
        accessToken: 'static-token',
      );
      await controller.refresh();
      expect(getCount, 1);

      controller.debugOnStreamEvent(const NotificationStreamEvent(
        type: 'dashboard.changed',
        data: {'reason': 'seed_purchase.create'},
      ));
      await pumpEventQueue();
      expect(getCount, 2);

      controller.dispose();
    });

    test('handleAppResumed refreshes immediately (no timer wait)', () async {
      var getCount = 0;
      final httpMock = http_testing.MockClient((request) async {
        if (request.url.path.endsWith('/notifications')) {
          getCount++;
          return http.Response('{"data":[]}', 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 404);
      });

      final controller = NotificationController(
        repository: NotificationRepository(
          remoteDataSource: FastApiNotificationRemoteDataSource(client: httpMock),
        ),
        accessToken: 'static-token',
      );
      await controller.refresh();
      expect(getCount, 1);

      // Resume without a prior startRealtime() must not throw.
      controller.handleAppResumed();
      await pumpEventQueue();
      expect(getCount, 2);

      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Group 5 — Shell lifecycle wiring (F fix) (widget)
  // -------------------------------------------------------------------------

  group('shell lifecycle wiring (root cause F fix)', () {
    testWidgets('AdminShell starts realtime and refreshes on resume',
        (tester) async {
      final spy = _SpyNotificationController();
      await tester.pumpWidget(MaterialApp(
        home: AdminShell(
          session: _createSession(UserRole.admin),
          onLogout: () {},
          notificationController: spy,
        ),
      ));

      expect(spy.pollingStarted, isTrue);
      expect(spy.realtimeStarted, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(spy.resumeCalls, 1);

      await tester.pumpWidget(const SizedBox());
      spy.dispose();
    });

    testWidgets('ManagerShell starts realtime and refreshes on resume',
        (tester) async {
      final spy = _SpyNotificationController();
      await tester.pumpWidget(MaterialApp(
        home: ManagerShell(
          session: _createSession(UserRole.manager),
          onLogout: () {},
          notificationController: spy,
        ),
      ));

      expect(spy.pollingStarted, isTrue);
      expect(spy.realtimeStarted, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(spy.resumeCalls, 1);

      await tester.pumpWidget(const SizedBox());
      spy.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _SpyNotificationController extends NotificationController {
  bool pollingStarted = false;
  bool realtimeStarted = false;
  int resumeCalls = 0;

  _SpyNotificationController()
      : super(
          repository: NotificationRepository(
            remoteDataSource: FastApiNotificationRemoteDataSource(
              client: http_testing.MockClient((_) async => http.Response(
                  '{"data":[]}',
                  200,
                  headers: {'content-type': 'application/json'})),
            ),
          ),
          accessToken: 'spy-token',
        );

  @override
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    pollingStarted = true;
  }

  @override
  void startRealtime() {
    realtimeStarted = true;
  }

  @override
  void handleAppResumed() {
    resumeCalls++;
  }
}

AuthSession _createSession(UserRole role) {
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
