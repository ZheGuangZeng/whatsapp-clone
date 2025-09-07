import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/i_auth_repository.dart';
import 'base_usecase.dart';

/// Parameters for sending password reset
class SendPasswordResetParams {
  const SendPasswordResetParams({
    required this.email,
  });

  final String email;
}

/// Use case for sending password reset email
class SendPasswordResetUseCase implements UseCase<void, SendPasswordResetParams> {
  const SendPasswordResetUseCase(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<void>> call([SendPasswordResetParams? params]) async {
    if (params == null) {
      return const ResultFailure(
        ValidationFailure(message: 'Email is required for password reset'),
      );
    }

    // Validate email
    if (params.email.isEmpty || !_isValidEmail(params.email)) {
      return const ResultFailure(
        ValidationFailure(message: 'Please enter a valid email address'),
      );
    }

    return await _repository.sendPasswordReset(email: params.email);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}