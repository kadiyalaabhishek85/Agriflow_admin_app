import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/navigation/nav_destination.dart';
import '../../domain/entities/notification_item.dart';

/// Maps a backend notification `reference_type` to an in-app route.
///
/// Only the reference types verified live on `GET /api/v1/notifications`
/// (2026-09-28, 400-row sample): `seed_purchase`, `booking_slot`,
/// `farm_visit`, `grain_sale`, `transaction`, `bank_change_request`.
/// No types are inferred or invented — unknown types resolve to null and
/// fall back to the Notifications screen.
class NotificationDestinationResolver {
  const NotificationDestinationResolver._();

  /// String values are `NavDestination.id`s (verified against
  /// `lib/core/navigation/nav_destination.dart`).
  static const Map<String, String> _routeByReferenceType = {
    'seed_purchase': 'seed-purchase',
    'booking_slot': 'booking-slot',
    'farm_visit': 'farm-visits',
    'grain_sale': 'grain-sales',
    'transaction': 'billing',
    // Module-level only: the app has no dedicated bank-change-request screen,
    // so the farmer directory is the truthful destination. The exact record
    // is never pretended to be opened.
    'bank_change_request': 'all-farmers',
  };

  /// Module route for a reference type, or null when the backend does not
  /// provide a reference or the type has no destination in this app.
  static String? routeFor(String? referenceType) {
    if (referenceType == null || referenceType.isEmpty) return null;
    return _routeByReferenceType[referenceType];
  }

  /// Role-safe route resolution for a notification tap.
  ///
  /// Missing/unresolvable reference → Notifications screen.
  /// Admin-only destinations are never exposed to a Manager.
  static String resolveRoute(
    NotificationItem item, {
    required bool isAdmin,
  }) {
    final route = routeFor(item.referenceType);
    if (route == null) return NavDestination.notifications.id;
    final destination = NavDestination.fromId(route);
    if (destination.adminOnly && !isAdmin) {
      return NavDestination.notifications.id;
    }
    return route;
  }
}

/// Carries a tapped/launched notification id from the platform layer to the
/// mounted navigation shell, which owns the canonical notification list.
///
/// Used for both foreground taps (`onDidReceiveNotificationResponse`) and
/// terminated-app launches (`getNotificationAppLaunchDetails`), plus the
/// in-app detail sheet's "Open" action.
class NotificationTapBridge {
  const NotificationTapBridge._();

  /// Set to a notification id when the user opens a notification; the shell
  /// clears it after resolving. Null means nothing pending.
  static final ValueNotifier<String?> pendingNotificationId =
      ValueNotifier<String?>(null);
}

/// Platform-facing system (Android) notification layer.
///
/// Implementations must never throw: system popups are an enhancement on top
/// of the in-app feed, and a missing platform channel (unit tests, unsupported
/// platform) must never break notification ingestion.
abstract class SystemNotificationService {
  /// Prepares the plugin (initialization + Android channel creation).
  Future<void> initialize();

  /// Shows the Android system popup for a real backend notification.
  /// Content comes exclusively from [item] — no generated/fake content.
  Future<void> show({required NotificationItem item});

  /// Whether system notifications are currently enabled for this app.
  Future<bool> areNotificationsEnabled();

  /// Requests POST_NOTIFICATIONS at most once per install (Android 13+).
  /// Never re-prompts after the first attempt; denial leaves the in-app
  /// feed fully functional.
  Future<void> ensurePermissionRequested();

  /// Registers the foreground tap callback (notification id).
  void setTapHandler(void Function(String notificationId) handler);

  /// Returns the notification id that launched this app (terminated-state
  /// tap), or null when the app was not launched from a notification.
  Future<String?> pendingLaunchNotificationId();
}

/// Default no-op service: used implicitly wherever the platform plugin is
/// unavailable (unit tests, unsupported platforms) because every call is
/// guarded and swallowed.
class NoopSystemNotificationService implements SystemNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> show({required NotificationItem item}) async {}

  @override
  Future<bool> areNotificationsEnabled() async => false;

  @override
  Future<void> ensurePermissionRequested() async {}

  @override
  void setTapHandler(void Function(String notificationId) handler) {}

  @override
  Future<String?> pendingLaunchNotificationId() async => null;
}

/// Real implementation backed by `flutter_local_notifications`.
///
/// - Channel `agriflow_business_events` with `Importance.high` so business
///   events produce heads-up popups (including while the app is foreground —
///   intentional product behavior).
/// - Notification id is a stable FNV-1a hash of the backend uuid, so the same
///   backend notification always updates the same Android notification
///   instead of stacking duplicates.
/// - Payload is the backend notification id (the shell resolves it against
///   the canonical REST list, which carries `reference_type`/`reference_id`).
class LocalSystemNotificationService implements SystemNotificationService {
  static const String channelId = 'agriflow_business_events';
  static const String channelName = 'Business events';
  static const String channelDescription =
      'Real-time business event notifications (bookings, seed purchases, '
      'farm visits, grain sales, payments).';
  static const String _permissionAskedKey =
      'agriflow_post_notifications_asked';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String notificationId)? _onTap;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(
        android: androidInit,
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          _onTap?.call(payload);
        },
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: channelDescription,
              importance: Importance.high,
              showBadge: true,
            ),
          );
      _initialized = true;
    } catch (_) {
      // Platform channel unavailable (unit tests / unsupported platform).
      // The in-app feed remains the source of truth.
    }
  }

  @override
  Future<void> show({required NotificationItem item}) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: _colorFor(item.type),
          styleInformation: BigTextStyleInformation(
            item.message,
            contentTitle: item.title,
          ),
          autoCancel: true,
          showWhen: true,
        ),
      );
      await _plugin.show(
        id: _stableIdFor(item.id),
        title: item.title,
        body: item.message,
        notificationDetails: details,
        payload: item.id,
      );
    } catch (_) {
      // Never let popup failures break notification ingestion.
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> ensurePermissionRequested() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      if (await android.areNotificationsEnabled() ?? false) return;

      final prefs = await SharedPreferences.getInstance();
      final asked = prefs.getBool(_permissionAskedKey) ?? false;
      if (asked) return;
      // Record the attempt BEFORE prompting so a dismissed/denied dialog is
      // never re-raised automatically (no permission nags).
      await prefs.setBool(_permissionAskedKey, true);
      await android.requestNotificationsPermission();
    } catch (_) {
      // Not on Android / plugin unavailable — in-app feed unaffected.
    }
  }

  @override
  void setTapHandler(void Function(String notificationId) handler) {
    _onTap = handler;
  }

  @override
  Future<String?> pendingLaunchNotificationId() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      final payload = details.notificationResponse?.payload;
      if (payload == null || payload.isEmpty) return null;
      return payload;
    } catch (_) {
      return null;
    }
  }

  /// Stable across process restarts so a repeated backend notification
  /// updates rather than duplicates its Android notification.
  static int _stableIdFor(String uuid) {
    var hash = 0x811c9dc5; // FNV-1a 32-bit offset basis
    for (final unit in uuid.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF2E7D32);
      case NotificationType.warning:
        return const Color(0xFFB26A00);
      case NotificationType.error:
        return const Color(0xFFC62828);
      case NotificationType.info:
        return const Color(0xFF0B3D6B);
    }
  }
}
