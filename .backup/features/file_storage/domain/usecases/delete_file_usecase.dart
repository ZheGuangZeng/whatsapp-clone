import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/file_entity.dart';
import '../repositories/i_file_repository.dart';

/// Parameters for deleting a file
class DeleteFileParams {
  const DeleteFileParams({
    required this.fileEntity,
    this.deleteThumbnail = true,
  });

  /// The file entity to delete
  final FileEntity fileEntity;

  /// Whether to also delete the thumbnail
  final bool deleteThumbnail;
}

/// Use case for deleting files from storage
class DeleteFileUseCase implements UseCase<void, DeleteFileParams> {
  const DeleteFileUseCase({
    required this.fileRepository,
  });

  final IFileRepository fileRepository;

  @override
  Future<Result<void>> call(DeleteFileParams params) async {
    return await fileRepository.deleteFile(
      params.fileEntity,
      deleteThumbnail: params.deleteThumbnail,
    );
  }
}