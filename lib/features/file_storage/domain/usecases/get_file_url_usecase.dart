import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/file_entity.dart';
import '../repositories/i_file_repository.dart';

/// Parameters for getting file URL
class GetFileUrlParams {
  const GetFileUrlParams({
    required this.fileEntity,
    this.expiresIn,
  });

  /// The file entity
  final FileEntity fileEntity;

  /// URL expiration time (optional)
  final Duration? expiresIn;
}

/// Use case for getting public URLs for files
class GetFileUrlUseCase implements UseCase<String, GetFileUrlParams> {
  const GetFileUrlUseCase({
    required this.fileRepository,
  });

  final IFileRepository fileRepository;

  @override
  Future<Result<String>> call(GetFileUrlParams params) async {
    return await fileRepository.getFileUrl(
      params.fileEntity,
      expiresIn: params.expiresIn,
    );
  }
}