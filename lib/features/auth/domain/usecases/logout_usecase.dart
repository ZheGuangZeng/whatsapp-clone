import '../../../../core/utils/result.dart';
import '../repositories/i_auth_repository.dart';
import 'base_usecase.dart';

/// Use case for user logout
class LogoutUseCase extends NoParamsUseCase<void> {
  const LogoutUseCase(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<void>> call() async {
    return _repository.signOut();
  }
}