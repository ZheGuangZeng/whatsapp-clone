import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:whatsapp_clone/features/auth/domain/usecases/logout_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late LogoutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LogoutUseCase(mockRepository);
  });

  group('LogoutUseCase', () {
    test('should logout successfully', () async {
      // Arrange
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase();

      // Assert
      expect(result, isA<Success<void>>());
      expect(result.isSuccess, true);
      verify(() => mockRepository.signOut()).called(1);
    });

    test('should return failure when logout fails', () async {
      // Arrange
      const failure = ServerFailure(message: 'Logout failed');
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, isA<ResultFailure<void>>());
      expect(result.failureOrNull, failure);
      verify(() => mockRepository.signOut()).called(1);
    });

    test('should handle network errors during logout', () async {
      // Arrange
      const failure = NetworkFailure(message: 'No internet connection');
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, isA<ResultFailure<void>>());
      expect(result.failureOrNull, failure);
      verify(() => mockRepository.signOut()).called(1);
    });

    test('should handle cache errors during logout', () async {
      // Arrange
      const failure = CacheFailure(message: 'Failed to clear local session');
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, isA<ResultFailure<void>>());
      expect(result.failureOrNull, failure);
      verify(() => mockRepository.signOut()).called(1);
    });

    group('edge cases', () {
      test('should handle repeated logout calls', () async {
        // Arrange
        when(() => mockRepository.signOut())
            .thenAnswer((_) async => const Success(null));

        // Act
        final result1 = await useCase();
        final result2 = await useCase();

        // Assert
        expect(result1, isA<Success<void>>());
        expect(result2, isA<Success<void>>());
        verify(() => mockRepository.signOut()).called(2);
      });

      test('should handle timeout during logout', () async {
        // Arrange
        when(() => mockRepository.signOut())
            .thenThrow(Exception('Timeout'));

        // Act & Assert
        expect(() => useCase(), throwsException);
        verify(() => mockRepository.signOut()).called(1);
      });
    });

    group('type safety', () {
      test('should maintain void return type', () async {
        // Arrange
        when(() => mockRepository.signOut())
            .thenAnswer((_) async => const Success(null));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, true);
      });
    });
  });
}