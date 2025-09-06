import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../repositories/i_auth_repository.dart';
import 'base_usecase.dart';

/// Use case for user registration with email or phone
class RegisterUseCase extends UseCase<AuthSession, RegisterParams> {
  RegisterUseCase(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(RegisterParams params) async {
    if (params.email != null) {
      return _repository.signUpWithEmail(
        email: params.email!,
        password: params.password,
        displayName: params.displayName,
      );
    } else if (params.phone != null) {
      return _repository.signUpWithPhone(
        phone: params.phone!,
        password: params.password,
        displayName: params.displayName,
      );
    } else {
      return const ResultFailure(
        ValidationFailure(message: 'Either email or phone must be provided'),
      );
    }
  }
}

/// Parameters for register use case
class RegisterParams extends Equatable {
  const RegisterParams({
    this.email,
    this.phone,
    required this.password,
    required this.displayName,
  }) : assert(
          (email != null && phone == null) || (phone != null && email == null),
          'Either email or phone must be provided, but not both',
        );

  final String? email;
  final String? phone;
  final String password;
  final String displayName;

  @override
  List<Object?> get props => [email, phone, password, displayName];
}