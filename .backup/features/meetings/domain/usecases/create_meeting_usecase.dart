import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../auth/domain/usecases/base_usecase.dart';
import '../entities/meeting.dart';
import '../repositories/i_meeting_repository.dart';

/// Use case to create a new meeting
class CreateMeetingUseCase implements UseCase<Meeting, CreateMeetingParams> {
  const CreateMeetingUseCase(this._repository);

  final IMeetingRepository _repository;

  @override
  Future<Result<Meeting>> call(CreateMeetingParams params) async {
    // Validate parameters
    if (params.maxParticipants < 2 || params.maxParticipants > 1000) {
      return const ResultFailure(
        ValidationFailure('Max participants must be between 2 and 1000'),
      );
    }

    if (params.scheduledFor != null && 
        params.scheduledFor!.isBefore(DateTime.now())) {
      return const ResultFailure(
        ValidationFailure('Cannot schedule meeting in the past'),
      );
    }

    // Create the meeting
    final createResult = await _repository.createMeeting(
      roomId: params.roomId,
      hostId: params.hostId,
      title: params.title,
      description: params.description,
      scheduledFor: params.scheduledFor,
      maxParticipants: params.maxParticipants,
      metadata: params.metadata,
    );

    return await createResult.when(
      success: (meeting) async {
        // If the meeting should start immediately
        if (params.startImmediately) {
          final startResult = await _repository.startMeeting(meeting.id);
          return startResult.when(
            success: (startedMeeting) => Success(startedMeeting),
            failure: (failure) => ResultFailure(failure),
          );
        }

        return Success(meeting);
      },
      failure: (failure) async => ResultFailure(failure),
    );
  }
}

/// Parameters for CreateMeetingUseCase
class CreateMeetingParams extends Equatable {
  const CreateMeetingParams({
    this.roomId,
    required this.hostId,
    this.title,
    this.description,
    this.scheduledFor,
    this.maxParticipants = 100,
    this.metadata = const {},
    this.startImmediately = false,
  });

  final String? roomId;
  final String hostId;
  final String? title;
  final String? description;
  final DateTime? scheduledFor;
  final int maxParticipants;
  final Map<String, dynamic> metadata;
  final bool startImmediately;

  @override
  List<Object?> get props => [
        roomId,
        hostId,
        title,
        description,
        scheduledFor,
        maxParticipants,
        metadata,
        startImmediately,
      ];
}