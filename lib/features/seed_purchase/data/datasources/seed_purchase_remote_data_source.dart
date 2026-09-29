import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_catalog_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_exception.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_pagination.dart';

abstract class SeedPurchaseRemoteDataSource {
  Future<({List<SeedPurchaseItem> items, SeedPurchasePagination pagination})> getPurchases({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  });

  Future<SeedPurchaseItem> updatePurchaseStatus({
    required String accessToken,
    required String purchaseId,
    required String newStatus,
  });

  Future<List<SeedCatalogItem>> getSeeds({required String accessToken});

  Future<Map<String, ({String name, String phone})>> getFarmerLookup({required String accessToken});
}

class SeedPurchaseRemoteDataSourceImpl implements SeedPurchaseRemoteDataSource {
  static const String defaultBaseUrl = 'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  SeedPurchaseRemoteDataSourceImpl({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final base = Uri.parse('$baseUrl$apiPrefix$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return base.replace(queryParameters: queryParams);
    }
    return base;
  }

  Map<String, String> _buildHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Never _handleErrorResponse(http.Response response) {
    String message = 'Request failed with status ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] != null) {
          message = decoded['detail'].toString();
        } else if (decoded['error'] is Map && decoded['error']['message'] != null) {
          message = decoded['error']['message'].toString();
        } else if (decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw SeedPurchaseException('Session expired. Please log in again.', statusCode: 401);
      case 403:
        throw SeedPurchaseException('Access denied. You do not have permission for this action.', statusCode: 403);
      case 404:
        throw SeedPurchaseException('Seed purchase record not found.', statusCode: 404);
      case 422:
        throw SeedPurchaseException('Validation error: $message', statusCode: 422);
      default:
        if (response.statusCode >= 500) {
          throw SeedPurchaseException('Server error (${response.statusCode}). Please try again shortly.', statusCode: response.statusCode);
        }
        throw SeedPurchaseException(message, statusCode: response.statusCode);
    }
  }

  @override
  Future<({List<SeedPurchaseItem> items, SeedPurchasePagination pagination})> getPurchases({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'sort': 'created_at',
        'order': 'desc',
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status != 'all' && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim().toLowerCase();
      }

      final uri = _uri('/seed-purchases', queryParams);

      final response = await client
          .get(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final itemsRaw = (decoded['data'] as List<dynamic>?) ?? [];
        final items = itemsRaw
            .map((e) => SeedPurchaseItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = SeedPurchasePagination.fromJson(
          decoded['pagination'] as Map<String, dynamic>?,
        );

        return (items: items, pagination: pagination);
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const SeedPurchaseException('Unable to connect to server. Please check your internet connection.', isNetworkError: true);
    } on http.ClientException catch (e) {
      throw SeedPurchaseException('Network error: ${e.message}', isNetworkError: true);
    }
  }

  @override
  Future<SeedPurchaseItem> updatePurchaseStatus({
    required String accessToken,
    required String purchaseId,
    required String newStatus,
  }) async {
    try {
      final uri = _uri('/seed-purchases/$purchaseId/status');
      final body = jsonEncode({'payment_status': newStatus.toLowerCase()});

      final response = await client
          .patch(uri, headers: _buildHeaders(accessToken), body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>;
        return SeedPurchaseItem.fromJson(data);
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const SeedPurchaseException('Unable to connect to server. Please check your internet connection.', isNetworkError: true);
    } on http.ClientException catch (e) {
      throw SeedPurchaseException('Network error: ${e.message}', isNetworkError: true);
    }
  }

  @override
  Future<List<SeedCatalogItem>> getSeeds({required String accessToken}) async {
    try {
      final uri = _uri('/seeds');
      final response = await client
          .get(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (decoded['data'] as List<dynamic>?) ?? [];
        return list.map((e) => SeedCatalogItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  }) async {
    try {
      final uri = _uri('/farmers', {'page': '1', 'page_size': '100'});
      final response = await client
          .get(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (decoded['data'] as List<dynamic>?) ?? [];
        final map = <String, ({String name, String phone})>{};
        for (final item in list) {
          if (item is Map<String, dynamic> && item['id'] != null) {
            final id = item['id'].toString();
            final name = (item['name'] ?? '').toString();
            final phone = (item['phone'] ?? '').toString();
            map[id] = (name: name, phone: phone);
          }
        }
        return map;
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}
