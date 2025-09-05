import 'package:equatable/equatable.dart';

import '../errors/failures.dart' as failures;

/// A generic result type that encapsulates success and failure states
sealed class Result<T> extends Equatable {
  const Result();
  
  /// Returns true if the result is a success
  bool get isSuccess => this is Success<T>;
  
  /// Returns true if the result is a failure
  bool get isFailure => this is ResultFailure<T>;
  
  /// Executes the appropriate callback based on the result type
  R when<R>({
    required R Function(T data) success,
    required R Function(failures.Failure failure) failure,
  }) {
    return switch (this) {
      Success(data: final data) => success(data),
      ResultFailure(failure: final failureValue) => failure(failureValue),
    };
  }
  
  /// Maps the success value to a new type
  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Success(data: final data) => Success(transform(data)),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }
  
  /// Returns the success value or null if it's a failure
  T? get dataOrNull {
    return switch (this) {
      Success(data: final data) => data,
      ResultFailure() => null,
    };
  }
  
  /// Returns the failure or null if it's a success
  failures.Failure? get failureOrNull {
    return switch (this) {
      Success() => null,
      ResultFailure(failure: final failure) => failure,
    };
  }
}

/// Represents a successful result
final class Success<T> extends Result<T> {
  const Success(this.data);
  
  final T data;
  
  @override
  List<Object?> get props => [data];
}

/// Represents a failed result
final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  
  final failures.Failure failure;
  
  @override
  List<Object?> get props => [failure];
}