import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../repositories/i_auth_repository.dart';
import 'base_usecase.dart';

/// Use case for refreshing authentication token
class RefreshTokenUseCase extends UseCase<AuthSession, RefreshTokenParams> {
  RefreshTokenUseCase(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(RefreshTokenParams params) async {
    return _repository.refreshToken(refreshToken: params.refreshToken);
  }
}

/// Parameters for refresh token use case
class RefreshTokenParams extends Equatable {
  const RefreshTokenParams({required this.refreshToken});

  final String refreshToken;

  @override
  List<Object?> get props => [refreshToken];
}