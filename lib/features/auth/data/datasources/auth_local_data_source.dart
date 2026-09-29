import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

/// Local storage contract for persisting authentication tokens and user session.
/// Plaintext passwords and confidential secrets are STRICTLY NEVER PERSISTED.
abstract class AuthLocalDataSource {
  Future<void> saveSession(AuthSession session, {bool rememberMe = true});
  Future<AuthSession?> getSession();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> updateTokens({required String accessToken, required String refreshToken});
  Future<void> updateUser(AuthUser user);
  Future<void> clearSession();
  Future<bool> isRemembered();
}

class SharedPreferencesAuthLocalDataSource implements AuthLocalDataSource {
  static const String _keyAccessToken = 'agriflow_access_token';
  static const String _keyRefreshToken = 'agriflow_refresh_token';
  static const String _keySessionData = 'agriflow_session_json';
  static const String _keyRememberMe = 'agriflow_remember_me';

  final SharedPreferences _prefs;

  SharedPreferencesAuthLocalDataSource(this._prefs);

  @override
  Future<void> saveSession(AuthSession session, {bool rememberMe = true}) async {
    await _prefs.setString(_keyAccessToken, session.accessToken);
    await _prefs.setString(_keyRefreshToken, session.refreshToken);
    await _prefs.setString(_keySessionData, jsonEncode(session.toJson()));
    await _prefs.setBool(_keyRememberMe, rememberMe);
  }

  @override
  Future<AuthSession?> getSession() async {
    final sessionJson = _prefs.getString(_keySessionData);
    if (sessionJson == null || sessionJson.isEmpty) return null;
    try {
      final map = jsonDecode(sessionJson) as Map<String, dynamic>;
      return AuthSession.fromJson(map);
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return _prefs.getString(_keyAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_keyRefreshToken);
  }

  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    final current = await getSession();
    if (current != null) {
      final updated = current.copyWith(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _prefs.setString(_keySessionData, jsonEncode(updated.toJson()));
    }
  }

  @override
  Future<void> updateUser(AuthUser user) async {
    final current = await getSession();
    if (current != null) {
      final updated = current.copyWith(user: user);
      await _prefs.setString(_keySessionData, jsonEncode(updated.toJson()));
    }
  }

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keySessionData);
    await _prefs.remove(_keyRememberMe);
  }

  @override
  Future<bool> isRemembered() async {
    return _prefs.getBool(_keyRememberMe) ?? true;
  }
}
