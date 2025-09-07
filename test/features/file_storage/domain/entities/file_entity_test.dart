import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/file_storage/domain/entities/file_entity.dart';

void main() {
  group('FileEntity', () {
    final testFileEntity = FileEntity(
      id: 'file_123',
      filename: 'test_file_processed.jpg',
      originalName: 'test_file.jpg',
      fileType: FileType.image,
      fileSize: 1024000, // 1MB
      storagePath: 'files/2024/01/test_file_processed.jpg',
      thumbnailPath: 'files/2024/01/thumbnails/test_file_thumb.jpg',
      uploadedBy: 'user_123',
      uploadedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      metadata: const {'width': 1920, 'height': 1080, 'camera': 'iPhone 15'},
      mimeType: 'image/jpeg',
      checksum: 'sha256:abc123def456',
      compressionRatio: 0.8,
      uploadStatus: UploadStatus.completed,
      uploadProgress: 100.0,
    );

    group('constructor', () {
      test('should create FileEntity with all required properties', () {
        expect(testFileEntity.id, equals('file_123'));
        expect(testFileEntity.filename, equals('test_file_processed.jpg'));
        expect(testFileEntity.originalName, equals('test_file.jpg'));
        expect(testFileEntity.fileType, equals(FileType.image));
        expect(testFileEntity.fileSize, equals(1024000));
        expect(testFileEntity.storagePath, equals('files/2024/01/test_file_processed.jpg'));
        expect(testFileEntity.uploadedBy, equals('user_123'));
        expect(testFileEntity.uploadedAt, equals(DateTime.parse('2024-01-15T10:30:00Z')));
      });

      test('should create FileEntity with default values for optional properties', () {
        final minimalEntity = FileEntity(
          id: 'file_456',
          filename: 'minimal.pdf',
          originalName: 'minimal.pdf',
          fileType: FileType.document,
          fileSize: 50000,
          storagePath: 'files/minimal.pdf',
          uploadedBy: 'user_456',
          uploadedAt: DateTime.parse('2024-01-16T11:00:00Z'),
        );

        expect(minimalEntity.thumbnailPath, isNull);
        expect(minimalEntity.metadata, equals(const <String, dynamic>{}));
        expect(minimalEntity.mimeType, isNull);
        expect(minimalEntity.checksum, isNull);
        expect(minimalEntity.compressionRatio, isNull);
        expect(minimalEntity.uploadStatus, equals(UploadStatus.completed));
        expect(minimalEntity.uploadProgress, equals(100.0));
      });
    });

    group('FileType enum', () {
      test('should correctly identify file type from extension', () {
        expect(FileType.fromExtension('jpg'), equals(FileType.image));
        expect(FileType.fromExtension('PNG'), equals(FileType.image));
        expect(FileType.fromExtension('mp4'), equals(FileType.video));
        expect(FileType.fromExtension('MOV'), equals(FileType.video));
        expect(FileType.fromExtension('mp3'), equals(FileType.audio));
        expect(FileType.fromExtension('WAV'), equals(FileType.audio));
        expect(FileType.fromExtension('pdf'), equals(FileType.document));
        expect(FileType.fromExtension('DOCX'), equals(FileType.document));
        expect(FileType.fromExtension('unknown'), equals(FileType.other));
      });

      test('should convert from string value', () {
        expect(FileType.fromString('image'), equals(FileType.image));
        expect(FileType.fromString('video'), equals(FileType.video));
        expect(FileType.fromString('audio'), equals(FileType.audio));
        expect(FileType.fromString('document'), equals(FileType.document));
        expect(FileType.fromString('other'), equals(FileType.other));
        expect(FileType.fromString('invalid'), equals(FileType.other));
      });
    });

    group('UploadStatus enum', () {
      test('should convert from string value', () {
        expect(UploadStatus.fromString('pending'), equals(UploadStatus.pending));
        expect(UploadStatus.fromString('uploading'), equals(UploadStatus.uploading));
        expect(UploadStatus.fromString('processing'), equals(UploadStatus.processing));
        expect(UploadStatus.fromString('completed'), equals(UploadStatus.completed));
        expect(UploadStatus.fromString('failed'), equals(UploadStatus.failed));
        expect(UploadStatus.fromString('cancelled'), equals(UploadStatus.cancelled));
        expect(UploadStatus.fromString('invalid'), equals(UploadStatus.pending));
      });
    });

    group('computed properties', () {
      test('should extract file extension correctly', () {
        expect(testFileEntity.extension, equals('jpg'));
        
        final noExtEntity = FileEntity(
          id: 'file_no_ext',
          filename: 'noextfile',
          originalName: 'noextfile',
          fileType: FileType.other,
          fileSize: 100,
          storagePath: 'files/noextfile',
          uploadedBy: 'user_123',
          uploadedAt: DateTime.parse('2024-01-15T10:30:00Z'),
        );
        expect(noExtEntity.extension, equals(''));
      });

      test('should identify if file has thumbnail', () {
        expect(testFileEntity.hasThumbnail, isTrue);
        
        final noThumbEntity = FileEntity(
          id: 'file_no_thumb',
          filename: 'nothumb.pdf',
          originalName: 'nothumb.pdf',
          fileType: FileType.document,
          fileSize: 100,
          storagePath: 'files/nothumb.pdf',
          uploadedBy: 'user_123',
          uploadedAt: DateTime.parse('2024-01-15T10:30:00Z'),
        );
        expect(noThumbEntity.hasThumbnail, isFalse);
      });

      test('should identify file types correctly', () {
        expect(testFileEntity.isImage, isTrue);
        expect(testFileEntity.isVideo, isFalse);
        expect(testFileEntity.isAudio, isFalse);
        expect(testFileEntity.isDocument, isFalse);
      });

      test('should identify upload status correctly', () {
        expect(testFileEntity.isUploading, isFalse);
        expect(testFileEntity.isCompleted, isTrue);
        expect(testFileEntity.isFailed, isFalse);

        final uploadingEntity = testFileEntity.copyWith(
          uploadStatus: UploadStatus.uploading,
          uploadProgress: 50.0,
        );
        expect(uploadingEntity.isUploading, isTrue);
        expect(uploadingEntity.isCompleted, isFalse);
      });

      test('should format file size correctly', () {
        final bytesEntity = FileEntity(
          id: 'small',
          filename: 'small.txt',
          originalName: 'small.txt',
          fileType: FileType.document,
          fileSize: 512,
          storagePath: 'files/small.txt',
          uploadedBy: 'user_123',
          uploadedAt: DateTime.parse('2024-01-15T10:30:00Z'),
        );
        expect(bytesEntity.formattedSize, equals('512 B'));

        final kbEntity = bytesEntity.copyWith(fileSize: 2048);
        expect(kbEntity.formattedSize, equals('2.0 KB'));

        expect(testFileEntity.formattedSize, equals('1000.0 KB'));

        final gbEntity = bytesEntity.copyWith(fileSize: 2147483648);
        expect(gbEntity.formattedSize, equals('2.0 GB'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedEntity = testFileEntity.copyWith(
          uploadStatus: UploadStatus.uploading,
          uploadProgress: 75.0,
        );

        expect(updatedEntity.id, equals(testFileEntity.id));
        expect(updatedEntity.filename, equals(testFileEntity.filename));
        expect(updatedEntity.uploadStatus, equals(UploadStatus.uploading));
        expect(updatedEntity.uploadProgress, equals(75.0));
      });

      test('should preserve original values when no updates provided', () {
        final copiedEntity = testFileEntity.copyWith();

        expect(copiedEntity, equals(testFileEntity));
        expect(copiedEntity.hashCode, equals(testFileEntity.hashCode));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final otherEntity = FileEntity(
          id: 'file_123',
          filename: 'test_file_processed.jpg',
          originalName: 'test_file.jpg',
          fileType: FileType.image,
          fileSize: 1024000,
          storagePath: 'files/2024/01/test_file_processed.jpg',
          thumbnailPath: 'files/2024/01/thumbnails/test_file_thumb.jpg',
          uploadedBy: 'user_123',
          uploadedAt: DateTime.parse('2024-01-15T10:30:00Z'),
          metadata: const {'width': 1920, 'height': 1080, 'camera': 'iPhone 15'},
          mimeType: 'image/jpeg',
          checksum: 'sha256:abc123def456',
          compressionRatio: 0.8,
          uploadStatus: UploadStatus.completed,
          uploadProgress: 100.0,
        );

        expect(testFileEntity, equals(otherEntity));
        expect(testFileEntity.hashCode, equals(otherEntity.hashCode));
      });

      test('should not be equal when properties differ', () {
        final differentEntity = testFileEntity.copyWith(id: 'different_id');

        expect(testFileEntity, isNot(equals(differentEntity)));
        expect(testFileEntity.hashCode, isNot(equals(differentEntity.hashCode)));
      });
    });
  });

  group('UploadProgressEntity', () {
    const testProgress = UploadProgressEntity(
      fileId: 'file_123',
      uploadedBytes: 512000,
      totalBytes: 1024000,
      status: UploadStatus.uploading,
      error: null,
      eta: Duration(seconds: 30),
      speed: 17000.0,
    );

    group('constructor', () {
      test('should create UploadProgressEntity with all properties', () {
        expect(testProgress.fileId, equals('file_123'));
        expect(testProgress.uploadedBytes, equals(512000));
        expect(testProgress.totalBytes, equals(1024000));
        expect(testProgress.status, equals(UploadStatus.uploading));
        expect(testProgress.eta, equals(const Duration(seconds: 30)));
        expect(testProgress.speed, equals(17000.0));
      });
    });

    group('computed properties', () {
      test('should calculate progress percentage correctly', () {
        expect(testProgress.progress, equals(50.0));
        
        const completedProgress = UploadProgressEntity(
          fileId: 'file_456',
          uploadedBytes: 1000,
          totalBytes: 1000,
          status: UploadStatus.completed,
        );
        expect(completedProgress.progress, equals(100.0));

        const zeroTotalProgress = UploadProgressEntity(
          fileId: 'file_789',
          uploadedBytes: 0,
          totalBytes: 0,
          status: UploadStatus.pending,
        );
        expect(zeroTotalProgress.progress, equals(0.0));
      });

      test('should identify completion status correctly', () {
        expect(testProgress.isComplete, isFalse);
        expect(testProgress.hasFailed, isFalse);

        final completedProgress = testProgress.copyWith(status: UploadStatus.completed);
        expect(completedProgress.isComplete, isTrue);

        final failedProgress = testProgress.copyWith(status: UploadStatus.failed);
        expect(failedProgress.hasFailed, isTrue);
      });

      test('should format speed correctly', () {
        expect(testProgress.formattedSpeed, equals('16.6 KB/s'));

        final slowProgress = testProgress.copyWith(speed: 500.0);
        expect(slowProgress.formattedSpeed, equals('500 B/s'));

        final fastProgress = testProgress.copyWith(speed: 2097152.0);
        expect(fastProgress.formattedSpeed, equals('2.0 MB/s'));

        const noSpeedProgress = UploadProgressEntity(
          fileId: 'file_no_speed',
          uploadedBytes: 500,
          totalBytes: 1000,
          status: UploadStatus.uploading,
          // speed is not provided, so it will be null
        );
        expect(noSpeedProgress.formattedSpeed, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedProgress = testProgress.copyWith(
          uploadedBytes: 768000,
          status: UploadStatus.processing,
        );

        expect(updatedProgress.fileId, equals(testProgress.fileId));
        expect(updatedProgress.uploadedBytes, equals(768000));
        expect(updatedProgress.totalBytes, equals(testProgress.totalBytes));
        expect(updatedProgress.status, equals(UploadStatus.processing));
        expect(updatedProgress.speed, equals(testProgress.speed));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        const otherProgress = UploadProgressEntity(
          fileId: 'file_123',
          uploadedBytes: 512000,
          totalBytes: 1024000,
          status: UploadStatus.uploading,
          error: null,
          eta: Duration(seconds: 30),
          speed: 17000.0,
        );

        expect(testProgress, equals(otherProgress));
      });

      test('should not be equal when properties differ', () {
        final differentProgress = testProgress.copyWith(uploadedBytes: 400000);

        expect(testProgress, isNot(equals(differentProgress)));
      });
    });
  });
}