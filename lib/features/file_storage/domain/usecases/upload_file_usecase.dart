import 'dart:io';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/file_entity.dart';
import '../repositories/i_file_repository.dart';

/// Parameters for uploading a file
class UploadFileParams {
  const UploadFileParams({
    required this.file,
    required this.bucket,
    this.path,
    this.onProgress,
    this.compressionQuality = 80,
    this.generateThumbnail = true,
  });

  /// The file to upload
  final File file;

  /// Storage bucket name
  final String bucket;

  /// Storage path (optional, will generate if not provided)
  final String? path;

  /// Callback for upload progress updates
  final Function(UploadProgressEntity)? onProgress;

  /// Image compression quality (0-100, only for images)
  final int compressionQuality;

  /// Whether to generate thumbnail for images/videos
  final bool generateThumbnail;
}

/// Use case for uploading files to storage
class UploadFileUseCase implements UseCase<FileEntity, UploadFileParams> {
  const UploadFileUseCase({
    required this.fileRepository,
  });

  final IFileRepository fileRepository;

  @override
  Future<Result<FileEntity>> call(UploadFileParams params) async {
    return await fileRepository.uploadFile(
      params.file,
      bucket: params.bucket,
      path: params.path,
      onProgress: params.onProgress,
      compressionQuality: params.compressionQuality,
      generateThumbnail: params.generateThumbnail,
    );
  }
}