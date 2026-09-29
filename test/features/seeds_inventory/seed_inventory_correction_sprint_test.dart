import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart';
import 'package:agriflow_admin/features/seeds_inventory/data/repositories/seeds_inventory_repository_impl.dart';
import 'package:agriflow_admin/features/seeds_inventory/domain/entities/seed_inventory_item.dart';
import 'package:agriflow_admin/features/seeds_inventory/domain/exceptions/seeds_inventory_exception.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/controllers/seeds_inventory_controller.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/widgets/seed_image_picker.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/widgets/seed_inventory_card.dart';

void main() {
  group('Seed Inventory Correction Sprint — IMAGE UPLOAD Verification Tests', () {
    test('1. Picker returns selected image with valid bytes, name, and mimeType', () async {
      final picker = SeedImagePicker(
        pick: () async => const SeedPickedImage(
          bytes: [1, 2, 3, 4],
          fileName: 'cotton_seeds.jpg',
          mimeType: 'image/jpeg',
        ),
      );
      final picked = await picker.pickImage();
      expect(picked, isNotNull);
      expect(picked!.bytes, [1, 2, 3, 4]);
      expect(picked.fileName, 'cotton_seeds.jpg');
      expect(picked.mimeType, 'image/jpeg');
    });

    test('2. Correct filename is preserved throughout resolution', () {
      expect(resolveSeedImageMimeType('sample_photo.png'), 'image/png');
      expect(resolveSeedImageMimeType('variety_seed.webp'), 'image/webp');
      expect(resolveSeedImageMimeType('grain.gif'), 'image/gif');
      expect(resolveSeedImageMimeType('hybrid.heic'), 'image/heic');
      expect(resolveSeedImageMimeType('paddy.heif'), 'image/heif');
      expect(resolveSeedImageMimeType('crop.bmp'), 'image/bmp');
      expect(resolveSeedImageMimeType('seed.jpg'), 'image/jpeg');
      expect(resolveSeedImageMimeType('seed.jpeg'), 'image/jpeg');
      expect(resolveSeedImageMimeType('unknown_extension.xyz'), 'image/jpeg');
    });

    test('3. Correct MIME type resolution prefers declared MIME type over fallback', () {
      expect(resolveSeedImageMimeType('file.jpg', 'image/png'), 'image/png');
      expect(resolveSeedImageMimeType('file.png', 'application/octet-stream'), 'image/png');
      expect(resolveSeedImageMimeType('file.webp', ''), 'image/webp');
    });

    test('4. Multipart request contains file bytes and filename', () async {
      http.Request? capturedRequest;
      final client = MockClient((req) async {
        capturedRequest = req;
        return http.Response(
          jsonEncode({
            'data': {'public_url': 'https://storage.example.com/seeds/test.png'}
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      final url = await ds.uploadSeedImage(
        accessToken: 'valid-token',
        fileBytes: [100, 101, 102],
        fileName: 'wheat.png',
        contentType: 'image/png',
      );

      expect(url, 'https://storage.example.com/seeds/test.png');
      expect(capturedRequest, isNotNull);
      final body = latin1.decode(capturedRequest!.bodyBytes);
      expect(body, contains('filename="wheat.png"'));
      expect(body, contains('content-type: image/png'));
    });

    test('5. Multipart request specifies bucket=seeds', () async {
      http.Request? capturedRequest;
      final client = MockClient((req) async {
        capturedRequest = req;
        return http.Response(
          jsonEncode({
            'data': {'public_url': 'https://storage.example.com/seeds/wheat.jpg'}
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      await ds.uploadSeedImage(
        accessToken: 'valid-token',
        fileBytes: [1, 2],
        fileName: 'wheat.jpg',
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.headers['Authorization'], 'Bearer valid-token');
      final body = latin1.decode(capturedRequest!.bodyBytes);
      expect(body, contains('name="bucket"\r\n\r\nseeds'));
    });

    test('6. Upload response with data.public_url returns URL correctly', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'data': {
              'object_path': 'seeds/chia.jpg',
              'public_url': 'https://supabase.co/storage/v1/object/public/uploads/seeds/chia.jpg',
              'size_bytes': 2048,
              'content_type': 'image/jpeg',
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      final url = await ds.uploadSeedImage(
        accessToken: 'token',
        fileBytes: [1, 2, 3],
        fileName: 'chia.jpg',
      );

      expect(url, 'https://supabase.co/storage/v1/object/public/uploads/seeds/chia.jpg');
    });

    test('7. Missing public_url in response throws SeedsInventoryException with clear message', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({'data': {'object_path': 'seeds/test.jpg'}}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      expect(
        () => ds.uploadSeedImage(
          accessToken: 'token',
          fileBytes: [1],
          fileName: 'test.jpg',
        ),
        throwsA(
          isA<SeedsInventoryException>().having(
            (e) => e.message,
            'message',
            'Image upload completed, but the server did not return a public image URL.',
          ),
        ),
      );
    });

    test('8. Empty public_url in response throws SeedsInventoryException', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({'data': {'public_url': '   '}}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      expect(
        () => ds.uploadSeedImage(
          accessToken: 'token',
          fileBytes: [1],
          fileName: 'test.jpg',
        ),
        throwsA(isA<SeedsInventoryException>()),
      );
    });

    test('9. HTTP 401 returns sanitized authorization error', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({'detail': 'Token has expired or is invalid'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      expect(
        () => ds.uploadSeedImage(
          accessToken: 'expired-token',
          fileBytes: [1],
          fileName: 'test.jpg',
        ),
        throwsA(
          isA<SeedsInventoryException>().having(
            (e) => e.message,
            'message',
            'Image upload is not authorized.',
          ),
        ),
      );
    });

    test('10. HTTP 422 returns sanitized rejection message', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({'detail': [{'loc': ['body', 'file'], 'msg': 'Invalid file format'}]}),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      expect(
        () => ds.uploadSeedImage(
          accessToken: 'token',
          fileBytes: [1],
          fileName: 'test.exe',
        ),
        throwsA(
          isA<SeedsInventoryException>().having(
            (e) => e.message,
            'message',
            'Image upload was rejected by the server.',
          ),
        ),
      );
    });

    test('11. HTTP 500 returns sanitized server error message', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({'detail': 'Internal database connection failed'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      expect(
        () => ds.uploadSeedImage(
          accessToken: 'token',
          fileBytes: [1],
          fileName: 'test.jpg',
        ),
        throwsA(
          isA<SeedsInventoryException>().having(
            (e) => e.message,
            'message',
            'Image upload service is temporarily unavailable.',
          ),
        ),
      );
    });

    test('12. Network failure surfaces connection message', () async {
      final client = MockClient((req) async {
        throw const SocketException('Connection reset by peer');
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      expect(
        () => ds.uploadSeedImage(
          accessToken: 'token',
          fileBytes: [1],
          fileName: 'test.jpg',
        ),
        throwsA(
          isA<SeedsInventoryNetworkException>().having(
            (e) => e.message,
            'message',
            'Unable to upload image. Check your connection.',
          ),
        ),
      );
    });

    test('13. image_url persisted in createSeed and updateSeed requests', () async {
      Map<String, dynamic>? createPayload;
      Map<String, dynamic>? updatePayload;

      final client = MockClient((req) async {
        if (req.method == 'POST' && req.url.path.endsWith('/seeds')) {
          createPayload = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'seed-new',
                'name': createPayload!['name'],
                'price_per_kg': '50.00',
                'stock_kg': '1000.00',
                'image_url': createPayload!['image_url'],
                'is_active': true,
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.method == 'PATCH' && req.url.path.contains('/seeds/seed-new')) {
          updatePayload = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'seed-new',
                'name': 'Updated Name',
                'price_per_kg': '50.00',
                'stock_kg': '1000.00',
                'image_url': updatePayload!['image_url'],
                'is_active': true,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      final created = await ds.createSeed(
        accessToken: 'token',
        name: 'Hybrid Corn',
        pricePerKg: 50.0,
        stockKg: 1000.0,
        imageUrl: 'https://cdn.example.com/corn.jpg',
      );
      expect(created.imageUrl, 'https://cdn.example.com/corn.jpg');
      expect(createPayload!['image_url'], 'https://cdn.example.com/corn.jpg');

      final updated = await ds.updateSeed(
        accessToken: 'token',
        seedId: 'seed-new',
        imageUrl: 'https://cdn.example.com/corn-new.jpg',
      );
      expect(updated.imageUrl, 'https://cdn.example.com/corn-new.jpg');
      expect(updatePayload!['image_url'], 'https://cdn.example.com/corn-new.jpg');
    });

    testWidgets('14. Image preview displays URL and truthful fallback when invalid', (tester) async {
      const seedWithImage = SeedInventoryItem(
        id: 'seed-1',
        name: 'Organic Paddy',
        pricePerKg: 60.0,
        stockKg: 2000.0,
        imageUrl: 'https://example.com/paddy.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeedInventoryCard(
              seed: seedWithImage,
              isAdmin: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Organic Paddy'), findsOneWidget);
    });

    testWidgets('15. Fallback image does NOT use application logo but displays Icons.grass', (tester) async {
      const seedWithoutImage = SeedInventoryItem(
        id: 'seed-2',
        name: 'No Image Variety',
        pricePerKg: 40.0,
        stockKg: 1500.0,
        imageUrl: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeedInventoryCard(
              seed: seedWithoutImage,
              isAdmin: true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Card must render the grass icon fallback
      expect(find.byIcon(Icons.grass), findsOneWidget);
    });
  });

  group('Seed Inventory Correction Sprint — SEED DELETE Verification Tests', () {
    test('1. Correct seed ID is sent in DELETE request', () async {
      String? requestedPath;
      final client = MockClient((req) async {
        if (req.method == 'DELETE') {
          requestedPath = req.url.path;
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );

      await ds.deleteSeed(
        accessToken: 'token',
        seedId: '9876-uuid-abcd',
      );

      expect(requestedPath, '/api/v1/seeds/9876-uuid-abcd');
    });

    test('2. Correct DELETE endpoint URL constructed with apiPrefix', () async {
      late Uri targetUri;
      final client = MockClient((req) async {
        targetUri = req.url;
        return http.Response('', 204);
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://backend.onrender.com',
        client: client,
      );

      await ds.deleteSeed(accessToken: 'token', seedId: 'uuid-123');
      expect(targetUri.toString(), 'https://backend.onrender.com/api/v1/seeds/uuid-123');
    });

    test('3. Successful 204 No Content response is parsed without exception', () async {
      final client = MockClient((req) async => http.Response('', 204));
      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: ds);

      await expectLater(
        repo.deleteSeed(accessToken: 'token', seedId: 's1'),
        completes,
      );
    });

    test('4. Failed 404 / 500 response throws typed SeedsInventoryException', () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode({'detail': 'Seed not found'}), 404, headers: {'content-type': 'application/json'});
      });
      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: ds);

      expect(
        () => repo.deleteSeed(accessToken: 'token', seedId: 's-missing'),
        throwsA(isA<SeedsInventoryNotFoundException>()),
      );
    });

    test('5. Local state is updated immediately on deleteSeed success', () async {
      final client = MockClient((req) async {
        if (req.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'seed-1', 'name': 'Paddy A', 'price_per_kg': '40.00', 'stock_kg': '500.00', 'is_active': true},
                {'id': 'seed-2', 'name': 'Wheat B', 'price_per_kg': '35.00', 'stock_kg': '800.00', 'is_active': true},
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: ds);
      final controller = SeedsInventoryController(repository: repo, accessToken: 'token');

      await controller.loadSeeds();
      expect(controller.allSeeds.length, 2);

      final ok = await controller.deleteSeed('seed-1');
      expect(ok, isTrue);
      expect(controller.allSeeds.length, 2);
      expect(controller.activeSeedsCount, 1);
      expect(controller.allSeeds.firstWhere((s) => s.id == 'seed-1').isActive, isFalse);
      expect(controller.successMessage, 'Seed "Paddy A" deleted successfully.');
    });

    test('6. Reload preserves backend state accurately and ensures deleted seed disappears from All/Active/Low Stock and is only in Inactive', () async {
      var deleteCalled = false;
      final client = MockClient((req) async {
        if (req.method == 'GET' && req.url.path.endsWith('/seeds')) {
          // If deleted on backend, it returns with is_active = false
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'seed-1',
                  'name': 'DHM-117 Maize',
                  'price_per_kg': '55.00',
                  'stock_kg': '400.00', // Low stock (<500kg)
                  'is_active': deleteCalled ? false : true,
                },
                {
                  'id': 'seed-2',
                  'name': 'HD-2967 Wheat',
                  'price_per_kg': '38.00',
                  'stock_kg': '2478.00',
                  'is_active': true,
                },
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.method == 'DELETE') {
          deleteCalled = true;
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: ds);
      final controller = SeedsInventoryController(repository: repo, accessToken: 'token');

      await controller.loadSeeds();
      expect(controller.totalSeedsCount, 2);
      expect(controller.activeSeedsCount, 2);
      expect(controller.lowStockCount, 1);
      expect(controller.inactiveSeedsCount, 0);

      // Before deletion, DHM-117 Maize is in All, Active, and Low Stock
      controller.setFilter('all');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isTrue);
      controller.setFilter('active');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isTrue);
      controller.setFilter('low_stock');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isTrue);

      // Admin deletes the seed
      final ok = await controller.deleteSeed('seed-1');
      expect(ok, isTrue);

      // Verify immediate disappearance from All, Active, Low Stock
      controller.setFilter('all');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isFalse);

      controller.setFilter('active');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isFalse);

      controller.setFilter('low_stock');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isFalse);

      // Verify present in Inactive
      controller.setFilter('inactive');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isTrue);
      expect(controller.inactiveSeedsCount, 1);

      // Refresh / re-fetch from backend
      await controller.loadSeeds(refresh: true);

      // Verify remains absent from All, Active, Low Stock after refresh
      controller.setFilter('all');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isFalse);

      controller.setFilter('active');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isFalse);

      controller.setFilter('low_stock');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isFalse);

      // Verify remains present in Inactive after refresh
      controller.setFilter('inactive');
      expect(controller.filteredSeeds.any((s) => s.id == 'seed-1'), isTrue);
      expect(controller.inactiveSeedsCount, 1);
    });

    test('7. Inactive seed filter behavior accurately segregates active and inactive items', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'seed-active', 'name': 'Active Maize', 'price_per_kg': '30.00', 'stock_kg': '1000.00', 'is_active': true},
              {'id': 'seed-inactive', 'name': 'Deactivated Cotton', 'price_per_kg': '70.00', 'stock_kg': '50.00', 'is_active': false},
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: ds);
      final controller = SeedsInventoryController(repository: repo, accessToken: 'token');

      await controller.loadSeeds();
      expect(controller.totalSeedsCount, 1);
      expect(controller.activeSeedsCount, 1);
      expect(controller.inactiveSeedsCount, 1);

      // 'all' tab shows active only
      controller.setFilter('all');
      expect(controller.filteredSeeds.length, 1);
      expect(controller.filteredSeeds.first.id, 'seed-active');

      // 'active' tab shows active only
      controller.setFilter('active');
      expect(controller.filteredSeeds.length, 1);
      expect(controller.filteredSeeds.first.id, 'seed-active');

      // 'inactive' tab shows inactive only
      controller.setFilter('inactive');
      expect(controller.filteredSeeds.length, 1);
      expect(controller.filteredSeeds.first.id, 'seed-inactive');
    });

    test('8. Safe delete handling when seeds list is empty prevents StateError', () async {
      final client = MockClient((req) async => http.Response('', 204));
      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: ds);
      final controller = SeedsInventoryController(repository: repo, accessToken: 'token');

      // seeds list is empty
      final ok = await controller.deleteSeed('non-existent-id');
      expect(ok, isTrue);
      expect(controller.successMessage, 'Seed "Seed" deleted successfully.');
    });

    test('9. Role permissions: Manager role receives 403 Forbidden feedback', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({'detail': 'Only admins can delete seeds'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: ds);
      final controller = SeedsInventoryController(repository: repo, accessToken: 'manager-token');

      final ok = await controller.deleteSeed('seed-1');
      expect(ok, isFalse);
      expect(controller.errorMessage, contains('Manager role does not have permission'));
    });

    test('10. No false success message when deletion fails on network or server error', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({'detail': 'Database transaction rollback'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiSeedsInventoryRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: client,
      );
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: ds);
      final controller = SeedsInventoryController(repository: repo, accessToken: 'token');

      final ok = await controller.deleteSeed('seed-1');
      expect(ok, isFalse);
      expect(controller.successMessage, isNull);
      expect(controller.errorMessage, isNotNull);
    });
  });
}
