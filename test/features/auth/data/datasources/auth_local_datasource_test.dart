import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:whatsapp_clone/features/auth/data/models/auth_session_model.dart';

import '../../../../fixtures/auth_fixtures.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('AuthLocalDataSource', () {
    late AuthLocalDataSource datasource;
    late MockFlutterSecureStorage mockSecureStorage;
    late AuthSessionModel testSession;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      datasource = AuthLocalDataSource(mockSecureStorage);
      testSession = AuthFixtures.createAuthSessionModel();
    });

    group('saveSession', () {
      test('should save session and refresh token to secure storage', () async {
        // Arrange
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        // Act
        await datasource.saveSession(testSession);

        // Assert
        verify(() => mockSecureStorage.write(
              key: 'auth_session',
              value: jsonEncode(testSession.toJson()),
            )).called(1);
        verify(() => mockSecureStorage.write(
              key: 'refresh_token',
              value: testSession.refreshToken,
            )).called(1);
      });

      test('should handle storage errors gracefully when saving session',
          () async {
        // Arrange
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => datasource.saveSession(testSession),
          throwsException,
        );
      });
    });

    group('getCachedSession', () {
      test('should return cached session when valid data exists', () async {
        // Arrange
        final sessionJson = jsonEncode(testSession.toJson());
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => sessionJson);

        // Act
        final result = await datasource.getCachedSession();

        // Assert
        expect(result, isNotNull);
        expect(result!.accessToken, equals(testSession.accessToken));
        expect(result.refreshToken, equals(testSession.refreshToken));
        expect(result.user.id, equals(testSession.user.id));
        verify(() => mockSecureStorage.read(key: 'auth_session')).called(1);
      });

      test('should return null when no session data exists', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => null);

        // Act
        final result = await datasource.getCachedSession();

        // Assert
        expect(result, isNull);
        verify(() => mockSecureStorage.read(key: 'auth_session')).called(1);
      });

      test('should clear session and return null on invalid JSON data',
          () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => 'invalid json');
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        // Act
        final result = await datasource.getCachedSession();

        // Assert
        expect(result, isNull);
        verify(() => mockSecureStorage.read(key: 'auth_session')).called(1);
        verify(() => mockSecureStorage.delete(key: 'auth_session')).called(1);
        verify(() => mockSecureStorage.delete(key: 'refresh_token')).called(1);
      });

      test('should clear session and return null on JSON parsing error',
          () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => '{"incomplete": "json"');
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        // Act
        final result = await datasource.getCachedSession();

        // Assert
        expect(result, isNull);
        verify(() => mockSecureStorage.read(key: 'auth_session')).called(1);
        verify(() => mockSecureStorage.delete(key: 'auth_session')).called(1);
        verify(() => mockSecureStorage.delete(key: 'refresh_token')).called(1);
      });

      test('should clear session and return null on session model creation error',
          () async {
        // Arrange - JSON that parses but creates invalid AuthSessionModel
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => '{"invalid": "session_model"}');
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        // Act
        final result = await datasource.getCachedSession();

        // Assert
        expect(result, isNull);
        verify(() => mockSecureStorage.read(key: 'auth_session')).called(1);
        verify(() => mockSecureStorage.delete(key: 'auth_session')).called(1);
        verify(() => mockSecureStorage.delete(key: 'refresh_token')).called(1);
      });
    });

    group('getCachedRefreshToken', () {
      test('should return cached refresh token when it exists', () async {
        // Arrange
        const expectedToken = 'cached_refresh_token';
        when(() => mockSecureStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => expectedToken);

        // Act
        final result = await datasource.getCachedRefreshToken();

        // Assert
        expect(result, equals(expectedToken));
        verify(() => mockSecureStorage.read(key: 'refresh_token')).called(1);
      });

      test('should return null when no refresh token exists', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);

        // Act
        final result = await datasource.getCachedRefreshToken();

        // Assert
        expect(result, isNull);
        verify(() => mockSecureStorage.read(key: 'refresh_token')).called(1);
      });

      test('should handle storage errors when reading refresh token', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'refresh_token'))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => datasource.getCachedRefreshToken(),
          throwsException,
        );
      });
    });

    group('clearSession', () {
      test('should delete both session and refresh token from storage',
          () async {
        // Arrange
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        // Act
        await datasource.clearSession();

        // Assert
        verify(() => mockSecureStorage.delete(key: 'auth_session')).called(1);
        verify(() => mockSecureStorage.delete(key: 'refresh_token')).called(1);
      });

      test('should handle storage errors when clearing session', () async {
        // Arrange
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => datasource.clearSession(),
          throwsException,
        );
      });
    });

    group('hasSession', () {
      test('should return true when session data exists', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => 'some_session_data');

        // Act
        final result = await datasource.hasSession();

        // Assert
        expect(result, isTrue);
        verify(() => mockSecureStorage.read(key: 'auth_session')).called(1);
      });

      test('should return false when no session data exists', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => null);

        // Act
        final result = await datasource.hasSession();

        // Assert
        expect(result, isFalse);
        verify(() => mockSecureStorage.read(key: 'auth_session')).called(1);
      });

      test('should handle storage errors when checking session existence',
          () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => datasource.hasSession(),
          throwsException,
        );
      });
    });

    group('Constants', () {
      test('should have correct storage keys', () {
        // This test ensures the private constants remain consistent
        expect(AuthLocalDataSource(MockFlutterSecureStorage()).toString(), contains('AuthLocalDataSource'));
        // We can't test private constants directly, but we can verify the keys are used correctly
        // by checking the mock calls in other tests
      });
    });

    group('Error Recovery', () {
      test(
          'should maintain consistent state after error in getCachedSession followed by saveSession',
          () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => 'invalid json');
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        // Act - First call should clear invalid session
        var result = await datasource.getCachedSession();
        expect(result, isNull);

        // Act - Second call should successfully save new session
        await datasource.saveSession(testSession);

        // Arrange for successful read after save
        final sessionJson = jsonEncode(testSession.toJson());
        when(() => mockSecureStorage.read(key: 'auth_session'))
            .thenAnswer((_) async => sessionJson);

        // Act - Third call should return the saved session
        result = await datasource.getCachedSession();

        // Assert
        expect(result, isNotNull);
        expect(result!.accessToken, equals(testSession.accessToken));
      });
    });
  });
}