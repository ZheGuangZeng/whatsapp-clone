import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/file_storage/domain/entities/file_entity.dart';

void main() {
  group('FileEntity', () {
    late FileEntity fileEntity;

    setUp(() {
      fileEntity = FileEntity(
        id: 'test-file-id',
        filename: 'test_image.jpg',
        originalName: 'my_photo.jpg',
        fileType: FileType.image,
        fileSize: 1024,
        storagePath: 'images/test_image.jpg',
        thumbnailPath: 'thumbnails/test_image_thumb.jpg',
        uploadedBy: 'user-123',
        uploadedAt: DateTime(2023, 1, 1),
        metadata: {'camera': 'iPhone'},
        mimeType: 'image/jpeg',
        checksum: 'abc123',
        compressionRatio: 0.8,
        uploadStatus: UploadStatus.completed,
        uploadProgress: 100.0,
      );
    });

    test('should create file entity with all properties', () {
      expect(fileEntity.id, 'test-file-id');
      expect(fileEntity.filename, 'test_image.jpg');
      expect(fileEntity.originalName, 'my_photo.jpg');
      expect(fileEntity.fileType, FileType.image);
      expect(fileEntity.fileSize, 1024);
      expect(fileEntity.storagePath, 'images/test_image.jpg');
      expect(fileEntity.thumbnailPath, 'thumbnails/test_image_thumb.jpg');
      expect(fileEntity.uploadedBy, 'user-123');
      expect(fileEntity.uploadedAt, DateTime(2023, 1, 1));
      expect(fileEntity.metadata, {'camera': 'iPhone'});
      expect(fileEntity.mimeType, 'image/jpeg');
      expect(fileEntity.checksum, 'abc123');
      expect(fileEntity.compressionRatio, 0.8);
      expect(fileEntity.uploadStatus, UploadStatus.completed);
      expect(fileEntity.uploadProgress, 100.0);
    });

    test('should have correct extension getter', () {
      expect(fileEntity.extension, 'jpg');
    });

    test('should have correct thumbnail check', () {
      expect(fileEntity.hasThumbnail, true);
      
      final fileWithoutThumbnail = fileEntity.copyWith(thumbnailPath: '');
      expect(fileWithoutThumbnail.hasThumbnail, false);
    });

    test('should have correct file type checks', () {
      expect(fileEntity.isImage, true);
      expect(fileEntity.isVideo, false);
      expect(fileEntity.isAudio, false);
      expect(fileEntity.isDocument, false);
    });

    test('should have correct upload status checks', () {
      expect(fileEntity.isUploading, false);
      expect(fileEntity.isCompleted, true);
      expect(fileEntity.isFailed, false);

      final uploadingFile = fileEntity.copyWith(uploadStatus: UploadStatus.uploading);
      expect(uploadingFile.isUploading, true);
      expect(uploadingFile.isCompleted, false);

      final failedFile = fileEntity.copyWith(uploadStatus: UploadStatus.failed);
      expect(failedFile.isFailed, true);
      expect(failedFile.isCompleted, false);
    });

    test('should format file size correctly', () {
      final smallFile = fileEntity.copyWith(fileSize: 512);
      expect(smallFile.formattedSize, '512 B');

      final kbFile = fileEntity.copyWith(fileSize: 2048);
      expect(kbFile.formattedSize, '2.0 KB');

      final mbFile = fileEntity.copyWith(fileSize: 5242880);
      expect(mbFile.formattedSize, '5.0 MB');

      final gbFile = fileEntity.copyWith(fileSize: 1073741824);
      expect(gbFile.formattedSize, '1.0 GB');
    });

    test('should create copy with updated fields', () {
      final copiedFile = fileEntity.copyWith(
        filename: 'updated_image.jpg',
        fileSize: 2048,
      );

      expect(copiedFile.filename, 'updated_image.jpg');
      expect(copiedFile.fileSize, 2048);
      expect(copiedFile.originalName, fileEntity.originalName); // unchanged
      expect(copiedFile.id, fileEntity.id); // unchanged
    });
  });

  group('FileType', () {
    test('should create from string correctly', () {
      expect(FileType.fromString('image'), FileType.image);
      expect(FileType.fromString('video'), FileType.video);
      expect(FileType.fromString('audio'), FileType.audio);
      expect(FileType.fromString('document'), FileType.document);
      expect(FileType.fromString('other'), FileType.other);
      expect(FileType.fromString('invalid'), FileType.other); // fallback
    });

    test('should create from extension correctly', () {
      expect(FileType.fromExtension('jpg'), FileType.image);
      expect(FileType.fromExtension('jpeg'), FileType.image);
      expect(FileType.fromExtension('png'), FileType.image);
      expect(FileType.fromExtension('webp'), FileType.image);
      expect(FileType.fromExtension('gif'), FileType.image);

      expect(FileType.fromExtension('mp4'), FileType.video);
      expect(FileType.fromExtension('mov'), FileType.video);
      expect(FileType.fromExtension('avi'), FileType.video);
      expect(FileType.fromExtension('webm'), FileType.video);

      expect(FileType.fromExtension('mp3'), FileType.audio);
      expect(FileType.fromExtension('wav'), FileType.audio);
      expect(FileType.fromExtension('m4a'), FileType.audio);
      expect(FileType.fromExtension('aac'), FileType.audio);

      expect(FileType.fromExtension('pdf'), FileType.document);
      expect(FileType.fromExtension('doc'), FileType.document);
      expect(FileType.fromExtension('docx'), FileType.document);
      expect(FileType.fromExtension('xls'), FileType.document);
      expect(FileType.fromExtension('xlsx'), FileType.document);
      expect(FileType.fromExtension('ppt'), FileType.document);
      expect(FileType.fromExtension('pptx'), FileType.document);
      expect(FileType.fromExtension('txt'), FileType.document);

      expect(FileType.fromExtension('unknown'), FileType.other);
    });
  });

  group('UploadStatus', () {
    test('should create from string correctly', () {
      expect(UploadStatus.fromString('pending'), UploadStatus.pending);
      expect(UploadStatus.fromString('uploading'), UploadStatus.uploading);
      expect(UploadStatus.fromString('processing'), UploadStatus.processing);
      expect(UploadStatus.fromString('completed'), UploadStatus.completed);
      expect(UploadStatus.fromString('failed'), UploadStatus.failed);
      expect(UploadStatus.fromString('cancelled'), UploadStatus.cancelled);
      expect(UploadStatus.fromString('invalid'), UploadStatus.pending); // fallback
    });
  });

  group('UploadProgressEntity', () {
    late UploadProgressEntity progressEntity;

    setUp(() {
      progressEntity = UploadProgressEntity(
        fileId: 'file-123',
        uploadedBytes: 500,
        totalBytes: 1000,
        status: UploadStatus.uploading,
        error: null,
        eta: Duration(seconds: 30),
        speed: 16.67,
      );
    });

    test('should create upload progress entity with all properties', () {
      expect(progressEntity.fileId, 'file-123');
      expect(progressEntity.uploadedBytes, 500);
      expect(progressEntity.totalBytes, 1000);
      expect(progressEntity.status, UploadStatus.uploading);
      expect(progressEntity.error, null);
      expect(progressEntity.eta, Duration(seconds: 30));
      expect(progressEntity.speed, 16.67);
    });

    test('should calculate progress correctly', () {
      expect(progressEntity.progress, 50.0);

      final zeroTotalProgress = progressEntity.copyWith(totalBytes: 0);
      expect(zeroTotalProgress.progress, 0.0);
    });

    test('should have correct status checks', () {
      expect(progressEntity.isComplete, false);
      expect(progressEntity.hasFailed, false);

      final completedProgress = progressEntity.copyWith(status: UploadStatus.completed);
      expect(completedProgress.isComplete, true);

      final failedProgress = progressEntity.copyWith(status: UploadStatus.failed);
      expect(failedProgress.hasFailed, true);
    });

    test('should format speed correctly', () {
      expect(progressEntity.formattedSpeed, '17 B/s');

      final kbProgress = progressEntity.copyWith(speed: 1536.0);
      expect(kbProgress.formattedSpeed, '1.5 KB/s');

      final mbProgress = progressEntity.copyWith(speed: 2097152.0);
      expect(mbProgress.formattedSpeed, '2.0 MB/s');

      final nullSpeedProgress = UploadProgressEntity(
        fileId: 'test',
        uploadedBytes: 0,
        totalBytes: 100,
        status: UploadStatus.uploading,
        speed: null,
      );
      expect(nullSpeedProgress.formattedSpeed, null);
    });

    test('should create copy with updated fields', () {
      final copiedProgress = progressEntity.copyWith(
        uploadedBytes: 750,
        speed: 25.0,
      );

      expect(copiedProgress.uploadedBytes, 750);
      expect(copiedProgress.speed, 25.0);
      expect(copiedProgress.totalBytes, progressEntity.totalBytes); // unchanged
      expect(copiedProgress.fileId, progressEntity.fileId); // unchanged
    });
  });
}