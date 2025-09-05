import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:whatsapp_clone/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LoginUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      const AuthSession(
        accessToken: 'token',
        refreshToken: 'refresh',
        user: User(
          id: '1',
          email: 'test@example.com',
          displayName: 'Test',
          createdAt: DateTime(2023, 1, 1),
        ),
        expiresAt: DateTime(2023, 12, 31),
        tokenType: 'Bearer',
      ),
    );
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    final testUser = User(
      id: '123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2023, 1, 1),
    );

    final testSession = AuthSession(
      accessToken: 'test_access_token',
      refreshToken: 'test_refresh_token',
      user: testUser,
      expiresAt: DateTime(2023, 12, 31),
      tokenType: 'Bearer',
    );

    group('email login', () {
      test('should return session when email login is successful', () async {
        // Arrange
        when(() => mockRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Success(testSession));

        const params = LoginParams(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await useCase.call(params);

        // Assert
        expect(result, isA<Success<AuthSession>>());
        expect(result.dataOrNull, equals(testSession));
        verify(() => mockRepository.signInWithEmail(
              email: 'test@example.com',
              password: 'password123',
            )).called(1);
      });

      test('should return failure when email login fails', () async {
        // Arrange
        const failure = AuthFailure(message: 'Invalid credentials');
        when(() => mockRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const ResultFailure(failure));

        const params = LoginParams(
          email: 'test@example.com',
          password: 'wrong_password',
        );

        // Act
        final result = await useCase.call(params);

        // Assert
        expect(result, isA<ResultFailure<AuthSession>>());
        expect(result.failureOrNull, equals(failure));
      });
    });

    group('phone login', () {
      test('should return session when phone login is successful', () async {
        // Arrange
        when(() => mockRepository.signInWithPhone(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Success(testSession));

        const params = LoginParams(
          phone: '+1234567890',
          password: 'password123',
        );

        // Act
        final result = await useCase.call(params);

        // Assert
        expect(result, isA<Success<AuthSession>>());
        expect(result.dataOrNull, equals(testSession));
        verify(() => mockRepository.signInWithPhone(
              phone: '+1234567890',
              password: 'password123',
            )).called(1);
      });

      test('should return failure when phone login fails', () async {
        // Arrange
        const failure = AuthFailure(message: 'Invalid credentials');
        when(() => mockRepository.signInWithPhone(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const ResultFailure(failure));

        const params = LoginParams(
          phone: '+1234567890',
          password: 'wrong_password',
        );

        // Act
        final result = await useCase.call(params);

        // Assert
        expect(result, isA<ResultFailure<AuthSession>>());
        expect(result.failureOrNull, equals(failure));
      });
    });

  });

  group('LoginParams', () {
    test('should support equality comparison', () {
      const params1 = LoginParams(
        email: 'test@example.com',
        password: 'password',
      );

      const params2 = LoginParams(
        email: 'test@example.com',
        password: 'password',
      );

      const params3 = LoginParams(
        email: 'different@example.com',
        password: 'password',
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}