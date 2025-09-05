import 'package:equatable/equatable.dart';

/// Enum for file types
enum FileType {
  image('image'),
  video('video'),
  audio('audio'),
  document('document'),
  other('other');

  const FileType(this.value);
  final String value;

  static FileType fromString(String value) {
    return FileType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FileType.other,
    );
  }

  static FileType fromExtension(String extension) {
    final ext = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
      return FileType.image;
    } else if (['mp4', 'mov', 'avi', 'webm'].contains(ext)) {
      return FileType.video;
    } else if (['mp3', 'wav', 'm4a', 'aac'].contains(ext)) {
      return FileType.audio;
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) {
      return FileType.document;
    }
    return FileType.other;
  }
}

/// Enum for upload status
enum UploadStatus {
  pending('pending'),
  uploading('uploading'),
  processing('processing'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const UploadStatus(this.value);
  final String value;

  static UploadStatus fromString(String value) {
    return UploadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UploadStatus.pending,
    );
  }
}

/// Domain entity representing a file in the storage system
class FileEntity extends Equatable {
  const FileEntity({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.fileType,
    required this.fileSize,
    required this.storagePath,
    this.thumbnailPath,
    required this.uploadedBy,
    required this.uploadedAt,
    this.metadata = const <String, dynamic>{},
    this.mimeType,
    this.checksum,
    this.compressionRatio,
    this.uploadStatus = UploadStatus.completed,
    this.uploadProgress = 100.0,
  });

  /// Unique identifier for the file
  final String id;

  /// Generated filename for storage
  final String filename;

  /// Original filename when uploaded
  final String originalName;

  /// Type of file (image, video, audio, document, other)
  final FileType fileType;

  /// Size of file in bytes
  final int fileSize;

  /// Storage path in the bucket
  final String storagePath;

  /// Path to generated thumbnail (if applicable)
  final String? thumbnailPath;

  /// User ID who uploaded the file
  final String uploadedBy;

  /// When the file was uploaded
  final DateTime uploadedAt;

  /// Additional metadata for the file
  final Map<String, dynamic> metadata;

  /// MIME type of the file
  final String? mimeType;

  /// File checksum for integrity verification
  final String? checksum;

  /// Compression ratio applied (if any)
  final double? compressionRatio;

  /// Current upload status
  final UploadStatus uploadStatus;

  /// Upload progress (0-100)
  final double uploadProgress;

  /// File extension from original name
  String get extension {
    final parts = originalName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Whether this file has a thumbnail
  bool get hasThumbnail => thumbnailPath != null && thumbnailPath!.isNotEmpty;

  /// Whether this file is an image
  bool get isImage => fileType == FileType.image;

  /// Whether this file is a video
  bool get isVideo => fileType == FileType.video;

  /// Whether this file is an audio file
  bool get isAudio => fileType == FileType.audio;

  /// Whether this file is a document
  bool get isDocument => fileType == FileType.document;

  /// Whether upload is in progress
  bool get isUploading => uploadStatus == UploadStatus.uploading;

  /// Whether upload is completed
  bool get isCompleted => uploadStatus == UploadStatus.completed;

  /// Whether upload failed
  bool get isFailed => uploadStatus == UploadStatus.failed;

  /// Human readable file size
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  List<Object?> get props => [
        id,
        filename,
        originalName,
        fileType,
        fileSize,
        storagePath,
        thumbnailPath,
        uploadedBy,
        uploadedAt,
        metadata,
        mimeType,
        checksum,
        compressionRatio,
        uploadStatus,
        uploadProgress,
      ];

  /// Creates a copy of this file with updated fields
  FileEntity copyWith({
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
    return FileEntity(
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

/// Entity representing upload progress information
class UploadProgressEntity extends Equatable {
  const UploadProgressEntity({
    required this.fileId,
    required this.uploadedBytes,
    required this.totalBytes,
    required this.status,
    this.error,
    this.eta,
    this.speed,
  });

  /// ID of the file being uploaded
  final String fileId;

  /// Number of bytes uploaded so far
  final int uploadedBytes;

  /// Total bytes to upload
  final int totalBytes;

  /// Current upload status
  final UploadStatus status;

  /// Error message if upload failed
  final String? error;

  /// Estimated time to completion
  final Duration? eta;

  /// Upload speed in bytes per second
  final double? speed;

  /// Progress percentage (0-100)
  double get progress => totalBytes > 0 ? (uploadedBytes / totalBytes) * 100 : 0;

  /// Whether upload is complete
  bool get isComplete => status == UploadStatus.completed;

  /// Whether upload failed
  bool get hasFailed => status == UploadStatus.failed;

  /// Human readable speed
  String? get formattedSpeed {
    if (speed == null) return null;
    if (speed! < 1024) {
      return '${speed!.toStringAsFixed(0)} B/s';
    } else if (speed! < 1024 * 1024) {
      return '${(speed! / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speed! / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  @override
  List<Object?> get props => [
        fileId,
        uploadedBytes,
        totalBytes,
        status,
        error,
        eta,
        speed,
      ];

  /// Creates a copy with updated fields
  UploadProgressEntity copyWith({
    String? fileId,
    int? uploadedBytes,
    int? totalBytes,
    UploadStatus? status,
    String? error,
    Duration? eta,
    double? speed,
  }) {
    return UploadProgressEntity(
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