import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/file_entity.dart';
import '../repositories/i_file_repository.dart';

/// Parameters for searching files
class SearchFilesParams {
  const SearchFilesParams({
    this.uploadedBy,
    this.fileType,
    this.bucket,
    this.fromDate,
    this.toDate,
    this.limit = 50,
    this.offset = 0,
  });

  /// Filter by user ID
  final String? uploadedBy;

  /// Filter by file type
  final FileType? fileType;

  /// Filter by storage bucket
  final String? bucket;

  /// Filter files uploaded after this date
  final DateTime? fromDate;

  /// Filter files uploaded before this date
  final DateTime? toDate;

  /// Maximum number of files to return
  final int limit;

  /// Number of files to skip
  final int offset;
}

/// Use case for searching files by criteria
class SearchFilesUseCase implements UseCase<List<FileEntity>, SearchFilesParams> {
  const SearchFilesUseCase({
    required this.fileRepository,
  });

  final IFileRepository fileRepository;

  @override
  Future<Result<List<FileEntity>>> call(SearchFilesParams params) async {
    return await fileRepository.searchFiles(
      uploadedBy: params.uploadedBy,
      fileType: params.fileType,
      bucket: params.bucket,
      fromDate: params.fromDate,
      toDate: params.toDate,
      limit: params.limit,
      offset: params.offset,
    );
  }
}