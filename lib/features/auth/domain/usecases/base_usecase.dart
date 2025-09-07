import '../../../../core/utils/result.dart';

/// Base class for all use cases
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Use case that doesn't require parameters
abstract class NoParamsUseCase<T> {
  Future<Result<T>> call();
}