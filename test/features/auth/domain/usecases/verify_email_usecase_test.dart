import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:whatsapp_clone/features/auth/domain/usecases/verify_email_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late VerifyEmailUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = VerifyEmailUseCase(mockRepository);
  });

  group('VerifyEmailUseCase', () {
    test('should allow constructor instantiation', () {
      // This test should now pass after fixing the constructor issue
      expect(() => VerifyEmailUseCase(mockRepository), returnsNormally);
    });

    group('call', () {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.utc(2023, 1, 1),
      );

      final testSession = AuthSession(
        accessToken: 'verified_access_token',
        refreshToken: 'verified_refresh_token',
        user: testUser,
        expiresAt: DateTime.utc(2023, 12, 31),
        tokenType: 'Bearer',
      );

      test('should return session when email verification is successful', () async {
        // Arrange
        const params = VerifyEmailParams(
          email: 'test@example.com',
          otp: '123456',
        );
        when(() => mockRepository.verifyEmail(
              email: any(named: 'email'),
              otp: any(named: 'otp'),
            )).thenAnswer((_) async => Success(testSession));

        // Act
        final result = await useCase.call(params);

        // Assert
        expect(result, isA<Success<AuthSession>>());
        expect(result.dataOrNull, equals(testSession));
        verify(() => mockRepository.verifyEmail(
              email: 'test@example.com',
              otp: '123456',
            )).called(1);
      });

      test('should return failure when email verification fails', () async {
        // Arrange
        const params = VerifyEmailParams(
          email: 'test@example.com',
          otp: 'invalid_otp',
        );
        const failure = AuthFailure(message: 'Invalid OTP code');
        when(() => mockRepository.verifyEmail(
              email: any(named: 'email'),
              otp: any(named: 'otp'),
            )).thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase.call(params);

        // Assert
        expect(result, isA<ResultFailure<AuthSession>>());
        expect(result.failureOrNull, equals(failure));
        verify(() => mockRepository.verifyEmail(
              email: 'test@example.com',
              otp: 'invalid_otp',
            )).called(1);
      });
    });
  });

  group('VerifyEmailParams', () {
    test('should support equality comparison', () {
      const params1 = VerifyEmailParams(
        email: 'test@example.com',
        otp: '123456',
      );
      const params2 = VerifyEmailParams(
        email: 'test@example.com',
        otp: '123456',
      );
      const params3 = VerifyEmailParams(
        email: 'different@example.com',
        otp: '123456',
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('should include email and otp in props', () {
      const params = VerifyEmailParams(
        email: 'test@example.com',
        otp: '123456',
      );
      expect(params.props, contains('test@example.com'));
      expect(params.props, contains('123456'));
    });
  });
}