import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock classes for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTAuth extends Mock implements GoTrueClient {}
class MockRealtimeClient extends Mock implements RealtimeClient {}
class MockStorageClient extends Mock implements SupabaseStorageClient {}
class MockPostgRESTClient extends Mock implements SupabaseQueryBuilder {}

/// Test helper utilities
class TestHelper {
  /// Sets up common test dependencies
  static void setUpTestDependencies() {
    // Register fallback values for mocks
    registerFallbackValue(AuthException('Test exception'));
    registerFallbackValue(PostgrestException(message: 'Test exception', details: 'Test details'));
    registerFallbackValue(StorageException('Test exception'));
  }

  /// Creates a mock Supabase client
  static MockSupabaseClient createMockSupabaseClient() {
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTAuth();
    final mockRealtime = MockRealtimeClient();
    final mockStorage = MockStorageClient();
    final mockPostgrest = MockPostgRESTClient();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockClient.realtime).thenReturn(mockRealtime);
    when(() => mockClient.storage).thenReturn(mockStorage);
    when(() => mockClient.from(any())).thenReturn(mockPostgrest);

    return mockClient;
  }
}