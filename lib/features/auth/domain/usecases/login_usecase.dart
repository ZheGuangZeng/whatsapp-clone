import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../repositories/i_auth_repository.dart';
import 'base_usecase.dart';

/// Use case for user login with email or phone
class LoginUseCase extends UseCase<AuthSession, LoginParams> {
  const LoginUseCase(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(LoginParams params) async {
    if (params.email != null) {
      return _repository.signInWithEmail(
        email: params.email!,
        password: params.password,
      );
    } else if (params.phone != null) {
      return _repository.signInWithPhone(
        phone: params.phone!,
        password: params.password,
      );
    } else {
      return const ResultFailure(
        ValidationFailure(message: 'Either email or phone must be provided'),
      );
    }
  }
}

/// Parameters for login use case
class LoginParams extends Equatable {
  const LoginParams({
    this.email,
    this.phone,
    required this.password,
  }) : assert(
          (email != null && phone == null) || (phone != null && email == null),
          'Either email or phone must be provided, but not both',
        );

  final String? email;
  final String? phone;
  final String password;

  @override
  List<Object?> get props => [email, phone, password];
}

