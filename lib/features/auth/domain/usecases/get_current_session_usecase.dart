import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../repositories/i_auth_repository.dart';
import 'base_usecase.dart';

/// Use case for getting the current authentication session
class GetCurrentSessionUseCase extends NoParamsUseCase<AuthSession?> {
  GetCurrentSessionUseCase(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<AuthSession?>> call() async {
    return _repository.getCurrentSession();
  }
}