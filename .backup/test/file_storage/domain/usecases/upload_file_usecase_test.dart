import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/file_storage/domain/entities/file_entity.dart';
import 'package:whatsapp_clone/features/file_storage/domain/repositories/i_file_repository.dart';
import 'package:whatsapp_clone/features/file_storage/domain/usecases/upload_file_usecase.dart';

class MockFileRepository extends Mock implements IFileRepository {}
class MockFile extends Mock implements File {}

void main() {
  late MockFileRepository mockFileRepository;
  late UploadFileUseCase uploadFileUseCase;
  late MockFile mockFile;
  late FileEntity testFileEntity;

  setUpAll(() {
    registerFallbackValue(MockFile());
  });

  setUp(() {
    mockFileRepository = MockFileRepository();
    uploadFileUseCase = UploadFileUseCase(fileRepository: mockFileRepository);
    mockFile = MockFile();

    testFileEntity = FileEntity(
      id: 'test-file-id',
      filename: 'test_image.jpg',
      originalName: 'my_photo.jpg',
      fileType: FileType.image,
      fileSize: 1024,
      storagePath: 'images/test_image.jpg',
      uploadedBy: 'user-123',
      uploadedAt: DateTime(2023, 1, 1),
    );
  });

  group('UploadFileUseCase', () {
    test('should upload file successfully', () async {
      // Arrange
      final params = UploadFileParams(
        file: mockFile,
        bucket: 'test-bucket',
        compressionQuality: 80,
        generateThumbnail: true,
      );

      when(() => mockFileRepository.uploadFile(
            any(),
            bucket: any(named: 'bucket'),
            path: any(named: 'path'),
            onProgress: any(named: 'onProgress'),
            compressionQuality: any(named: 'compressionQuality'),
            generateThumbnail: any(named: 'generateThumbnail'),
          )).thenAnswer((_) async => Success(testFileEntity));

      // Act
      final result = await uploadFileUseCase(params);

      // Assert
      expect(result.isSuccess, true);
      expect(result.dataOrNull, testFileEntity);

      verify(() => mockFileRepository.uploadFile(
            mockFile,
            bucket: 'test-bucket',
            path: null,
            onProgress: null,
            compressionQuality: 80,
            generateThumbnail: true,
          )).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      final params = UploadFileParams(
        file: mockFile,
        bucket: 'test-bucket',
      );

      const failure = StorageFailure('Upload failed');
      when(() => mockFileRepository.uploadFile(
            any(),
            bucket: any(named: 'bucket'),
            path: any(named: 'path'),
            onProgress: any(named: 'onProgress'),
            compressionQuality: any(named: 'compressionQuality'),
            generateThumbnail: any(named: 'generateThumbnail'),
          )).thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await uploadFileUseCase(params);

      // Assert
      expect(result.isFailure, true);
      expect(result.failureOrNull, failure);
    });

    test('should pass all parameters correctly', () async {
      // Arrange
      var progressCalled = false;
      void onProgress(UploadProgressEntity progress) {
        progressCalled = true;
      }

      final params = UploadFileParams(
        file: mockFile,
        bucket: 'custom-bucket',
        path: 'custom/path',
        onProgress: onProgress,
        compressionQuality: 90,
        generateThumbnail: false,
      );

      when(() => mockFileRepository.uploadFile(
            any(),
            bucket: any(named: 'bucket'),
            path: any(named: 'path'),
            onProgress: any(named: 'onProgress'),
            compressionQuality: any(named: 'compressionQuality'),
            generateThumbnail: any(named: 'generateThumbnail'),
          )).thenAnswer((invocation) async {
        // Simulate progress callback
        final progressCallback = invocation.namedArguments[#onProgress] as Function(UploadProgressEntity)?;
        progressCallback?.call(const UploadProgressEntity(
          fileId: 'test-id',
          uploadedBytes: 50,
          totalBytes: 100,
          status: UploadStatus.uploading,
        ));
        return Success(testFileEntity);
      });

      // Act
      final result = await uploadFileUseCase(params);

      // Assert
      expect(result.isSuccess, true);
      expect(progressCalled, true);

      verify(() => mockFileRepository.uploadFile(
            mockFile,
            bucket: 'custom-bucket',
            path: 'custom/path',
            onProgress: any(named: 'onProgress'),
            compressionQuality: 90,
            generateThumbnail: false,
          )).called(1);
    });
  });

  group('UploadFileParams', () {
    test('should create with default values', () {
      final params = UploadFileParams(
        file: mockFile,
        bucket: 'test-bucket',
      );

      expect(params.file, mockFile);
      expect(params.bucket, 'test-bucket');
      expect(params.path, null);
      expect(params.onProgress, null);
      expect(params.compressionQuality, 80);
      expect(params.generateThumbnail, true);
    });

    test('should create with custom values', () {
      void onProgress(UploadProgressEntity progress) {}

      final params = UploadFileParams(
        file: mockFile,
        bucket: 'custom-bucket',
        path: 'custom/path',
        onProgress: onProgress,
        compressionQuality: 90,
        generateThumbnail: false,
      );

      expect(params.file, mockFile);
      expect(params.bucket, 'custom-bucket');
      expect(params.path, 'custom/path');
      expect(params.onProgress, onProgress);
      expect(params.compressionQuality, 90);
      expect(params.generateThumbnail, false);
    });
  });
}