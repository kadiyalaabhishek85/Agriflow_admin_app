import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/features/farmers/data/farmer_lookup_service.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_exception.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_item.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_pagination.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/warehouse_item.dart';

abstract class BookingRemoteDataSource {
  Future<({List<BookingItem> items, BookingPagination pagination})> getBookings({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  });

  Future<BookingItem> updateBookingStatus({
    required String accessToken,
    required String bookingId,
    required String newStatus,
    String? notes,
  });

  /// Records crop inspection for a delivered booking.
  Future<void> inspectBooking({
    required String accessToken,
    required String bookingId,
    required double goodQuantityKg,
    required double badQuantityKg,
    String? rejectionReason,
    String? notes,
  });

  Future<List<WarehouseItem>> getWarehouses({required String accessToken});

  Future<Map<String, ({String name, String phone})>> getFarmerLookup({required String accessToken});
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  static const String defaultBaseUrl = 'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  BookingRemoteDataSourceImpl({
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
        throw BookingException('Session expired. Please log in again.', statusCode: 401);
      case 403:
        throw BookingException('Access denied. You do not have permission for this action.', statusCode: 403);
      case 404:
        throw BookingException('Booking record not found.', statusCode: 404);
      case 409:
        throw const BookingConflictException();
      case 422:
        throw BookingException('Validation error: $message', statusCode: 422);
      default:
        if (response.statusCode >= 500) {
          throw BookingException('Server error (${response.statusCode}). Please try again shortly.', statusCode: response.statusCode);
        }
        throw BookingException(message, statusCode: response.statusCode);
    }
  }

  @override
  Future<({List<BookingItem> items, BookingPagination pagination})> getBookings({
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

      if (status != null && status.trim().isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status.trim().toLowerCase();
      }

      final uri = _uri('/bookings', queryParams);
      final response = await client.get(uri, headers: _buildHeaders(accessToken)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          final itemsList = <BookingItem>[];

          if (data is List) {
            for (final raw in data) {
              if (raw is Map<String, dynamic>) {
                itemsList.add(BookingItem.fromJson(raw));
              }
            }
          }

          final pagination = decoded['pagination'] is Map<String, dynamic>
              ? BookingPagination.fromJson(decoded['pagination'] as Map<String, dynamic>)
              : BookingPagination(
                  page: page,
                  pageSize: pageSize,
                  total: itemsList.length,
                  totalPages: 1,
                );

          return (items: itemsList, pagination: pagination);
        }
      }

      _handleErrorResponse(response);
    } on SocketException {
      throw const BookingException(
        'Unable to connect to server. Please check your internet connection.',
        statusCode: 0,
        isNetworkError: true,
      );
    } on http.ClientException catch (e) {
      throw BookingException(
        'Network error: ${e.message}',
        statusCode: 0,
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const BookingException(
        'Server request timed out. Please try again later.',
        statusCode: 0,
        isNetworkError: true,
      );
    } catch (e) {
      if (e is BookingException) rethrow;
      throw BookingException('An unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<BookingItem> updateBookingStatus({
    required String accessToken,
    required String bookingId,
    required String newStatus,
    String? notes,
  }) async {
    try {
      final uri = _uri('/bookings/$bookingId/status');
      final body = <String, dynamic>{
        'status': newStatus.toLowerCase(),
      };
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await client.patch(
        uri,
        headers: _buildHeaders(accessToken),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded;
          if (data is Map<String, dynamic>) {
            return BookingItem.fromJson(data);
          }
        }
      }

      _handleErrorResponse(response);
    } on SocketException {
      throw const BookingException(
        'Unable to connect to server. Please check your internet connection.',
        statusCode: 0,
        isNetworkError: true,
      );
    } on http.ClientException catch (e) {
      throw BookingException(
        'Network error: ${e.message}',
        statusCode: 0,
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const BookingException(
        'Server request timed out. Please try again later.',
        statusCode: 0,
        isNetworkError: true,
      );
    } catch (e) {
      if (e is BookingException) rethrow;
      throw BookingException('Failed to update booking status: ${e.toString()}');
    }
  }

  @override
  Future<void> inspectBooking({
    required String accessToken,
    required String bookingId,
    required double goodQuantityKg,
    required double badQuantityKg,
    String? rejectionReason,
    String? notes,
  }) async {
    try {
      final uri = _uri('/bookings/$bookingId/inspect');
      final body = <String, dynamic>{
        'good_quantity_kg': goodQuantityKg,
        'bad_quantity_kg': badQuantityKg,
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejection_reason': rejectionReason.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final response = await client.post(
        uri,
        headers: _buildHeaders(accessToken),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      _handleErrorResponse(response);
    } on SocketException {
      throw const BookingException(
        'Unable to connect to server. Please check your internet connection.',
        statusCode: 0,
        isNetworkError: true,
      );
    } on http.ClientException catch (e) {
      throw BookingException(
        'Network error: ${e.message}',
        statusCode: 0,
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const BookingException(
        'Server request timed out. Please try again later.',
        statusCode: 0,
        isNetworkError: true,
      );
    } catch (e) {
      if (e is BookingException) rethrow;
      throw BookingException('Failed to record inspection: ${e.toString()}');
    }
  }

  @override
  Future<List<WarehouseItem>> getWarehouses({required String accessToken}) async {
    try {
      final uri = _uri('/warehouses');
      final response = await client.get(uri, headers: _buildHeaders(accessToken)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = <WarehouseItem>[];
        final data = decoded is Map<String, dynamic> ? decoded['data'] : decoded;

        if (data is List) {
          for (final raw in data) {
            if (raw is Map<String, dynamic>) {
              list.add(WarehouseItem.fromJson(raw));
            }
          }
        }
        return list;
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
      final full = await FarmerLookupService.fetch(
        accessToken: accessToken,
        baseUrl: baseUrl,
        apiPrefix: apiPrefix,
        client: client,
      );
      return full.map((id, entry) => MapEntry(id, (name: entry.name, phone: entry.phone)));
    } catch (_) {
      return {};
    }
  }
}
