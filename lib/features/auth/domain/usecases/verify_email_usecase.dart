import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../repositories/i_auth_repository.dart';
import 'base_usecase.dart';

/// Use case for email verification
class VerifyEmailUseCase extends UseCase<AuthSession, VerifyEmailParams> {
  VerifyEmailUseCase(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(VerifyEmailParams params) async {
    return _repository.verifyEmail(
      email: params.email,
      otp: params.otp,
    );
  }
}

/// Parameters for email verification use case
class VerifyEmailParams extends Equatable {
  const VerifyEmailParams({
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}