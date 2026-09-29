import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/core/network/api_exception.dart';
import 'package:agriflow_admin/features/booking_slot/data/datasources/booking_remote_data_source.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_exception.dart';
import 'package:agriflow_admin/features/farm_visits/data/datasources/farm_visit_remote_data_source.dart';
import 'package:agriflow_admin/features/farm_visits/domain/entities/farm_visit_exception.dart';
import 'package:agriflow_admin/features/farmers/data/farmer_lookup_service.dart';
import 'package:agriflow_admin/features/farmers/domain/entities/farmer_exception.dart';
import 'package:agriflow_admin/features/grain_sales/domain/entities/grain_sale_exception.dart';

void main() {
  setUp(FarmerLookupService.clear);

  Map<String, String> headers() => {'content-type': 'application/json'};

  String farmerRows() => jsonEncode({
        'data': [
          {
            'id': 'f1',
            'name': 'Ravi Kumar',
            'phone': '9000000001',
            'farmer_profile': {'address': 'Kurnool'},
          },
          {
            'id': 'f2',
            'name': 'Sita Devi',
            'phone': '9000000002',
            'village': 'Top-level Village',
          },
          {'id': 'f3', 'name': 'No Profile', 'phone': '9000000003'},
        ],
      });

  group('M11 flutter-03 rec 5 — shared FarmerLookupService', () {
    test('parses farmer_profile.address (canonical) with top-level village fallback', () async {
      final client = MockClient((_) async => http.Response(farmerRows(), 200, headers: headers()));

      final map = await FarmerLookupService.fetch(
        accessToken: 'tok-1',
        baseUrl: 'https://unit.test',
        apiPrefix: '/api/v1',
        client: client,
      );

      expect(map.keys, ['f1', 'f2', 'f3']);
      expect(map['f1']!.name, 'Ravi Kumar');
      expect(map['f1']!.phone, '9000000001');
      expect(map['f1']!.village, 'Kurnool');
      expect(map['f2']!.village, 'Top-level Village');
      expect(map['f3']!.village, isNull);
    });

    test('serves repeat fetches from the session cache (one HTTP call)', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(farmerRows(), 200, headers: headers());
      });

      Future<Map<String, FarmerLookupEntry>> fetch() => FarmerLookupService.fetch(
            accessToken: 'tok-cache',
            baseUrl: 'https://unit.test',
            apiPrefix: '/api/v1',
            client: client,
          );

      final first = await fetch();
      final second = await fetch();

      expect(calls, 1);
      expect(second, first);
    });

    test('a different access token bypasses the cache', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(farmerRows(), 200, headers: headers());
      });

      Future<Map<String, FarmerLookupEntry>> fetch(String token) =>
          FarmerLookupService.fetch(
            accessToken: token,
            baseUrl: 'https://unit.test',
            apiPrefix: '/api/v1',
            client: client,
          );

      await fetch('tok-a');
      await fetch('tok-b');

      expect(calls, 2);
    });

    test('concurrent callers share a single in-flight request', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(farmerRows(), 200, headers: headers());
      });

      final f1 = FarmerLookupService.fetch(
        accessToken: 'tok-concurrent',
        baseUrl: 'https://unit.test',
        apiPrefix: '/api/v1',
        client: client,
      );
      final f2 = FarmerLookupService.fetch(
        accessToken: 'tok-concurrent',
        baseUrl: 'https://unit.test',
        apiPrefix: '/api/v1',
        client: client,
      );
      final results = await Future.wait([f1, f2]);

      expect(calls, 1);
      expect(results[0], results[1]);
    });

    test('failures return an empty map and are never cached', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        if (calls == 1) {
          return http.Response('{"detail":"boom"}', 500, headers: headers());
        }
        return http.Response(farmerRows(), 200, headers: headers());
      });

      Future<Map<String, FarmerLookupEntry>> fetch() => FarmerLookupService.fetch(
            accessToken: 'tok-fail',
            baseUrl: 'https://unit.test',
            apiPrefix: '/api/v1',
            client: client,
          );

      final failed = await fetch();
      final recovered = await fetch();

      expect(failed, isEmpty);
      expect(recovered, isNotEmpty);
      expect(calls, 2);
    });
  });

  group('M11 flutter-03 rec 6 — shared AppApiException + 409 conflict cases', () {
    test('all four feature exception hierarchies implement AppApiException', () {
      final List<Object> samples = [
        FarmerException(message: 'x'),
        GrainSaleException(message: 'x'),
        const FarmVisitValidationException('x'),
        const BookingException('x'),
      ];
      expect(samples.every((e) => e is AppApiException), isTrue);
    });

    test('AppApiException exposes message, statusCode and isNetworkError uniformly', () {
      const conflicts = <AppApiException>[
        FarmVisitConflictException(),
        BookingConflictException(),
        FarmVisitNetworkException(),
        FarmerConflictException(),
        GrainSaleConflictException(),
      ];

      for (final e in conflicts) {
        expect(e.message, isNotEmpty);
        expect(e.statusCode, isNotNull);
      }
      expect(const FarmVisitConflictException().statusCode, 409);
      expect(const BookingConflictException().statusCode, 409);
      expect(const FarmerConflictException().statusCode, 409);
      expect(const GrainSaleConflictException().statusCode, 409);

      expect(const FarmVisitNetworkException().isNetworkError, isTrue);
      expect(const FarmVisitConflictException().isNetworkError, isFalse);
      expect(const BookingException('x', statusCode: 0, isNetworkError: true).isNetworkError, isTrue);
      expect(const BookingConflictException().isNetworkError, isFalse);
    });

    test('farm-visits maps HTTP 409 to FarmVisitConflictException', () async {
      final ds = FarmVisitRemoteDataSourceImpl(
        client: MockClient(
          (_) async => http.Response('{"detail":"visit changed"}', 409, headers: headers()),
        ),
      );

      await expectLater(
        ds.getVisits(accessToken: 't'),
        throwsA(isA<FarmVisitConflictException>()),
      );
    });

    test('bookings maps HTTP 409 to BookingConflictException', () async {
      final ds = BookingRemoteDataSourceImpl(
        client: MockClient(
          (_) async => http.Response('{"detail":"booking changed"}', 409, headers: headers()),
        ),
      );

      await expectLater(
        ds.getBookings(accessToken: 't'),
        throwsA(isA<BookingConflictException>()),
      );
    });
  });
}
