import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../auth/domain/usecases/base_usecase.dart';
import '../repositories/i_meeting_repository.dart';

/// Use case to leave a meeting
class LeaveMeetingUseCase implements UseCase<void, LeaveMeetingParams> {
  const LeaveMeetingUseCase(this._repository);

  final IMeetingRepository _repository;

  @override
  Future<Result<void>> call(LeaveMeetingParams params) async {
    // First check if meeting exists
    final getMeetingResult = await _repository.getMeeting(params.meetingId);
    
    return await getMeetingResult.when(
      success: (meeting) async {
        // Check if user is actually a participant
        final participantsResult = await _repository.getMeetingParticipants(params.meetingId);
        
        return await participantsResult.when(
          success: (participants) async {
            final userParticipant = participants
                .where((p) => p.userId == params.userId && p.isActive)
                .firstOrNull;

            if (userParticipant == null) {
              return const ResultFailure(
                ValidationFailure('User is not an active participant in this meeting'),
              );
            }

            // If user is the host and there are other participants, 
            // optionally transfer host role
            if (userParticipant.isHost && params.transferHostTo != null) {
              final newHost = participants
                  .where((p) => p.userId == params.transferHostTo && p.isActive)
                  .firstOrNull;
              
              if (newHost != null) {
                await _repository.updateParticipant(
                  params.meetingId,
                  params.transferHostTo!,
                  role: ParticipantRole.host,
                );
              }
            }

            // If user is the host and is ending the meeting for everyone
            if (userParticipant.isHost && params.endMeetingForAll) {
              // End the meeting
              await _repository.endMeeting(params.meetingId);
              
              // Remove all participants
              for (final participant in participants.where((p) => p.isActive)) {
                await _repository.removeParticipant(params.meetingId, participant.userId);
              }
              
              return const Success(null);
            }

            // Remove the participant
            final removeResult = await _repository.removeParticipant(
              params.meetingId,
              params.userId,
            );

            return removeResult.when(
              success: (_) {
                // If this was the last participant and auto-end is enabled, end the meeting
                final remainingParticipants = participants
                    .where((p) => p.userId != params.userId && p.isActive)
                    .toList();
                
                if (remainingParticipants.isEmpty && params.autoEndMeeting) {
                  _repository.endMeeting(params.meetingId);
                }
                
                return const Success(null);
              },
              failure: (failure) => ResultFailure(failure),
            );
          },
          failure: (failure) async => ResultFailure(failure),
        );
      },
      failure: (failure) async => ResultFailure(failure),
    );
  }
}

/// Parameters for LeaveMeetingUseCase
class LeaveMeetingParams extends Equatable {
  const LeaveMeetingParams({
    required this.meetingId,
    required this.userId,
    this.transferHostTo,
    this.endMeetingForAll = false,
    this.autoEndMeeting = true,
  });

  final String meetingId;
  final String userId;
  final String? transferHostTo;
  final bool endMeetingForAll;
  final bool autoEndMeeting;

  @override
  List<Object?> get props => [
        meetingId,
        userId,
        transferHostTo,
        endMeetingForAll,
        autoEndMeeting,
      ];
}