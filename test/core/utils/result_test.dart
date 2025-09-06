import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result with data', () {
        // Arrange
        const testData = 'test data';
        
        // Act
        const result = Success(testData);
        
        // Assert
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.dataOrNull, testData);
        expect(result.failureOrNull, null);
      });

      test('should execute success callback in when method', () {
        // Arrange
        const testData = 42;
        const result = Success(testData);
        
        // Act
        final output = result.when(
          success: (data) => 'Success: $data',
          failure: (failure) => 'Failure: ${failure.message}',
        );
        
        // Assert
        expect(output, 'Success: 42');
      });

      test('should map success value correctly', () {
        // Arrange
        const result = Success(5);
        
        // Act
        final mappedResult = result.map((value) => value * 2);
        
        // Assert
        expect(mappedResult.isSuccess, true);
        expect(mappedResult.dataOrNull, 10);
      });
    });

    group('ResultFailure', () {
      test('should create failure result with error', () {
        // Arrange
        const failure = ServerFailure(message: 'Server error');
        
        // Act
        const result = ResultFailure(failure);
        
        // Assert
        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.dataOrNull, null);
        expect(result.failureOrNull, failure);
      });

      test('should execute failure callback in when method', () {
        // Arrange
        const failure = ValidationFailure(message: 'Validation failed');
        const result = ResultFailure<String>(failure);
        
        // Act
        final output = result.when(
          success: (data) => 'Success: $data',
          failure: (failure) => 'Failure: ${failure.message}',
        );
        
        // Assert
        expect(output, 'Failure: Validation failed');
      });

      test('should preserve failure when mapping', () {
        // Arrange
        const failure = NetworkFailure(message: 'No internet');
        const result = ResultFailure<int>(failure);
        
        // Act
        final mappedResult = result.map((value) => value * 2);
        
        // Assert
        expect(mappedResult.isFailure, true);
        expect(mappedResult.failureOrNull, failure);
      });
    });

    group('Equality', () {
      test('should be equal when same success data', () {
        // Arrange
        const result1 = Success('test');
        const result2 = Success('test');
        
        // Assert
        expect(result1, equals(result2));
      });

      test('should be equal when same failure', () {
        // Arrange
        const failure = ServerFailure(message: 'Error');
        const result1 = ResultFailure(failure);
        const result2 = ResultFailure(failure);
        
        // Assert
        expect(result1, equals(result2));
      });
    });
  });
}