import 'package:shared_preferences/shared_preferences.dart';

/// Device-local notification preferences for the Settings screen (M10).
///
/// These are per-device display preferences only. The live backend exposes
/// no notification-settings endpoint — server-side notification preferences
/// are "Backend API required — to be supplied by Syed." Nothing here is sent
/// to the backend.
class NotificationPreferences {
  static const String pushKey = 'notif_push_enabled';
  static const String emailKey = 'notif_email_enabled';
  static const String smsKey = 'notif_sms_enabled';

  /// HTML defaults: Push ON, Email ON, SMS OFF.
  static const bool pushDefault = true;
  static const bool emailDefault = true;
  static const bool smsDefault = false;

  static Future<Map<String, bool>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        pushKey: prefs.getBool(pushKey) ?? pushDefault,
        emailKey: prefs.getBool(emailKey) ?? emailDefault,
        smsKey: prefs.getBool(smsKey) ?? smsDefault,
      };
    } catch (_) {
      // Platform store unavailable (fresh install edge cases) — fall back to
      // the HTML defaults instead of blocking the screen on a spinner.
      return {
        pushKey: pushDefault,
        emailKey: emailDefault,
        smsKey: smsDefault,
      };
    }
  }

  static Future<void> save(String key, bool value) async {
    if (key != pushKey && key != emailKey && key != smsKey) {
      throw ArgumentError('Unknown preference key: $key');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
