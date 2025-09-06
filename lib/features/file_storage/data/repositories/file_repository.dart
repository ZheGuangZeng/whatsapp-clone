import 'dart:io';
import 'dart:typed_data';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/i_file_repository.dart';
import '../sources/file_storage_source.dart';
import '../models/file_model.dart';

/// Implementation of file repository
class FileRepository implements IFileRepository {
  const FileRepository({
    required this.fileStorageSource,
  });

  final FileStorageSource fileStorageSource;

  @override
  Future<Result<FileEntity>> uploadFile(
    File file, {
    required String bucket,
    String? path,
    Function(UploadProgressEntity)? onProgress,
    int compressionQuality = 80,
    bool generateThumbnail = true,
  }) async {
    try {
      // Validate file first
      final validationResult = await validateFile(file, bucket: bucket);
      if (validationResult.isFailure) {
        return ResultFailure(validationResult.failureOrNull!);
      }

      final fileModel = await fileStorageSource.uploadFile(
        file,
        bucket: bucket,
        path: path,
        onProgress: onProgress,
        compressionQuality: compressionQuality,
        generateThumbnail: generateThumbnail,
      );

      return Success(fileModel.toEntity());
    } on StorageException catch (e) {
      return ResultFailure(StorageFailure(e.message));
    } on DatabaseException catch (e) {
      return ResultFailure(DatabaseFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FileEntity>> uploadFromBytes(
    Uint8List bytes, {
    required String fileName,
    required String bucket,
    String? path,
    String? mimeType,
    Function(UploadProgressEntity)? onProgress,
    int compressionQuality = 80,
    bool generateThumbnail = true,
  }) async {
    try {
      final fileModel = await fileStorageSource.uploadFromBytes(
        bytes,
        fileName: fileName,
        bucket: bucket,
        path: path,
        mimeType: mimeType,
        onProgress: onProgress,
        compressionQuality: compressionQuality,
        generateThumbnail: generateThumbnail,
      );

      return Success(fileModel.toEntity());
    } on StorageException catch (e) {
      return ResultFailure(StorageFailure(e.message));
    } on DatabaseException catch (e) {
      return ResultFailure(DatabaseFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<File>> downloadFile(
    FileEntity fileEntity, {
    String? localPath,
    Function(UploadProgressEntity)? onProgress,
  }) async {
    try {
      final fileModel = FileModel.fromEntity(fileEntity);
      final file = await fileStorageSource.downloadFile(
        fileModel,
        localPath: localPath,
        onProgress: onProgress,
      );

      return Success(file);
    } on StorageException catch (e) {
      return ResultFailure(StorageFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Uint8List>> getFileBytes(FileEntity fileEntity) async {
    try {
      final fileModel = FileModel.fromEntity(fileEntity);
      final bytes = await fileStorageSource.getFileBytes(fileModel);

      return Success(bytes);
    } on StorageException catch (e) {
      return ResultFailure(StorageFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<String>> getFileUrl(
    FileEntity fileEntity, {
    Duration? expiresIn,
  }) async {
    try {
      final fileModel = FileModel.fromEntity(fileEntity);
      final url = await fileStorageSource.getFileUrl(
        fileModel,
        expiresIn: expiresIn,
      );

      return Success(url);
    } on StorageException catch (e) {
      return ResultFailure(StorageFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFile(
    FileEntity fileEntity, {
    bool deleteThumbnail = true,
  }) async {
    try {
      final fileModel = FileModel.fromEntity(fileEntity);
      await fileStorageSource.deleteFile(
        fileModel,
        deleteThumbnail: deleteThumbnail,
      );

      return const Success(null);
    } on StorageException catch (e) {
      return ResultFailure(StorageFailure(e.message));
    } on DatabaseException catch (e) {
      return ResultFailure(DatabaseFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FileEntity>> getFileMetadata(String bucket, String path) async {
    try {
      // For now, we'll use fileId since our current implementation uses that
      final fileModel = await fileStorageSource.getFileMetadata(path);

      return Success(fileModel.toEntity());
    } on DatabaseException catch (e) {
      return ResultFailure(DatabaseFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FileEntity>>> listFiles({
    required String bucket,
    String? path,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final fileModels = await fileStorageSource.listFiles(
        bucket: bucket,
        limit: limit,
        offset: offset,
      );

      final entities = fileModels.map((model) => model.toEntity()).toList();
      return Success(entities);
    } on DatabaseException catch (e) {
      return ResultFailure(DatabaseFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FileEntity>>> searchFiles({
    String? uploadedBy,
    FileType? fileType,
    String? bucket,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final fileModels = await fileStorageSource.listFiles(
        uploadedBy: uploadedBy,
        fileType: fileType,
        bucket: bucket,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );

      final entities = fileModels.map((model) => model.toEntity()).toList();
      return Success(entities);
    } on DatabaseException catch (e) {
      return ResultFailure(DatabaseFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<File>> compressImage(
    File file, {
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Use the source's compression through a public method
      // For now, we'll implement basic compression here
      // TODO: Move compression logic to a separate service
      return ResultFailure(const NotImplementedFailure('Image compression not implemented in repository yet'));
    } catch (e) {
      return ResultFailure(ProcessingFailure(e.toString()));
    }
  }

  @override
  Future<Result<File>> generateThumbnail(
    File file, {
    int size = 200,
    int quality = 50,
  }) async {
    try {
      // TODO: Move thumbnail generation to a separate service
      return ResultFailure(const NotImplementedFailure('Thumbnail generation not implemented in repository yet'));
    } catch (e) {
      return ResultFailure(ProcessingFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> validateFile(
    File file, {
    required String bucket,
    int? maxSize,
    List<String>? allowedTypes,
  }) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return ResultFailure(const ValidationFailure(message: 'File does not exist'));
      }

      // Get file info
      final fileStats = await file.stat();
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();

      // Check file size based on bucket
      int sizeLimit;
      switch (bucket) {
        case AppConstants.userAvatarsBucket:
          sizeLimit = maxSize ?? AppConstants.maxAvatarSize;
          break;
        case AppConstants.chatMediaBucket:
          sizeLimit = maxSize ?? AppConstants.maxChatMediaSize;
          break;
        case AppConstants.messageAttachmentsBucket:
          sizeLimit = maxSize ?? AppConstants.maxAttachmentSize;
          break;
        default:
          sizeLimit = maxSize ?? AppConstants.maxChatMediaSize;
      }

      if (fileStats.size > sizeLimit) {
        return ResultFailure(ValidationFailure(message: 
          'File size exceeds limit of ${(sizeLimit / (1024 * 1024)).toStringAsFixed(1)} MB',
        ));
      }

      // Check file type if specified
      if (allowedTypes != null && !allowedTypes.contains(extension)) {
        return ResultFailure(ValidationFailure(message: 
          'File type .$extension is not allowed. Allowed types: ${allowedTypes.join(', ')}',
        ));
      }

      // Check against default supported types
      final allSupportedTypes = [
        ...AppConstants.supportedImageTypes,
        ...AppConstants.supportedVideoTypes,
        ...AppConstants.supportedAudioTypes,
        ...AppConstants.supportedDocumentTypes,
      ];

      if (!allSupportedTypes.contains(extension)) {
        return ResultFailure(ValidationFailure(message: 
          'File type .$extension is not supported',
        ));
      }

      return const Success(null);
    } catch (e) {
      return ResultFailure(ValidationFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> cancelUpload(String fileId) async {
    // TODO: Implement upload cancellation
    // This would require maintaining a map of active uploads
    // and their cancellation tokens
    return ResultFailure(const NotImplementedFailure('Upload cancellation not implemented yet'));
  }

  @override
  Future<Result<void>> pauseUpload(String fileId) async {
    // TODO: Implement upload pause
    // This would require resumable upload support
    return ResultFailure(const NotImplementedFailure('Upload pause not implemented yet'));
  }

  @override
  Future<Result<void>> resumeUpload(String fileId) async {
    // TODO: Implement upload resume
    // This would require resumable upload support  
    return ResultFailure(const NotImplementedFailure('Upload resume not implemented yet'));
  }

  @override
  Future<Result<UploadProgressEntity>> getUploadProgress(String fileId) async {
    // TODO: Implement progress tracking
    // This would require maintaining upload state
    return ResultFailure(const NotImplementedFailure('Upload progress tracking not implemented yet'));
  }

  @override
  Future<Result<int>> cleanupTempFiles({Duration? olderThan}) async {
    try {
      // TODO: Implement temp file cleanup
      // This would clean up old temporary files from local storage
      return const Success(0);
    } catch (e) {
      return ResultFailure(UnknownFailure(message: e.toString()));
    }
  }
}