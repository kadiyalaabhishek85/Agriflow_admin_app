import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/sse/notification_event_stream.dart';
import '../../domain/entities/notification_item.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../services/system_notification_service.dart';

/// Controller managing notification state with periodic polling and
/// real-time SSE updates.
///
/// Three update sources keep the badge/screen dynamic:
/// 1. Polls the backend every 30 seconds (matching the web app's refetch
///    interval) as a fallback.
/// 2. Subscribes to `GET /api/v1/events/stream` — the backend pushes
///    `notification.created` frames (verified live: <5s from event to frame).
/// 3. `handleAppResumed()` refreshes immediately when the app returns to the
///    foreground (timers are throttled while backgrounded).
///
/// Requests are routed through `ApiClient` (when the data source was built
/// with one) so the access token is read from storage and refreshed on 401 —
/// backend tokens expire after 900s, so a static token would otherwise freeze
/// polling silently after 15 minutes.
class NotificationController extends ChangeNotifier {
  final NotificationRepository repository;
  final String accessToken;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  bool _disposed = false;

  NotificationEventStream? _realtime;
  StreamSubscription<NotificationStreamEvent>? _realtimeSub;

  /// Android system popup layer. Null = in-app only (tests/showcase).
  final SystemNotificationService? systemNotifications;

  /// Backend notification ids already shown as a system popup this session —
  /// guarantees one backend id = one user-visible popup even if the same
  /// frame is ever delivered twice.
  final Set<String> _presentedPopupIds = <String>{};

  NotificationController({
    required this.repository,
    required this.accessToken,
    this.systemNotifications,
  });

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  /// Whether the real-time SSE channel is currently connected/running.
  bool get isRealtimeActive => _realtime?.isActive ?? false;

  /// Starts polling. Safe to call multiple times — only one timer runs.
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollingTimer?.cancel();
    // Initial fetch
    refresh();
    // Periodic refresh
    _pollingTimer = Timer.periodic(interval, (_) => refresh());
  }

  /// Stops polling.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Starts the real-time SSE subscription. Safe to call multiple times.
  void startRealtime() {
    if (_disposed) return;
    _realtime ??= NotificationEventStream(
      dataSource: repository.remoteDataSource,
      accessToken: accessToken,
    );
    _realtimeSub ??= _realtime!.events.listen(
      _onStreamEvent,
      onError: (Object _) {
        // Stream errors are handled internally (reconnect loop); polling
        // remains the fallback, so nothing to surface here.
      },
    );
    _realtime!.start();
  }

  /// Stops the real-time SSE subscription.
  void stopRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    _realtime?.stop();
  }

  /// Called when the app returns to the foreground: refresh immediately and
  /// revive the SSE connection in case the OS dropped it while backgrounded.
  void handleAppResumed() {
    if (_disposed) return;
    refresh();
    if (_realtime != null) {
      _realtime!.stop();
      _realtime!.start();
    }
  }

  void _onStreamEvent(NotificationStreamEvent event) {
    if (_disposed) return;

    if (event.type == 'notification.created') {
      final data = event.data;
      if (data == null || data['id'] == null) return;
      final incoming = NotificationItem.fromJson({
        ...data,
        // The push payload does not carry read state or a timestamp; the
        // immediate canonical refresh() below reconciles both fields.
        'is_read': data['is_read'] ?? false,
        'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
      });
      final exists = _notifications.any((n) => n.id == incoming.id);
      if (!exists) {
        _notifications = [incoming, ..._notifications];
        notifyListeners();
        // Android system popup for the real backend payload — shown in
        // foreground AND background (intentional: business events must be
        // seen immediately). Polling/resume refreshes never call this, so
        // they cannot duplicate a popup.
        final popup = systemNotifications;
        if (popup != null && _presentedPopupIds.add(incoming.id)) {
          unawaited(popup.show(item: incoming));
        }
        // Reconcile with the canonical list (read state, timestamp, order).
        unawaited(refresh());
      }
      // A duplicate frame is a no-op — the row is already present.
    } else if (event.type == 'dashboard.changed') {
      unawaited(refresh());
    }
  }

  /// Test-only entry point for simulating an inbound SSE frame.
  @visibleForTesting
  void debugOnStreamEvent(NotificationStreamEvent event) =>
      _onStreamEvent(event);

  /// Fetches notifications from the backend.
  Future<void> refresh() async {
    if (_disposed) return;

    // Don't show loading indicator for background refreshes
    final isFirstLoad = _notifications.isEmpty;
    if (isFirstLoad) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final items = await repository.fetchNotifications(
        accessToken: accessToken,
      );
      if (_disposed) return;
      _notifications = items;
      _error = null;
    } catch (e) {
      if (_disposed) return;
      // Only set error on first load failure
      if (isFirstLoad) {
        _error = e.toString().replaceAll('Exception: ', '');
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Marks a single notification as read, updates local state optimistically.
  Future<void> markRead(String notificationId) async {
    // Optimistic update
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }

    try {
      await repository.markRead(
        accessToken: accessToken,
        notificationId: notificationId,
      );
    } catch (_) {
      // Revert on failure
      if (idx >= 0 && !_disposed) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: false);
        notifyListeners();
      }
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllRead() async {
    // Optimistic update
    final previousState = List<NotificationItem>.from(_notifications);
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await repository.markAllRead(accessToken: accessToken);
    } catch (_) {
      // Revert on failure
      if (!_disposed) {
        _notifications = previousState;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    stopRealtime();
    _realtime?.dispose();
    _realtime = null;
    super.dispose();
  }
}
