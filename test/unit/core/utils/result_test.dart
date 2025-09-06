import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should return true for isSuccess', () {
        const result = Success<String>('test data');
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
      });

      test('should return data when calling dataOrNull', () {
        const testData = 'test data';
        const result = Success<String>(testData);
        expect(result.dataOrNull, testData);
      });

      test('should return null when calling failureOrNull', () {
        const result = Success<String>('test data');
        expect(result.failureOrNull, null);
      });

      test('should call success callback in when method', () {
        const testData = 'test data';
        const result = Success<String>(testData);
        
        final output = result.when(
          success: (String data) => 'Success: $data',
          failure: (Failure failure) => 'Failure: ${failure.message}',
        );
        
        expect(output, 'Success: $testData');
      });

      test('should transform data in map method', () {
        const result = Success<int>(42);
        final mapped = result.map((data) => data.toString());
        
        expect(mapped.isSuccess, true);
        expect(mapped.dataOrNull, '42');
      });
    });

    group('ResultFailure', () {
      test('should return false for isSuccess', () {
        const failure = ServerFailure(message: 'Test error');
        const result = ResultFailure<String>(failure);
        expect(result.isSuccess, false);
        expect(result.isFailure, true);
      });

      test('should return null when calling dataOrNull', () {
        const failure = ServerFailure(message: 'Test error');
        const result = ResultFailure<String>(failure);
        expect(result.dataOrNull, null);
      });

      test('should return failure when calling failureOrNull', () {
        const failure = ServerFailure(message: 'Test error');
        const result = ResultFailure<String>(failure);
        expect(result.failureOrNull, failure);
      });

      test('should call failure callback in when method', () {
        const failure = ServerFailure(message: 'Test error');
        const result = ResultFailure<String>(failure);
        
        final output = result.when(
          success: (String data) => 'Success: $data',
          failure: (Failure failure) => 'Failure: ${failure.message}',
        );
        
        expect(output, 'Failure: Test error');
      });

      test('should preserve failure in map method', () {
        const failure = ServerFailure(message: 'Test error');
        const result = ResultFailure<int>(failure);
        final mapped = result.map((int data) => data.toString());
        
        expect(mapped.isFailure, true);
        expect(mapped.failureOrNull, failure);
      });
    });
  });
}