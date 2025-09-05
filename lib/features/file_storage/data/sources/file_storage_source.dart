import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/file_model.dart';
import '../../domain/entities/file_entity.dart';

/// Remote data source for file storage operations using Supabase
class FileStorageSource {
  const FileStorageSource({
    required this.supabaseClient,
  });

  final SupabaseClient supabaseClient;

  /// Upload a file to Supabase Storage
  Future<FileModel> uploadFile(
    File file, {
    required String bucket,
    String? path,
    Function(UploadProgressEntity)? onProgress,
    int compressionQuality = 80,
    bool generateThumbnail = true,
  }) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        throw const StorageException('File does not exist');
      }

      // Get file info
      final fileStats = await file.stat();
      final originalName = file.path.split('/').last;
      final mimeType = lookupMimeType(file.path);
      final fileType = FileType.fromExtension(
        originalName.split('.').last,
      );

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = originalName.split('.').last;
      final filename = '${timestamp}_$originalName';
      final storagePath = path ?? '${fileType.value}/$filename';

      File uploadFile = file;
      int finalSize = fileStats.size;
      double? compressionRatio;

      // Compress image if needed
      if (fileType == FileType.image && compressionQuality < 100) {
        final compressedFile = await _compressImage(
          file,
          quality: compressionQuality,
        );
        if (compressedFile != null) {
          uploadFile = compressedFile;
          final compressedStats = await compressedFile.stat();
          finalSize = compressedStats.size;
          compressionRatio = fileStats.size / finalSize;
        }
      }

      // Read file bytes
      final fileBytes = await uploadFile.readAsBytes();

      // Create progress tracker
      String? uploadId;
      if (onProgress != null) {
        uploadId = _generateUploadId();
        onProgress(UploadProgressEntity(
          fileId: uploadId,
          uploadedBytes: 0,
          totalBytes: finalSize,
          status: UploadStatus.uploading,
        ));
      }

      // Upload to Supabase Storage
      await supabaseClient.storage.from(bucket).uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );

      // Update progress to processing for thumbnail generation
      if (onProgress != null && uploadId != null) {
        onProgress(UploadProgressEntity(
          fileId: uploadId,
          uploadedBytes: finalSize,
          totalBytes: finalSize,
          status: UploadStatus.processing,
        ));
      }

      String? thumbnailPath;
      if (generateThumbnail && (fileType == FileType.image || fileType == FileType.video)) {
        thumbnailPath = await _generateAndUploadThumbnail(
          uploadFile,
          bucket: AppConstants.thumbnailsBucket,
          originalPath: storagePath,
          fileType: fileType,
        );
      }

      // Create file metadata
      final fileEntity = FileModel(
        id: _generateFileId(),
        filename: filename,
        originalName: originalName,
        fileType: fileType,
        fileSize: finalSize,
        storagePath: storagePath,
        thumbnailPath: thumbnailPath,
        uploadedBy: supabaseClient.auth.currentUser?.id ?? '',
        uploadedAt: DateTime.now(),
        metadata: {
          'bucket': bucket,
          'mime_type': mimeType,
          'original_size': fileStats.size,
          if (compressionRatio != null) 'compression_ratio': compressionRatio,
        },
        mimeType: mimeType,
        compressionRatio: compressionRatio,
        uploadStatus: UploadStatus.completed,
        uploadProgress: 100.0,
      );

      // Save metadata to database
      await _saveFileMetadata(fileEntity);

      // Complete progress tracking
      if (onProgress != null && uploadId != null) {
        onProgress(UploadProgressEntity(
          fileId: uploadId,
          uploadedBytes: finalSize,
          totalBytes: finalSize,
          status: UploadStatus.completed,
        ));
      }

      // Clean up temporary compressed file
      if (uploadFile != file && await uploadFile.exists()) {
        await uploadFile.delete();
      }

      return fileEntity;
    } catch (e) {
      throw StorageException('Failed to upload file: ${e.toString()}');
    }
  }

  /// Upload file from bytes
  Future<FileModel> uploadFromBytes(
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
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      // Upload using file method
      final result = await uploadFile(
        tempFile,
        bucket: bucket,
        path: path,
        onProgress: onProgress,
        compressionQuality: compressionQuality,
        generateThumbnail: generateThumbnail,
      );

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return result;
    } catch (e) {
      throw StorageException('Failed to upload from bytes: ${e.toString()}');
    }
  }

  /// Download file from storage
  Future<File> downloadFile(
    FileModel file, {
    String? localPath,
    Function(UploadProgressEntity)? onProgress,
  }) async {
    try {
      // Determine download path
      final downloadPath = localPath ?? await _getDownloadPath(file.originalName);
      
      // Get file bytes from storage
      final fileBytes = await supabaseClient.storage
          .from(_getBucketFromPath(file.storagePath))
          .download(file.storagePath);

      // Create local file
      final localFile = File(downloadPath);
      await localFile.writeAsBytes(fileBytes);

      return localFile;
    } catch (e) {
      throw StorageException('Failed to download file: ${e.toString()}');
    }
  }

  /// Get file bytes without saving to disk
  Future<Uint8List> getFileBytes(FileModel file) async {
    try {
      return await supabaseClient.storage
          .from(_getBucketFromPath(file.storagePath))
          .download(file.storagePath);
    } catch (e) {
      throw StorageException('Failed to get file bytes: ${e.toString()}');
    }
  }

  /// Get public URL for file
  Future<String> getFileUrl(FileModel file, {Duration? expiresIn}) async {
    try {
      final bucket = _getBucketFromPath(file.storagePath);
      if (expiresIn != null) {
        return supabaseClient.storage
            .from(bucket)
            .createSignedUrl(file.storagePath, expiresIn.inSeconds);
      } else {
        return supabaseClient.storage
            .from(bucket)
            .getPublicUrl(file.storagePath);
      }
    } catch (e) {
      throw StorageException('Failed to get file URL: ${e.toString()}');
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(FileModel file, {bool deleteThumbnail = true}) async {
    try {
      final bucket = _getBucketFromPath(file.storagePath);
      
      // Delete main file
      await supabaseClient.storage
          .from(bucket)
          .remove([file.storagePath]);

      // Delete thumbnail if exists
      if (deleteThumbnail && file.thumbnailPath != null) {
        await supabaseClient.storage
            .from(AppConstants.thumbnailsBucket)
            .remove([file.thumbnailPath!]);
      }

      // Delete metadata from database
      await supabaseClient
          .from(AppConstants.filesTable)
          .delete()
          .eq('id', file.id);
    } catch (e) {
      throw StorageException('Failed to delete file: ${e.toString()}');
    }
  }

  /// Get file metadata from database
  Future<FileModel> getFileMetadata(String fileId) async {
    try {
      final response = await supabaseClient
          .from(AppConstants.filesTable)
          .select()
          .eq('id', fileId)
          .single();

      return FileModel.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to get file metadata: ${e.toString()}');
    }
  }

  /// List files from database with filters
  Future<List<FileModel>> listFiles({
    String? uploadedBy,
    FileType? fileType,
    String? bucket,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = supabaseClient
          .from(AppConstants.filesTable)
          .select();

      if (uploadedBy != null) {
        query = query.eq('uploaded_by', uploadedBy);
      }

      if (fileType != null) {
        query = query.eq('file_type', fileType.value);
      }

      if (fromDate != null) {
        query = query.gte('uploaded_at', fromDate.toIso8601String());
      }

      if (toDate != null) {
        query = query.lte('uploaded_at', toDate.toIso8601String());
      }

      final response = await query
          .order('uploaded_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => FileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to list files: ${e.toString()}');
    }
  }

  /// Compress image file
  Future<File?> _compressImage(
    File file, {
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: quality,
        minWidth: maxWidth ?? 1920,
        minHeight: maxHeight ?? 1080,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      // If compression fails, return null to use original file
      return null;
    }
  }

  /// Generate and upload thumbnail
  Future<String?> _generateAndUploadThumbnail(
    File file, {
    required String bucket,
    required String originalPath,
    required FileType fileType,
  }) async {
    try {
      File? thumbnailFile;

      if (fileType == FileType.image) {
        thumbnailFile = await _generateImageThumbnail(file);
      } else if (fileType == FileType.video) {
        thumbnailFile = await _generateVideoThumbnail(file);
      }

      if (thumbnailFile == null) return null;

      // Upload thumbnail
      final thumbnailPath = 'thumbnails/${originalPath.split('/').last}_thumb.jpg';
      final thumbnailBytes = await thumbnailFile.readAsBytes();

      await supabaseClient.storage.from(bucket).uploadBinary(
        thumbnailPath,
        thumbnailBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // Clean up temp thumbnail file
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }

      return thumbnailPath;
    } catch (e) {
      // Thumbnail generation is optional, so we don't throw
      return null;
    }
  }

  /// Generate image thumbnail
  Future<File?> _generateImageThumbnail(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      final thumbnail = img.copyResize(
        image,
        width: AppConstants.thumbnailSize,
        height: AppConstants.thumbnailSize,
        interpolation: img.Interpolation.average,
      );

      final tempDir = await getTemporaryDirectory();
      final thumbnailFile = File('${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await thumbnailFile.writeAsBytes(
        img.encodeJpg(thumbnail, quality: AppConstants.videoThumbnailQuality),
      );

      return thumbnailFile;
    } catch (e) {
      return null;
    }
  }

  /// Generate video thumbnail
  Future<File?> _generateVideoThumbnail(File videoFile) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: AppConstants.thumbnailSize,
        maxHeight: AppConstants.thumbnailSize,
        quality: AppConstants.videoThumbnailQuality,
      );

      return thumbnailPath != null ? File(thumbnailPath) : null;
    } catch (e) {
      return null;
    }
  }

  /// Save file metadata to database
  Future<void> _saveFileMetadata(FileModel file) async {
    try {
      await supabaseClient
          .from(AppConstants.filesTable)
          .upsert(file.toJson());
    } catch (e) {
      throw DatabaseException('Failed to save file metadata: ${e.toString()}');
    }
  }

  /// Get bucket name from storage path
  String _getBucketFromPath(String path) {
    // Extract bucket from metadata or use default logic
    if (path.startsWith('avatars/')) {
      return AppConstants.userAvatarsBucket;
    } else if (path.startsWith('media/')) {
      return AppConstants.chatMediaBucket;
    } else if (path.startsWith('attachments/')) {
      return AppConstants.messageAttachmentsBucket;
    }
    return AppConstants.chatMediaBucket; // default
  }

  /// Generate unique file ID
  String _generateFileId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate unique upload ID for progress tracking
  String _generateUploadId() {
    return 'upload_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Generate random string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      Iterable.generate(length, (i) => chars.codeUnitAt((random + i) % chars.length)),
    );
  }

  /// Get download path for file
  Future<String> _getDownloadPath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/downloads/$fileName';
  }
}