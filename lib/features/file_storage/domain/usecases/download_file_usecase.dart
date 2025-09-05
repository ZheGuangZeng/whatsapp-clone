import 'dart:io';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/file_entity.dart';
import '../repositories/i_file_repository.dart';

/// Parameters for downloading a file
class DownloadFileParams {
  const DownloadFileParams({
    required this.fileEntity,
    this.localPath,
    this.onProgress,
  });

  /// The file entity to download
  final FileEntity fileEntity;

  /// Where to save the file locally
  final String? localPath;

  /// Callback for download progress updates
  final Function(UploadProgressEntity)? onProgress;
}

/// Use case for downloading files from storage
class DownloadFileUseCase implements UseCase<File, DownloadFileParams> {
  const DownloadFileUseCase({
    required this.fileRepository,
  });

  final IFileRepository fileRepository;

  @override
  Future<Result<File>> call(DownloadFileParams params) async {
    return await fileRepository.downloadFile(
      params.fileEntity,
      localPath: params.localPath,
      onProgress: params.onProgress,
    );
  }
}