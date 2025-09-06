import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/meeting.dart';
import '../entities/meeting_participant.dart';
import '../repositories/i_meeting_repository.dart';

/// Use case to start a meeting
class StartMeetingUseCase implements UseCase<Meeting, StartMeetingParams> {
  const StartMeetingUseCase(this._repository);

  final IMeetingRepository _repository;

  @override
  Future<Result<Meeting>> call(StartMeetingParams params) async {
    // First check if meeting exists and user has permission
    final getMeetingResult = await _repository.getMeeting(params.meetingId);
    
    if (getMeetingResult.isSuccess) {
      final meeting = getMeetingResult.dataOrNull!;
      
      // Verify user is host or admin
      if (meeting.hostId != params.userId) {
        final participantsResult = await _repository.getMeetingParticipants(params.meetingId);
        bool isAdmin = false;
        
        if (participantsResult.isSuccess) {
          final participants = participantsResult.dataOrNull!;
          final userParticipant = participants
              .where((MeetingParticipant p) => p.userId == params.userId && p.hasElevatedPrivileges)
              .firstOrNull;
          isAdmin = userParticipant != null;
        }
        
        if (!isAdmin) {
          return const ResultFailure(
            ServerFailure(message: 'Only host or admin can start the meeting'),
          );
        }
      }

      // Check if meeting is already started
      if (meeting.isActive) {
        return const ResultFailure(
          ServerFailure(message: 'Meeting is already active'),
        );
      }

      // Start the meeting
      final startResult = await _repository.startMeeting(params.meetingId);
      
      if (startResult.isSuccess) {
        final startedMeeting = startResult.dataOrNull!;
        
        // Update host participant if needed
        await _repository.updateParticipant(
          params.meetingId,
          params.userId,
          role: ParticipantRole.host,
        );
        
        return Success(startedMeeting);
      } else {
        final failure = startResult.failureOrNull!;
        return ResultFailure(failure);
      }
    } else {
      final failure = getMeetingResult.failureOrNull!;
      return ResultFailure(failure);
    }
  }
}

/// Parameters for StartMeetingUseCase
class StartMeetingParams extends Equatable {
  const StartMeetingParams({
    required this.meetingId,
    required this.userId,
  });

  final String meetingId;
  final String userId;

  @override
  List<Object?> get props => [meetingId, userId];
}