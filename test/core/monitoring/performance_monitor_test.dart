import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/core/monitoring/performance_monitor.dart';

void main() {
  group('PerformanceMonitor', () {
    late PerformanceMonitor performanceMonitor;

    setUp(() {
      performanceMonitor = PerformanceMonitor();
    });

    tearDown(() {
      performanceMonitor.dispose();
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        // Act
        await performanceMonitor.initialize();

        // Assert
        expect(performanceMonitor.isHealthy, isTrue);
      });

      test('should handle multiple initializations gracefully', () async {
        // Act
        await performanceMonitor.initialize();
        await performanceMonitor.initialize(); // Should not throw

        // Assert
        expect(performanceMonitor.isHealthy, isTrue);
      });
    });

    group('trace management', () {
      test('should start and stop traces successfully', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act
        final trace = await performanceMonitor.startTrace('test_trace');
        expect(trace, isNotNull);

        await performanceMonitor.stopTrace('test_trace');

        // No exception should be thrown
      });

      test('should handle stopping non-existent traces', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act & Assert - should not throw
        await performanceMonitor.stopTrace('non_existent_trace');
      });

      test('should handle starting duplicate traces', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act
        final trace1 = await performanceMonitor.startTrace('duplicate_trace');
        final trace2 = await performanceMonitor.startTrace('duplicate_trace');

        // Assert - should return the same trace
        expect(trace1, equals(trace2));

        await performanceMonitor.stopTrace('duplicate_trace');
      });
    });

    group('operation tracking', () {
      test('should track successful operations', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act
        final result = await performanceMonitor.trackOperation<String>(
          'test_operation',
          () async {
            await Future.delayed(const Duration(milliseconds: 10));
            return 'success';
          },
          metadata: {'test': true},
        );

        // Assert
        expect(result, equals('success'));
      });

      test('should track failed operations', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act & Assert
        expect(
          () => performanceMonitor.trackOperation<void>(
            'failing_operation',
            () async {
              await Future.delayed(const Duration(milliseconds: 5));
              throw Exception('Test exception');
            },
          ),
          throwsException,
        );
      });

      test('should track operations without metadata', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act
        final result = await performanceMonitor.trackOperation<int>(
          'simple_operation',
          () async => 42,
        );

        // Assert
        expect(result, equals(42));
      });
    });

    group('manual timing', () {
      test('should track manual operations successfully', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act & Assert - should not throw
        await performanceMonitor.trackManualOperation(
          'manual_operation',
          const Duration(milliseconds: 100),
          {'custom_metric': 50},
        );
      });

      test('should handle manual operations with null metadata', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act & Assert - should not throw
        await performanceMonitor.trackManualOperation(
          'manual_operation_no_metadata',
          const Duration(milliseconds: 200),
          null,
        );
      });
    });

    group('network tracking', () {
      test('should track network requests successfully', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act & Assert - should not throw
        await performanceMonitor.trackNetworkRequest(
          url: 'https://api.example.com/test',
          httpMethod: 'GET',
          responseCode: 200,
          requestPayloadSize: 1024,
          responsePayloadSize: 2048,
          duration: const Duration(milliseconds: 150),
        );
      });

      test('should handle different HTTP methods', () async {
        // Arrange
        await performanceMonitor.initialize();

        final methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];

        // Act - track requests with different methods
        for (final method in methods) {
          await performanceMonitor.trackNetworkRequest(
            url: 'https://api.example.com/test',
            httpMethod: method,
            responseCode: 200,
            requestPayloadSize: 512,
            responsePayloadSize: 1024,
            duration: const Duration(milliseconds: 100),
          );
        }

        // Assert - no exceptions should be thrown
      });

      test('should handle error response codes', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act & Assert - should not throw
        await performanceMonitor.trackNetworkRequest(
          url: 'https://api.example.com/error',
          httpMethod: 'GET',
          responseCode: 500,
          requestPayloadSize: 0,
          responsePayloadSize: 256,
          duration: const Duration(milliseconds: 5000),
        );
      });
    });

    group('performance statistics', () {
      test('should provide performance statistics', () async {
        // Arrange
        await performanceMonitor.initialize();
        
        // Track some operations to generate stats
        await performanceMonitor.trackManualOperation(
          'stats_test',
          const Duration(milliseconds: 100),
          null,
        );

        // Act
        final stats = performanceMonitor.getPerformanceStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('memory_usage_mb'), isTrue);
        expect(stats.containsKey('peak_memory_usage_mb'), isTrue);
        expect(stats.containsKey('current_fps'), isTrue);
        expect(stats.containsKey('active_traces'), isTrue);
        expect(stats.containsKey('operation_stats'), isTrue);
      });

      test('should track operation statistics over time', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act - track multiple operations
        for (int i = 0; i < 5; i++) {
          await performanceMonitor.trackManualOperation(
            'repeated_operation',
            Duration(milliseconds: 50 + i * 10),
            {'iteration': i},
          );
        }

        final stats = performanceMonitor.getPerformanceStats();

        // Assert
        final operationStats = stats['operation_stats'] as Map<String, dynamic>;
        expect(operationStats.containsKey('repeated_operation'), isTrue);

        final repeatStats = operationStats['repeated_operation'] as Map<String, dynamic>;
        expect(repeatStats['count'], equals(5));
        expect(repeatStats.containsKey('avg_ms'), isTrue);
        expect(repeatStats.containsKey('min_ms'), isTrue);
        expect(repeatStats.containsKey('max_ms'), isTrue);
        expect(repeatStats.containsKey('p95_ms'), isTrue);
      });
    });

    group('memory constraints', () {
      test('should limit stored operation times to prevent memory leaks', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act - track more than 100 operations (the limit)
        for (int i = 0; i < 150; i++) {
          await performanceMonitor.trackManualOperation(
            'memory_limit_test',
            Duration(milliseconds: i + 1),
            null,
          );
        }

        final stats = performanceMonitor.getPerformanceStats();
        final operationStats = stats['operation_stats'] as Map<String, dynamic>;
        final memoryTestStats = operationStats['memory_limit_test'] as Map<String, dynamic>;

        // Assert - should not store more than 100 measurements
        expect(memoryTestStats['count'], lessThanOrEqualTo(100));
      });
    });

    group('lifecycle management', () {
      test('should dispose cleanly', () async {
        // Arrange
        await performanceMonitor.initialize();
        await performanceMonitor.startTrace('test_trace');

        // Act & Assert - should not throw
        expect(() => performanceMonitor.dispose(), returnsNormally);
      });

      test('should handle operations after disposal', () async {
        // Arrange
        await performanceMonitor.initialize();
        performanceMonitor.dispose();

        // Act - operations after disposal should be no-ops
        final trace = await performanceMonitor.startTrace('after_dispose');
        expect(trace, isNull);

        await performanceMonitor.stopTrace('after_dispose');
        // Should not throw
      });
    });

    group('concurrent operations', () {
      test('should handle concurrent trace operations', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act - start multiple traces concurrently
        final futures = List.generate(10, (i) => 
          performanceMonitor.startTrace('concurrent_trace_$i'));

        final traces = await Future.wait(futures);

        // Stop all traces
        final stopFutures = List.generate(10, (i) => 
          performanceMonitor.stopTrace('concurrent_trace_$i'));

        await Future.wait(stopFutures);

        // Assert - all traces should have been created
        expect(traces.where((t) => t != null).length, equals(10));
      });

      test('should handle concurrent operation tracking', () async {
        // Arrange
        await performanceMonitor.initialize();

        // Act - track multiple operations concurrently
        final futures = List.generate(10, (i) => 
          performanceMonitor.trackOperation<int>(
            'concurrent_operation_$i',
            () async {
              await Future.delayed(Duration(milliseconds: 10 + i));
              return i;
            },
          ));

        final results = await Future.wait(futures);

        // Assert - all operations should complete successfully
        expect(results.length, equals(10));
        for (int i = 0; i < 10; i++) {
          expect(results[i], equals(i));
        }
      });
    });

    group('error handling', () {
      test('should handle initialization failure gracefully', () async {
        // This is hard to test without mocking the underlying services
        // For now, test that multiple initializations don't cause issues
        
        await performanceMonitor.initialize();
        await performanceMonitor.initialize(); // Should not throw
        
        expect(performanceMonitor.isHealthy, isTrue);
      });

      test('should handle operations when not initialized', () async {
        // Act & Assert - operations on uninitialized monitor should not throw
        final trace = await performanceMonitor.startTrace('not_initialized');
        expect(trace, isNull);

        await performanceMonitor.stopTrace('not_initialized');

        await performanceMonitor.trackManualOperation(
          'not_initialized',
          const Duration(milliseconds: 1),
          null,
        );

        // No exceptions should be thrown
      });
    });
  });
}