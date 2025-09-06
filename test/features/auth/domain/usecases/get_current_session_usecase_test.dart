import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:whatsapp_clone/features/auth/domain/usecases/get_current_session_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late GetCurrentSessionUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentSessionUseCase(mockRepository);
  });

  group('GetCurrentSessionUseCase', () {
    test('should allow constructor instantiation', () {
      // This test should now pass after fixing the constructor issue
      expect(() => GetCurrentSessionUseCase(mockRepository), returnsNormally);
    });

    group('call', () {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.utc(2023, 1, 1),
      );

      final testSession = AuthSession(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        user: testUser,
        expiresAt: DateTime.utc(2023, 12, 31),
        tokenType: 'Bearer',
      );

      test('should return current session when available', () async {
        // Arrange
        when(() => mockRepository.getCurrentSession())
            .thenAnswer((_) async => Success(testSession));

        // Act
        final result = await useCase.call();

        // Assert
        expect(result, isA<Success<AuthSession?>>());
        expect(result.dataOrNull, equals(testSession));
        verify(() => mockRepository.getCurrentSession()).called(1);
      });

      test('should return null when no session exists', () async {
        // Arrange
        when(() => mockRepository.getCurrentSession())
            .thenAnswer((_) async => const Success(null));

        // Act
        final result = await useCase.call();

        // Assert
        expect(result, isA<Success<AuthSession?>>());
        expect(result.dataOrNull, isNull);
        verify(() => mockRepository.getCurrentSession()).called(1);
      });

      test('should return failure when repository fails', () async {
        // Arrange
        const failure = AuthFailure(message: 'Session error');
        when(() => mockRepository.getCurrentSession())
            .thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase.call();

        // Assert
        expect(result, isA<ResultFailure<AuthSession?>>());
        expect(result.failureOrNull, equals(failure));
        verify(() => mockRepository.getCurrentSession()).called(1);
      });
    });
  });
}