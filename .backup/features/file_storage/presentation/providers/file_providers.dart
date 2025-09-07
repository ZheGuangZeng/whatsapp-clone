import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/file_repository.dart';
import '../../data/sources/file_storage_source.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/i_file_repository.dart';
import '../../domain/usecases/upload_file_usecase.dart';
import '../../domain/usecases/download_file_usecase.dart';
import '../../domain/usecases/delete_file_usecase.dart';
import '../../domain/usecases/get_file_url_usecase.dart';
import '../../domain/usecases/search_files_usecase.dart';

part 'file_providers.g.dart';

/// Provider for file storage data source
@riverpod
FileStorageSource fileStorageSource(FileStorageSourceRef ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return FileStorageSource(supabaseClient: supabaseClient);
}

/// Provider for file repository
@riverpod
IFileRepository fileRepository(FileRepositoryRef ref) {
  final fileStorageSource = ref.watch(fileStorageSourceProvider);
  return FileRepository(fileStorageSource: fileStorageSource);
}

/// Provider for upload file use case
@riverpod
UploadFileUseCase uploadFileUseCase(UploadFileUseCaseRef ref) {
  final fileRepository = ref.watch(fileRepositoryProvider);
  return UploadFileUseCase(fileRepository: fileRepository);
}

/// Provider for download file use case
@riverpod
DownloadFileUseCase downloadFileUseCase(DownloadFileUseCaseRef ref) {
  final fileRepository = ref.watch(fileRepositoryProvider);
  return DownloadFileUseCase(fileRepository: fileRepository);
}

/// Provider for delete file use case
@riverpod
DeleteFileUseCase deleteFileUseCase(DeleteFileUseCaseRef ref) {
  final fileRepository = ref.watch(fileRepositoryProvider);
  return DeleteFileUseCase(fileRepository: fileRepository);
}

/// Provider for get file URL use case
@riverpod
GetFileUrlUseCase getFileUrlUseCase(GetFileUrlUseCaseRef ref) {
  final fileRepository = ref.watch(fileRepositoryProvider);
  return GetFileUrlUseCase(fileRepository: fileRepository);
}

/// Provider for search files use case
@riverpod
SearchFilesUseCase searchFilesUseCase(SearchFilesUseCaseRef ref) {
  final fileRepository = ref.watch(fileRepositoryProvider);
  return SearchFilesUseCase(fileRepository: fileRepository);
}

/// Provider for tracking upload progress
@riverpod
class UploadProgress extends _$UploadProgress {
  @override
  Map<String, UploadProgressEntity> build() {
    return {};
  }

  /// Update upload progress for a file
  void updateProgress(String fileId, UploadProgressEntity progress) {
    state = {...state, fileId: progress};
  }

  /// Remove upload progress for a file
  void removeProgress(String fileId) {
    final newState = Map<String, UploadProgressEntity>.from(state);
    newState.remove(fileId);
    state = newState;
  }

  /// Clear all upload progress
  void clearAll() {
    state = {};
  }
}

/// Provider for file cache (recently accessed files)
@riverpod
class FileCache extends _$FileCache {
  @override
  Map<String, FileEntity> build() {
    return {};
  }

  /// Add file to cache
  void addFile(FileEntity file) {
    state = {...state, file.id: file};
  }

  /// Get file from cache
  FileEntity? getFile(String fileId) {
    return state[fileId];
  }

  /// Remove file from cache
  void removeFile(String fileId) {
    final newState = Map<String, FileEntity>.from(state);
    newState.remove(fileId);
    state = newState;
  }

  /// Clear cache
  void clear() {
    state = {};
  }
}

/// Provider for user's recent files
@riverpod
class UserFiles extends _$UserFiles {
  @override
  AsyncValue<List<FileEntity>> build(String userId) {
    return const AsyncValue.loading();
  }

  /// Load user's files
  Future<void> loadFiles({
    FileType? fileType,
    int limit = 50,
    int offset = 0,
  }) async {
    state = const AsyncValue.loading();

    try {
      final searchFilesUseCase = ref.read(searchFilesUseCaseProvider);
      final result = await searchFilesUseCase(SearchFilesParams(
        uploadedBy: userId,
        fileType: fileType,
        limit: limit,
        offset: offset,
      ));

      if (result.isSuccess) {
        final files = result.dataOrNull!;
        // Add files to cache
        final fileCache = ref.read(fileCacheProvider.notifier);
        for (final file in files) {
          fileCache.addFile(file);
        }
        
        state = AsyncValue.data(files);
      } else {
        final failure = result.failureOrNull!;
        state = AsyncValue.error(failure, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add a new file to the list
  void addFile(FileEntity file) {
    state.whenData((files) {
      final newFiles = [file, ...files];
      state = AsyncValue.data(newFiles);
      
      // Add to cache
      ref.read(fileCacheProvider.notifier).addFile(file);
    });
  }

  /// Remove a file from the list
  void removeFile(String fileId) {
    state.whenData((files) {
      final newFiles = files.where((f) => f.id != fileId).toList();
      state = AsyncValue.data(newFiles);
      
      // Remove from cache
      ref.read(fileCacheProvider.notifier).removeFile(fileId);
    });
  }

  /// Update a file in the list
  void updateFile(FileEntity updatedFile) {
    state.whenData((files) {
      final newFiles = files.map((f) {
        return f.id == updatedFile.id ? updatedFile : f;
      }).toList();
      state = AsyncValue.data(newFiles);
      
      // Update cache
      ref.read(fileCacheProvider.notifier).addFile(updatedFile);
    });
  }
}

/// Provider for file URLs with caching
@riverpod
class FileUrls extends _$FileUrls {
  @override
  Map<String, String> build() {
    return {};
  }

  /// Get file URL with caching
  Future<String?> getFileUrl(FileEntity file, {Duration? expiresIn}) async {
    // Check cache first
    final cachedUrl = state[file.id];
    if (cachedUrl != null) {
      return cachedUrl;
    }

    try {
      final getFileUrlUseCase = ref.read(getFileUrlUseCaseProvider);
      final result = await getFileUrlUseCase(GetFileUrlParams(
        fileEntity: file,
        expiresIn: expiresIn,
      ));

      if (result.isSuccess) {
        final url = result.dataOrNull!;
        // Cache the URL
        state = {...state, file.id: url};
        return url;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Clear URL cache
  void clearCache() {
    state = {};
  }

  /// Remove specific URL from cache
  void removeUrl(String fileId) {
    final newState = Map<String, String>.from(state);
    newState.remove(fileId);
    state = newState;
  }
}