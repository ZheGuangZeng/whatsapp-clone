import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../auth/domain/usecases/base_usecase.dart';
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
    
    return await getMeetingResult.when(
      success: (meeting) async {
        // Verify user is host or admin
        if (meeting.hostId != params.userId) {
          final participantsResult = await _repository.getMeetingParticipants(params.meetingId);
          final isAdmin = await participantsResult.when(
            success: (participants) async {
              final userParticipant = participants
                  .where((p) => p.userId == params.userId && p.hasElevatedPrivileges)
                  .firstOrNull;
              return userParticipant != null;
            },
            failure: (failure) async => false,
          );
          
          if (!isAdmin) {
            return const ResultFailure(
              UnauthorizedFailure('Only host or admin can start the meeting'),
            );
          }
        }

        // Check if meeting is already started
        if (meeting.isActive) {
          return const ResultFailure(
            ValidationFailure('Meeting is already active'),
          );
        }

        // Start the meeting
        final startResult = await _repository.startMeeting(params.meetingId);
        
        return await startResult.when(
          success: (startedMeeting) async {
            // Update host participant if needed
            await _repository.updateParticipant(
              params.meetingId,
              params.userId,
              role: ParticipantRole.host,
            );
            
            return Success(startedMeeting);
          },
          failure: (failure) async => ResultFailure(failure),
        );
      },
      failure: (failure) async => ResultFailure(failure),
    );
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