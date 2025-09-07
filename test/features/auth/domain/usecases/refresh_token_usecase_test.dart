import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:whatsapp_clone/features/auth/domain/usecases/refresh_token_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late RefreshTokenUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RefreshTokenUseCase(mockRepository);
  });

  group('RefreshTokenUseCase', () {
    test('should allow constructor instantiation', () {
      // This test should now pass after fixing the constructor issue
      expect(() => RefreshTokenUseCase(mockRepository), returnsNormally);
    });

    group('call', () {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.utc(2023, 1, 1),
      );

      final testSession = AuthSession(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        user: testUser,
        expiresAt: DateTime.utc(2023, 12, 31),
        tokenType: 'Bearer',
      );

      test('should return new session when token refresh is successful', () async {
        // Arrange
        const params = RefreshTokenParams(refreshToken: 'old_refresh_token');
        when(() => mockRepository.refreshToken(refreshToken: any(named: 'refreshToken')))
            .thenAnswer((_) async => Success(testSession));

        // Act
        final result = await useCase.call(params);

        // Assert
        expect(result, isA<Success<AuthSession>>());
        expect(result.dataOrNull, equals(testSession));
        verify(() => mockRepository.refreshToken(refreshToken: 'old_refresh_token')).called(1);
      });

      test('should return failure when token refresh fails', () async {
        // Arrange
        const params = RefreshTokenParams(refreshToken: 'invalid_refresh_token');
        const failure = AuthFailure(message: 'Invalid refresh token');
        when(() => mockRepository.refreshToken(refreshToken: any(named: 'refreshToken')))
            .thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase.call(params);

        // Assert
        expect(result, isA<ResultFailure<AuthSession>>());
        expect(result.failureOrNull, equals(failure));
        verify(() => mockRepository.refreshToken(refreshToken: 'invalid_refresh_token')).called(1);
      });
    });
  });

  group('RefreshTokenParams', () {
    test('should support equality comparison', () {
      const params1 = RefreshTokenParams(refreshToken: 'token123');
      const params2 = RefreshTokenParams(refreshToken: 'token123');
      const params3 = RefreshTokenParams(refreshToken: 'different_token');

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('should include refreshToken in props', () {
      const params = RefreshTokenParams(refreshToken: 'token123');
      expect(params.props, contains('token123'));
    });
  });
}