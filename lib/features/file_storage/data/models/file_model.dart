import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/file_entity.dart';

part 'file_model.g.dart';

/// Data model for file entity with JSON serialization
@JsonSerializable()
class FileModel extends FileEntity {
  const FileModel({
    required super.id,
    required super.filename,
    required super.originalName,
    required super.fileType,
    required super.fileSize,
    required super.storagePath,
    super.thumbnailPath,
    required super.uploadedBy,
    required super.uploadedAt,
    super.metadata = const <String, dynamic>{},
    super.mimeType,
    super.checksum,
    super.compressionRatio,
    super.uploadStatus = UploadStatus.completed,
    super.uploadProgress = 100.0,
  });

  /// Creates FileModel from JSON
  factory FileModel.fromJson(Map<String, dynamic> json) {
    // Convert file_type string to FileType enum
    final fileTypeStr = json['file_type'] as String?;
    final fileType = fileTypeStr != null 
        ? FileType.fromString(fileTypeStr)
        : FileType.other;

    // Convert upload_status string to UploadStatus enum
    final uploadStatusStr = json['upload_status'] as String?;
    final uploadStatus = uploadStatusStr != null
        ? UploadStatus.fromString(uploadStatusStr)
        : UploadStatus.completed;

    // Convert timestamp strings to DateTime
    final uploadedAtStr = json['uploaded_at'] as String?;
    final uploadedAt = uploadedAtStr != null
        ? DateTime.parse(uploadedAtStr)
        : DateTime.now();

    return FileModel(
      id: json['id'] as String,
      filename: json['filename'] as String,
      originalName: json['original_name'] as String,
      fileType: fileType,
      fileSize: (json['file_size'] as num).toInt(),
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      uploadedBy: json['uploaded_by'] as String,
      uploadedAt: uploadedAt,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      mimeType: json['mime_type'] as String?,
      checksum: json['checksum'] as String?,
      compressionRatio: (json['compression_ratio'] as num?)?.toDouble(),
      uploadStatus: uploadStatus,
      uploadProgress: (json['upload_progress'] as num?)?.toDouble() ?? 100.0,
    );
  }

  /// Converts FileModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'original_name': originalName,
      'file_type': fileType.value,
      'file_size': fileSize,
      'storage_path': storagePath,
      'thumbnail_path': thumbnailPath,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
      'metadata': metadata,
      'mime_type': mimeType,
      'checksum': checksum,
      'compression_ratio': compressionRatio,
      'upload_status': uploadStatus.value,
      'upload_progress': uploadProgress,
    };
  }

  /// Creates FileModel from FileEntity
  factory FileModel.fromEntity(FileEntity entity) {
    return FileModel(
      id: entity.id,
      filename: entity.filename,
      originalName: entity.originalName,
      fileType: entity.fileType,
      fileSize: entity.fileSize,
      storagePath: entity.storagePath,
      thumbnailPath: entity.thumbnailPath,
      uploadedBy: entity.uploadedBy,
      uploadedAt: entity.uploadedAt,
      metadata: entity.metadata,
      mimeType: entity.mimeType,
      checksum: entity.checksum,
      compressionRatio: entity.compressionRatio,
      uploadStatus: entity.uploadStatus,
      uploadProgress: entity.uploadProgress,
    );
  }

  /// Converts to FileEntity
  FileEntity toEntity() {
    return FileEntity(
      id: id,
      filename: filename,
      originalName: originalName,
      fileType: fileType,
      fileSize: fileSize,
      storagePath: storagePath,
      thumbnailPath: thumbnailPath,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      metadata: metadata,
      mimeType: mimeType,
      checksum: checksum,
      compressionRatio: compressionRatio,
      uploadStatus: uploadStatus,
      uploadProgress: uploadProgress,
    );
  }

  /// Creates a copy with updated fields
  @override
  FileModel copyWith({
    String? id,
    String? filename,
    String? originalName,
    FileType? fileType,
    int? fileSize,
    String? storagePath,
    String? thumbnailPath,
    String? uploadedBy,
    DateTime? uploadedAt,
    Map<String, dynamic>? metadata,
    String? mimeType,
    String? checksum,
    double? compressionRatio,
    UploadStatus? uploadStatus,
    double? uploadProgress,
  }) {
    return FileModel(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      originalName: originalName ?? this.originalName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      storagePath: storagePath ?? this.storagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      metadata: metadata ?? this.metadata,
      mimeType: mimeType ?? this.mimeType,
      checksum: checksum ?? this.checksum,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

/// Data model for upload progress with JSON serialization
@JsonSerializable()
class UploadProgressModel extends UploadProgressEntity {
  const UploadProgressModel({
    required super.fileId,
    required super.uploadedBytes,
    required super.totalBytes,
    required super.status,
    super.error,
    super.eta,
    super.speed,
  });

  /// Creates UploadProgressModel from JSON
  factory UploadProgressModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String;
    final status = UploadStatus.fromString(statusStr);
    
    final etaSeconds = json['eta_seconds'] as int?;
    final eta = etaSeconds != null ? Duration(seconds: etaSeconds) : null;

    return UploadProgressModel(
      fileId: json['file_id'] as String,
      uploadedBytes: (json['uploaded_bytes'] as num).toInt(),
      totalBytes: (json['total_bytes'] as num).toInt(),
      status: status,
      error: json['error'] as String?,
      eta: eta,
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }

  /// Converts UploadProgressModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'uploaded_bytes': uploadedBytes,
      'total_bytes': totalBytes,
      'status': status.value,
      'error': error,
      'eta_seconds': eta?.inSeconds,
      'speed': speed,
    };
  }

  /// Creates UploadProgressModel from UploadProgressEntity
  factory UploadProgressModel.fromEntity(UploadProgressEntity entity) {
    return UploadProgressModel(
      fileId: entity.fileId,
      uploadedBytes: entity.uploadedBytes,
      totalBytes: entity.totalBytes,
      status: entity.status,
      error: entity.error,
      eta: entity.eta,
      speed: entity.speed,
    );
  }

  /// Converts to UploadProgressEntity
  UploadProgressEntity toEntity() {
    return UploadProgressEntity(
      fileId: fileId,
      uploadedBytes: uploadedBytes,
      totalBytes: totalBytes,
      status: status,
      error: error,
      eta: eta,
      speed: speed,
    );
  }

  /// Creates a copy with updated fields
  @override
  UploadProgressModel copyWith({
    String? fileId,
    int? uploadedBytes,
    int? totalBytes,
    UploadStatus? status,
    String? error,
    Duration? eta,
    double? speed,
  }) {
    return UploadProgressModel(
      fileId: fileId ?? this.fileId,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      error: error ?? this.error,
      eta: eta ?? this.eta,
      speed: speed ?? this.speed,
    );
  }
}