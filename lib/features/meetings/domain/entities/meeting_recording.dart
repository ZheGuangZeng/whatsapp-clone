import 'package:equatable/equatable.dart';

/// Enum for recording status
enum RecordingStatus {
  processing('processing'),
  completed('completed'),
  failed('failed');

  const RecordingStatus(this.value);
  final String value;

  static RecordingStatus fromString(String value) {
    return RecordingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RecordingStatus.processing,
    );
  }
}

/// Domain entity representing a meeting recording
class MeetingRecording extends Equatable {
  const MeetingRecording({
    required this.id,
    required this.meetingId,
    required this.livekitEgressId,
    this.fileUrl,
    this.fileSize,
    this.durationSeconds,
    this.status = RecordingStatus.processing,
    required this.startedAt,
    this.completedAt,
    this.metadata = const {},
  });

  /// Unique identifier for the recording
  final String id;

  /// ID of the meeting this recording belongs to
  final String meetingId;

  /// LiveKit egress ID for tracking the recording
  final String livekitEgressId;

  /// URL to the recorded file
  final String? fileUrl;

  /// Size of the recorded file in bytes
  final int? fileSize;

  /// Duration of the recording in seconds
  final int? durationSeconds;

  /// Current status of the recording
  final RecordingStatus status;

  /// When the recording was started
  final DateTime startedAt;

  /// When the recording was completed
  final DateTime? completedAt;

  /// Additional metadata as JSON
  final Map<String, dynamic> metadata;

  /// Whether the recording is completed
  bool get isCompleted => status == RecordingStatus.completed;

  /// Whether the recording is still processing
  bool get isProcessing => status == RecordingStatus.processing;

  /// Whether the recording failed
  bool get hasFailed => status == RecordingStatus.failed;

  /// Whether the recording is available for download
  bool get isAvailable => isCompleted && fileUrl != null;

  /// Duration formatted as human-readable string
  String get formattedDuration {
    if (durationSeconds == null) return 'Unknown';
    
    final duration = Duration(seconds: durationSeconds!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// File size formatted as human-readable string
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = fileSize!.toDouble();
    var suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  /// Processing time in minutes (if completed)
  int? get processingMinutes {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt).inMinutes;
  }

  @override
  List<Object?> get props => [
        id,
        meetingId,
        livekitEgressId,
        fileUrl,
        fileSize,
        durationSeconds,
        status,
        startedAt,
        completedAt,
        metadata,
      ];

  /// Creates a copy of this recording with updated fields
  MeetingRecording copyWith({
    String? id,
    String? meetingId,
    String? livekitEgressId,
    String? fileUrl,
    int? fileSize,
    int? durationSeconds,
    RecordingStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return MeetingRecording(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      livekitEgressId: livekitEgressId ?? this.livekitEgressId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}