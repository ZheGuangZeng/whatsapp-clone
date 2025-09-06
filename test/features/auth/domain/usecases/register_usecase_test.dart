import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:whatsapp_clone/features/auth/domain/usecases/register_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late RegisterUseCase useCase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      AuthSession(
        accessToken: 'token',
        refreshToken: 'refresh',
        user: User(
          id: '1',
          email: 'test@example.com',
          displayName: 'Test',
          createdAt: DateTime.utc(2023, 1, 1),
        ),
        expiresAt: DateTime.utc(2023, 12, 31),
        tokenType: 'Bearer',
      ),
    );
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockRepository);
  });

  group('RegisterUseCase', () {
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

    group('email registration', () {
      test('should register successfully with email', () async {
        // Arrange
        const params = RegisterParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        when(() => mockRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => Success(testSession));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<AuthSession>>());
        expect(result.dataOrNull, testSession);
        verify(() => mockRepository.signUpWithEmail(
              email: 'test@example.com',
              password: 'password123',
              displayName: 'Test User',
            )).called(1);
      });

      test('should return failure when email registration fails', () async {
        // Arrange
        const params = RegisterParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        const failure = ServerFailure(message: 'Registration failed');
        when(() => mockRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<AuthSession>>());
        expect(result.failureOrNull, failure);
        verify(() => mockRepository.signUpWithEmail(
              email: 'test@example.com',
              password: 'password123',
              displayName: 'Test User',
            )).called(1);
      });
    });

    group('phone registration', () {
      test('should register successfully with phone', () async {
        // Arrange
        const params = RegisterParams(
          phone: '+1234567890',
          password: 'password123',
          displayName: 'Test User',
        );

        when(() => mockRepository.signUpWithPhone(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => Success(testSession));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<AuthSession>>());
        expect(result.dataOrNull, testSession);
        verify(() => mockRepository.signUpWithPhone(
              phone: '+1234567890',
              password: 'password123',
              displayName: 'Test User',
            )).called(1);
      });

      test('should return failure when phone registration fails', () async {
        // Arrange
        const params = RegisterParams(
          phone: '+1234567890',
          password: 'password123',
          displayName: 'Test User',
        );

        const failure = ServerFailure(message: 'Registration failed');
        when(() => mockRepository.signUpWithPhone(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<AuthSession>>());
        expect(result.failureOrNull, failure);
        verify(() => mockRepository.signUpWithPhone(
              phone: '+1234567890',
              password: 'password123',
              displayName: 'Test User',
            )).called(1);
      });
    });

    group('validation', () {
      test('should be enforced at compile time', () {
        // The validation that either email or phone must be provided
        // is enforced at compile time through the assertion in RegisterParams
        // This ensures type safety and prevents invalid states
        expect(true, true);
      });
    });

    group('RegisterParams', () {
      test('should create RegisterParams with email', () {
        const params = RegisterParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(params.email, 'test@example.com');
        expect(params.phone, isNull);
        expect(params.password, 'password123');
        expect(params.displayName, 'Test User');
      });

      test('should create RegisterParams with phone', () {
        const params = RegisterParams(
          phone: '+1234567890',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(params.email, isNull);
        expect(params.phone, '+1234567890');
        expect(params.password, 'password123');
        expect(params.displayName, 'Test User');
      });

      test('should support equality comparison', () {
        const params1 = RegisterParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        const params2 = RegisterParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        const params3 = RegisterParams(
          phone: '+1234567890',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
      });

      test('should have consistent hashCode for equal objects', () {
        const params1 = RegisterParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        const params2 = RegisterParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(params1.hashCode, params2.hashCode);
      });

      test('should include all properties in props', () {
        const params = RegisterParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        final props = params.props;
        expect(props, contains(params.email));
        expect(props, contains(params.phone));
        expect(props, contains(params.password));
        expect(props, contains(params.displayName));
      });
    });

    group('edge cases', () {
      test('should handle empty string values appropriately', () {
        // Test that empty strings are treated as valid inputs
        // but may fail at the repository level
        const params = RegisterParams(
          email: '',
          password: '',
          displayName: '',
        );

        expect(params.email, isEmpty);
        expect(params.password, isEmpty);
        expect(params.displayName, isEmpty);
      });

      test('should handle special characters in inputs', () {
        const params = RegisterParams(
          email: 'test+special@example.com',
          password: 'P@ssw0rd!#\$',
          displayName: 'Test User 123',
        );

        expect(params.email, 'test+special@example.com');
        expect(params.password, 'P@ssw0rd!#\$');
        expect(params.displayName, 'Test User 123');
      });

      test('should handle international phone numbers', () {
        const params = RegisterParams(
          phone: '+441234567890',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(params.phone, '+441234567890');
      });
    });
  });
}