import 'dart:io';
import 'dart:typed_data';
import '../../../../core/utils/result.dart';
import '../entities/file_entity.dart';

/// Repository interface for file storage operations
abstract interface class IFileRepository {
  /// Upload a file to storage
  /// 
  /// [file] - The file to upload
  /// [bucket] - Storage bucket name
  /// [path] - Storage path (optional, will generate if not provided)
  /// [onProgress] - Callback for upload progress updates
  /// [compressionQuality] - Image compression quality (0-100, only for images)
  /// [generateThumbnail] - Whether to generate thumbnail for images/videos
  Future<Result<FileEntity>> uploadFile(
    File file, {
    required String bucket,
    String? path,
    Function(UploadProgressEntity)? onProgress,
    int compressionQuality = 80,
    bool generateThumbnail = true,
  });

  /// Upload file from bytes
  /// 
  /// [bytes] - File data as bytes
  /// [fileName] - Original filename
  /// [bucket] - Storage bucket name
  /// [path] - Storage path (optional, will generate if not provided)
  /// [mimeType] - MIME type of the file
  /// [onProgress] - Callback for upload progress updates
  /// [compressionQuality] - Image compression quality (0-100, only for images)
  /// [generateThumbnail] - Whether to generate thumbnail for images/videos
  Future<Result<FileEntity>> uploadFromBytes(
    Uint8List bytes, {
    required String fileName,
    required String bucket,
    String? path,
    String? mimeType,
    Function(UploadProgressEntity)? onProgress,
    int compressionQuality = 80,
    bool generateThumbnail = true,
  });

  /// Download a file from storage
  /// 
  /// [fileEntity] - The file entity to download
  /// [localPath] - Where to save the file locally
  /// [onProgress] - Callback for download progress updates
  Future<Result<File>> downloadFile(
    FileEntity fileEntity, {
    String? localPath,
    Function(UploadProgressEntity)? onProgress,
  });

  /// Get file as bytes without saving to disk
  /// 
  /// [fileEntity] - The file entity to get
  Future<Result<Uint8List>> getFileBytes(FileEntity fileEntity);

  /// Get public URL for a file
  /// 
  /// [fileEntity] - The file entity
  /// [expiresIn] - URL expiration time (optional)
  Future<Result<String>> getFileUrl(
    FileEntity fileEntity, {
    Duration? expiresIn,
  });

  /// Delete a file from storage
  /// 
  /// [fileEntity] - The file entity to delete
  /// [deleteThumbnail] - Whether to also delete the thumbnail
  Future<Result<void>> deleteFile(
    FileEntity fileEntity, {
    bool deleteThumbnail = true,
  });

  /// Get file metadata from storage
  /// 
  /// [bucket] - Storage bucket name
  /// [path] - File path in bucket
  Future<Result<FileEntity>> getFileMetadata(String bucket, String path);

  /// List files in a bucket/path
  /// 
  /// [bucket] - Storage bucket name
  /// [path] - Path prefix to filter by
  /// [limit] - Maximum number of files to return
  /// [offset] - Number of files to skip
  Future<Result<List<FileEntity>>> listFiles({
    required String bucket,
    String? path,
    int limit = 50,
    int offset = 0,
  });

  /// Search files by criteria
  /// 
  /// [uploadedBy] - Filter by user ID
  /// [fileType] - Filter by file type
  /// [bucket] - Filter by storage bucket
  /// [fromDate] - Filter files uploaded after this date
  /// [toDate] - Filter files uploaded before this date
  /// [limit] - Maximum number of files to return
  /// [offset] - Number of files to skip
  Future<Result<List<FileEntity>>> searchFiles({
    String? uploadedBy,
    FileType? fileType,
    String? bucket,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  });

  /// Compress an image file
  /// 
  /// [file] - The image file to compress
  /// [quality] - Compression quality (0-100)
  /// [maxWidth] - Maximum width (optional)
  /// [maxHeight] - Maximum height (optional)
  Future<Result<File>> compressImage(
    File file, {
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  });

  /// Generate thumbnail for image or video
  /// 
  /// [file] - The source file
  /// [size] - Thumbnail size (square)
  /// [quality] - Thumbnail quality (0-100)
  Future<Result<File>> generateThumbnail(
    File file, {
    int size = 200,
    int quality = 50,
  });

  /// Validate file before upload
  /// 
  /// [file] - The file to validate
  /// [bucket] - Target storage bucket
  /// [maxSize] - Maximum allowed file size
  /// [allowedTypes] - List of allowed file extensions
  Future<Result<void>> validateFile(
    File file, {
    required String bucket,
    int? maxSize,
    List<String>? allowedTypes,
  });

  /// Cancel an ongoing upload
  /// 
  /// [fileId] - ID of the file being uploaded
  Future<Result<void>> cancelUpload(String fileId);

  /// Pause an ongoing upload
  /// 
  /// [fileId] - ID of the file being uploaded
  Future<Result<void>> pauseUpload(String fileId);

  /// Resume a paused upload
  /// 
  /// [fileId] - ID of the file being uploaded
  Future<Result<void>> resumeUpload(String fileId);

  /// Get upload progress for a file
  /// 
  /// [fileId] - ID of the file being uploaded
  Future<Result<UploadProgressEntity>> getUploadProgress(String fileId);

  /// Clean up temporary files
  /// 
  /// [olderThan] - Delete files older than this duration
  Future<Result<int>> cleanupTempFiles({Duration? olderThan});
}