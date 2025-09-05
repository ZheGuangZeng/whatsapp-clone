import '../../../../core/utils/result.dart';

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

/// Use case that doesn't require parameters
abstract class NoParamsUseCase<Type> {
  Future<Result<Type>> call();
}