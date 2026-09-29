import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Canonical enrichment record produced by the shared farmer lookup.
typedef FarmerLookupEntry = ({String name, String phone, String? village});

/// Single shared provider for the `GET /farmers?page=1&page_size=100`
/// enrichment fetch (flutter-03 rec 5).
///
/// Before this class existed, farm-visits, grain-sales, booking-slots and the
/// farmers repository each issued their own copy of the same request. The
/// service fetches once per (baseUrl, accessToken) session and de-duplicates
/// concurrent callers; failures are returned as an empty map and never
/// cached, matching the previous per-feature behaviour.
class FarmerLookupService {
  FarmerLookupService._();

  static Map<String, FarmerLookupEntry>? _cached;
  static String? _cacheKey;
  static Future<Map<String, FarmerLookupEntry>?>? _inflight;

  static Future<Map<String, FarmerLookupEntry>> fetch({
    required String accessToken,
    required String baseUrl,
    required String apiPrefix,
    required http.Client client,
  }) async {
    final key = '$baseUrl$apiPrefix|$accessToken';
    final cached = _cached;
    if (cached != null && _cacheKey == key) return cached;

    final inflight = _inflight;
    if (inflight != null && _cacheKey == key) {
      return (await inflight) ?? <String, FarmerLookupEntry>{};
    }

    _cacheKey = key;
    final future = _load(
      accessToken: accessToken,
      baseUrl: baseUrl,
      apiPrefix: apiPrefix,
      client: client,
    );
    _inflight = future;
    try {
      final rows = await future;
      if (rows == null) return <String, FarmerLookupEntry>{};
      _cached = rows;
      return rows;
    } finally {
      if (identical(_inflight, future)) _inflight = null;
    }
  }

  static Future<Map<String, FarmerLookupEntry>?> _load({
    required String accessToken,
    required String baseUrl,
    required String apiPrefix,
    required http.Client client,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$apiPrefix/farmers')
          .replace(queryParameters: {'page': '1', 'page_size': '100'});
      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      if (data is! List) return null;

      final map = <String, FarmerLookupEntry>{};
      for (final raw in data) {
        if (raw is! Map<String, dynamic>) continue;
        final id = raw['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        String? village;
        final profile = raw['farmer_profile'];
        if (profile is Map<String, dynamic>) {
          village = profile['address']?.toString();
        }
        village ??= raw['village']?.toString();
        if (village != null && village.isEmpty) village = null;
        map[id] = (
          name: raw['name']?.toString() ?? '',
          phone: raw['phone']?.toString() ?? '',
          village: village,
        );
      }
      return map;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void clear() {
    _cached = null;
    _cacheKey = null;
    _inflight = null;
  }
}
